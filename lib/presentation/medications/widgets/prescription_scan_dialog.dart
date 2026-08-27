import 'package:fe/core/allergy/allergy_matcher.dart';
import 'package:fe/core/constants/app_size.dart';
import 'package:fe/core/utils/user_facing_error.dart';
import 'package:fe/core/prescription/prescription_ocr.dart';
import 'package:fe/core/prescription/prescription_plan_parser.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/core/widgets/labeled_column.dart';
import 'package:fe/data/models/medication/medication.dart';
import 'package:fe/data/models/medication/medication_frequency.dart';
import 'package:fe/data/models/medication/medication_reminder.dart';
import 'package:fe/data/services/api_ocr_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'dart:async';

import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:fe/presentation/medications/widgets/medication_dialog_components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Mở dialog quét đơn thuốc (OCR → chỉnh sửa → lưu lô).
Future<void> showPrescriptionScanDialog(BuildContext context) {
  final bloc = context.read<MedicationBloc>();
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: const PrescriptionScanDialog(),
    ),
  );
}

class _DraftEntry {
  _DraftEntry.fromParsed(ParsedPrescriptionLine p)
      : includeInSchedule = p.likelyOral,
        allergyHints = List<String>.from(p.allergyHints),
        name = TextEditingController(text: p.name),
        dosage = TextEditingController(text: p.dosage),
        instructions = TextEditingController(text: p.instructions),
        times = TextEditingController(text: p.suggestedTimes.join(', '));

  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController instructions;
  final TextEditingController times;
  bool includeInSchedule;
  final List<String> allergyHints;

  void dispose() {
    name.dispose();
    dosage.dispose();
    instructions.dispose();
    times.dispose();
  }
}

class PrescriptionScanDialog extends StatefulWidget {
  const PrescriptionScanDialog({super.key});

  @override
  State<PrescriptionScanDialog> createState() => _PrescriptionScanDialogState();
}

class _PrescriptionScanDialogState extends State<PrescriptionScanDialog> {
  static const Duration _stateSwitchDuration = Duration(milliseconds: 260);
  final ApiOcrService _apiOcrService = ApiOcrService();
  final LocalStorageService _localStorage = LocalStorageService();
  bool _busy = false;
  String? _error;
  bool _requireReselect = false;
  List<_DraftEntry>? _entries;
  /// Bumped whenever OCR replaces the whole draft list so [AnimatedSwitcher] and
  /// list rows do not reuse [TextField] elements across different controllers
  /// (avoids stale selection/composing asserts on web: text_input.dart).
  int _entriesGeneration = 0;
  List<AllergyMatch> _allergyMatches = [];

  @override
  void dispose() {
    _disposeEntries(immediate: true);
    super.dispose();
  }

  void _disposeEntries({bool immediate = false}) {
    if (_entries == null) return;
    final oldEntries = List<_DraftEntry>.from(_entries!);
    _entries = null;
    _disposeDraftEntries(oldEntries, immediate: immediate);
  }

  void _disposeDraftEntries(
    List<_DraftEntry> entries, {
    bool immediate = false,
  }) {
    if (entries.isEmpty) return;
    if (immediate || !mounted) {
      for (final e in entries) {
        e.dispose();
      }
      return;
    }

    // AnimatedSwitcher giữ widget cũ trong lúc animate-out.
    // Dispose trễ để tránh "TextEditingController was used after being disposed".
    Future<void>.delayed(_stateSwitchDuration + const Duration(milliseconds: 40), () {
      for (final e in entries) {
        e.dispose();
      }
    });
  }

  double _nameQualityScore(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 0;
    final len = trimmed.length;
    final badChars = RegExp(r'[^A-Za-zÀ-ỹ0-9\s\-\+\(\)\.,/]').allMatches(trimmed).length;
    final badRatio = badChars / len;
    var score = (1 - badRatio).clamp(0.0, 1.0);
    if (RegExp(r'\b\d+(?:[.,]\d+)?\s*(mg|ml|g|mcg|iu|ui)\b', caseSensitive: false)
        .hasMatch(trimmed)) {
      score += 0.1;
    }
    if (RegExp(r'[A-Za-zÀ-ỹ]{4,}').hasMatch(trimmed)) {
      score += 0.05;
    }
    return score.clamp(0.0, 1.0);
  }

  String _normalizeNameForMatch(String name) {
    final lower = name.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-zà-ỹ0-9\s]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isLikelyDuplicateName(String a, String b) {
    final na = _normalizeNameForMatch(a);
    final nb = _normalizeNameForMatch(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb || na.contains(nb) || nb.contains(na)) return true;
    final ta = na.split(' ').where((e) => e.length >= 4).toSet();
    final tb = nb.split(' ').where((e) => e.length >= 4).toSet();
    if (ta.isEmpty || tb.isEmpty) return false;
    final overlap = ta.intersection(tb).length;
    if (overlap >= 2) return true;

    // lightweight fuzzy containment by first 6-letter token
    final leadA = ta.where((t) => t.length >= 6).toList();
    final leadB = tb.where((t) => t.length >= 6).toList();
    for (final x in leadA) {
      for (final y in leadB) {
        if (x == y || x.contains(y) || y.contains(x)) return true;
      }
    }
    return false;
  }

  bool _isAcceptableLocalName(String name) {
    final n = name.trim();
    final q = _nameQualityScore(n);
    if (q < 0.68) return false;
    final medLike = RegExp(
      r'(furosem|agif|atorva|lipot|bidifer|folic|sulfat|calci|vitamin\s*d3|pregabalin|clopidogrel)',
      caseSensitive: false,
    ).hasMatch(n);
    final hasDoseUnit = RegExp(r'\b\d+(?:[.,]\d+)?\s*(mg|ml|g|mcg|iu|ui)\b', caseSensitive: false)
        .hasMatch(n);
    return medLike || hasDoseUnit;
  }

  List<ParsedPrescriptionLine> _mergeServerWithLocalCandidates(
    List<ParsedPrescriptionLine> serverItems,
    List<ParsedPrescriptionLine> localItems,
  ) {
    final merged = List<ParsedPrescriptionLine>.from(serverItems);
    for (final local in localItems) {
      if (!_isAcceptableLocalName(local.name)) continue;
      final duplicated =
          merged.any((server) => _isLikelyDuplicateName(server.name, local.name));
      if (!duplicated) {
        merged.add(local);
      }
    }
    return merged;
  }

  List<String> _parseTimeList(String s) {
    final parts = s
        .split(RegExp(r'[,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final out = <String>[];
    for (final p in parts) {
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(p);
      if (m != null) {
        final h = int.tryParse(m.group(1)!);
        final min = int.tryParse(m.group(2)!);
        if (h != null &&
            min != null &&
            h >= 0 &&
            h < 24 &&
            min >= 0 &&
            min < 60) {
          out.add(
            '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
          );
        }
      }
    }
    return out.isEmpty ? ['08:00'] : out;
  }

  bool _shouldForceReselectFromWarnings(List<String> warnings, int parsedCount) {
    if (warnings.isEmpty) return false;
    final joined = warnings.join(' ').toLowerCase();
    if (joined.contains('không parse') || joined.contains('khong parse')) {
      return true;
    }
    if (joined.contains('độ tin cậy ocr thấp') ||
        joined.contains('do tin cay ocr thap')) {
      return true;
    }
    if (joined.contains('số thuốc parse được thấp') ||
        joined.contains('so thuoc parse duoc thap')) {
      return parsedCount <= 1;
    }
    return false;
  }

  Future<void> _runOcr(XFile file) async {
    setState(() {
      _busy = true;
      _error = null;
      _requireReselect = false;
      _allergyMatches = [];
    });
    try {
      List<ParsedPrescriptionLine> parsed = const [];
      bool forceReselect = false;
      final apiResult = await _apiOcrService.tryParsePrescription(file);
      if (apiResult != null && apiResult.hasUsableData) {
        final serverText = (apiResult.rawText ?? '').trim();
        final shouldRescueWithText =
            serverText.isNotEmpty &&
            (apiResult.items.isEmpty ||
                apiResult.items.length <= 1 ||
                apiResult.warnings.isNotEmpty);
        if (shouldRescueWithText) {
          debugPrint(
              '[OCR] server rescue check items=${apiResult.items.length} warnings=${apiResult.warnings.length} raw_len=${serverText.length}');
          final parsedMaps =
              await compute(parsePrescriptionPlanInBackground, serverText);
          final reparsed = parsedMaps.map(ParsedPrescriptionLine.fromMap).toList();
          if (reparsed.length > apiResult.items.length) {
            parsed = reparsed;
            debugPrint('[OCR] using reparsed server text items=${parsed.length}');
          } else {
            parsed = apiResult.items;
            debugPrint('[OCR] keeping server parsed items=${parsed.length}');
          }
        } else {
          parsed = apiResult.items;
          debugPrint('[OCR] using server parsed items=${parsed.length}');
        }

        // Chỉ hybrid khi server gần như không tách được dòng thuốc (0–1 dòng).
        // Cảnh báo "ít thuốc so với text dài" vẫn có thể xảy ra với đơn 2 thuốc thật;
        // hybrid lúc đó hay tách nhầm thành 3–4 dòng và làm sai số lượng.
        final shouldHybridLocal =
            apiResult.warnings.isNotEmpty && parsed.length <= 1;
        if (shouldHybridLocal) {
          debugPrint(
              '[OCR] hybrid rescue: server items=${parsed.length}, running local OCR');
          final localText = await recognizePrescriptionImage(file);
          final localTrimmed = localText.trim();
          debugPrint('[OCR] hybrid local recognized length=${localTrimmed.length}');
          if (localTrimmed.isNotEmpty) {
            final localParsedMaps =
                await compute(parsePrescriptionPlanInBackground, localTrimmed);
            final localParsed =
                localParsedMaps.map(ParsedPrescriptionLine.fromMap).toList();
            debugPrint('[OCR] hybrid local parsed items=${localParsed.length}');
            if (localParsed.length > parsed.length) {
              final merged = _mergeServerWithLocalCandidates(parsed, localParsed);
              if (merged.length > parsed.length) {
                parsed = merged;
                debugPrint('[OCR] hybrid merged server+local items=${parsed.length}');
              } else {
                parsed = localParsed;
                debugPrint('[OCR] hybrid chose local parsed items=${parsed.length}');
              }
            }
          }
        }
        forceReselect = _shouldForceReselectFromWarnings(
          apiResult.warnings,
          parsed.length,
        );
      } else {
        final text = await recognizePrescriptionImage(file);
        final trimmed = text.trim();
        debugPrint('[OCR] recognized text length=${trimmed.length}');
        if (trimmed.isNotEmpty) {
          final preview = trimmed.length > 700
              ? '${trimmed.substring(0, 700)} ...'
              : trimmed;
          debugPrint('[OCR] recognized preview=$preview');
        }
        final parsedMaps =
            await compute(parsePrescriptionPlanInBackground, trimmed);
        parsed = parsedMaps.map(ParsedPrescriptionLine.fromMap).toList();
      }

      debugPrint('[OCR] parsed entries=${parsed.length}');
      if (parsed.isNotEmpty) {
        final names = parsed.map((e) => e.name).join(' | ');
        debugPrint('[OCR] parsed names=$names');
      }
      if (!mounted) return;
      if (parsed.isEmpty) {
        setState(() {
          _disposeEntries();
          _error =
              'Không nhận diện được nội dung đơn thuốc. Ảnh có thể mờ hoặc thiếu sáng. Vui lòng chụp lại hoặc tải ảnh khác.';
          _requireReselect = true;
        });
        return;
      }
      if (forceReselect) {
        setState(() {
          _disposeEntries();
          _error =
              'Ảnh chưa đủ rõ nên không đọc tin cậy được nội dung đơn. Vui lòng chụp lại hoặc chọn ảnh khác.';
          _requireReselect = true;
        });
        return;
      }
      setState(() {
        _disposeEntries();
        _entriesGeneration++;
        _entries = parsed.map((p) => _DraftEntry.fromParsed(p)).toList();
        _requireReselect = false;
      });
      await _runAllergyCheck(parsed, apiResult?.meta);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = UserFacingError.message(e);
        _requireReselect = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Load user allergies and run matcher for each parsed item.
  /// Enriches [_DraftEntry.allergyHints] with user-specific reason text
  /// and populates [_allergyMatches] for the top-level banner.
  Future<void> _runAllergyCheck(
    List<ParsedPrescriptionLine> parsed,
    Map<String, dynamic>? meta,
  ) async {
    if (!mounted) return;
    List<String> userAllergies;
    try {
      final authAllergies = context.read<AuthBloc>().state.user.allergies;
      if (authAllergies.isNotEmpty) {
        userAllergies = authAllergies;
      } else {
        userAllergies = await _localStorage.getAllergies();
      }
    } catch (_) {
      return; // Storage failure — skip silently, don't block scan flow
    }
    if (userAllergies.isEmpty || _entries == null) return;

    final avgConf = (meta?['avg_confidence'] as num?)?.toDouble() ?? 1.0;
    final ocrUncertain = avgConf < 0.65;

    final newMatches = <AllergyMatch>[];
    for (var i = 0; i < parsed.length && i < _entries!.length; i++) {
      final item = parsed[i];
      final match = AllergyMatcher.checkItem(
        itemName: item.name,
        itemGroupHints: item.allergyHints,
        userAllergies: userAllergies,
        ocrUncertain: ocrUncertain,
      );
      if (match.hasWarning) {
        newMatches.add(match);
        // Replace generic OCR hints with the user-specific reason on this entry.
        _entries![i].allergyHints
          ..clear()
          ..add(match.reason);
      }
    }

    if (newMatches.isNotEmpty && mounted) {
      setState(() => _allergyMatches = newMatches);
    }
  }

  Future<bool> _isLikelyBlurred(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return false;
      final gray = img.grayscale(decoded);

      // Variance of Laplacian approximation:
      // lower variance often indicates blurred images.
      final w = gray.width;
      final h = gray.height;
      if (w < 3 || h < 3) return false;

      double sum = 0;
      double sumSq = 0;
      int n = 0;

      for (var y = 1; y < h - 1; y += 2) {
        for (var x = 1; x < w - 1; x += 2) {
          final c = gray.getPixel(x, y).r.toDouble();
          final up = gray.getPixel(x, y - 1).r.toDouble();
          final down = gray.getPixel(x, y + 1).r.toDouble();
          final left = gray.getPixel(x - 1, y).r.toDouble();
          final right = gray.getPixel(x + 1, y).r.toDouble();
          final lap = (4 * c) - up - down - left - right;
          sum += lap;
          sumSq += lap * lap;
          n++;
        }
      }
      if (n == 0) return false;
      final mean = sum / n;
      final variance = (sumSq / n) - (mean * mean);
      debugPrint('[OCR] blur variance=$variance for file=${file.name}');
      return variance < 70; // softer threshold for real-world hospital photos
    } catch (_) {
      return false;
    }
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    final blurred = await _isLikelyBlurred(file);
    if (blurred) {
      if (!mounted) return;
      setState(() {
        _disposeEntries();
        _error =
            'Ảnh có dấu hiệu bị mờ nên không thể nhận diện ổn định. Vui lòng chụp lại hoặc tải ảnh khác.';
        _requireReselect = true;
      });
      return;
    }
    await _runOcr(file);
  }

  Widget _buildReselectActions() {
    if (!_requireReselect) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        if (!kIsWeb) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Chụp lại'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Tải ảnh khác'),
                ),
              ),
            ],
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Tải ảnh khác'),
          ),
        ],
      ],
    );
  }

  Future<void> _chooseSource() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chọn ảnh đơn',
                      style: AppTextStyles.h4.copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                kIsWeb
                    ? 'Chọn file ảnh từ thiết bị.'
                    : 'Chụp mới hoặc chọn nhanh từ thư viện.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 14),
              if (!kIsWeb) ...[
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pick(ImageSource.camera);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_rounded,
                          size: 21,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Chụp ảnh',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        kIsWeb ? Icons.image_rounded : Icons.photo_library_rounded,
                        size: 21,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kIsWeb ? 'Chọn ảnh từ máy' : 'Thư viện ảnh',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _removeEntry(int index) {
    final removed = _entries![index];
    setState(() {
      _entries!.removeAt(index);
      if (_entries!.isEmpty) _entries = null;
    });
    _disposeDraftEntries([removed]);
  }

  Widget _buildAllergyBanner(List<AllergyMatch> matches) {
    final hasHigh =
        matches.any((m) => m.severity == AllergySeverity.highRisk);
    final bannerColor =
        hasHigh ? AppColors.errorLight : const Color(0xFFFFF3E0);
    final borderColor = hasHigh
        ? AppColors.error.withValues(alpha: 0.35)
        : const Color(0xFFFFB74D);
    final iconColor =
        hasHigh ? AppColors.error : const Color(0xFFF57C00);
    final titleColor =
        hasHigh ? AppColors.error : const Color(0xFFE65100);
    final bodyColor =
        hasHigh ? AppColors.error : const Color(0xFFBF360C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasHigh
                      ? 'Phát hiện thuốc có thể liên quan đến dị ứng đã khai báo'
                      : 'Một số thuốc cần kiểm tra lại với hồ sơ dị ứng',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Thông tin chỉ mang tính hỗ trợ, không thay thế tư vấn bác sĩ hoặc dược sĩ.',
            style: AppTextStyles.caption.copyWith(color: bodyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStateContent() {
    final stateKey = _busy
        ? 'busy'
        : (_error != null
            ? 'error'
            : (_entries != null ? 'entries|$_entriesGeneration' : 'idle'));

    return AnimatedSwitcher(
      duration: _stateSwitchDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(stateKey),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang đọc đơn, bạn chờ một chút nhé…', style: AppTextStyles.caption),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              _buildReselectActions(),
            ],
            if (_entries != null) ...[
              const SizedBox(height: 12),
              if (_allergyMatches.isNotEmpty) ...[
                _buildAllergyBanner(_allergyMatches),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  children: [
                    ...List.generate(_entries!.length, (index) {
                      final e = _entries![index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlanItemCard(
                          key: ObjectKey(e),
                          index: index + 1,
                          entry: e,
                          onRemove: () => _removeEntry(index),
                          onIncludeChanged: (v) {
                            setState(() =>
                                _entries![index].includeInSchedule = v);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _confirmPlan,
                  icon: const Icon(Icons.check_circle_rounded, size: 22),
                  label: const Text('Lưu vào lịch uống'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPlan() async {
    if (_entries == null || _entries!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hãy chọn ảnh đơn để nhận dạng trước.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = context.read<AuthBloc>().state.user.id;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không xác định được tài khoản. Vui lòng đăng nhập lại.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final toAdd = <Medication>[];
    final now = DateTime.now();
    final startDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    var seq = 0;

    for (final e in _entries!) {
      if (!e.includeInSchedule) continue;
      final name = e.name.text.trim();
      final dosage = e.dosage.text.trim();
      if (name.isEmpty || dosage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mỗi mục cần có tên và liều lượng.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final times = _parseTimeList(e.times.text);
      final baseMs = DateTime.now().millisecondsSinceEpoch + seq;
      seq += 1;
      final id = 'med-$baseMs';

      toAdd.add(
        Medication(
          id: id,
          userId: userId,
          name: name,
          dosage: dosage,
          frequency: MedicationFrequency(
            type: MedicationFrequencyType.daily,
            timesPerDay: times.length,
            specificTimes: times,
          ),
          startDate: startDateStr,
          instructions: e.instructions.text.trim(),
          prescribedBy: '',
          reminders: [
            for (var i = 0; i < times.length; i++)
              MedicationReminder(
                id: 'rem-$baseMs-$i',
                medicationId: id,
                time: times[i],
              ),
          ],
        ),
      );
    }

    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bật ít nhất một mục “Thêm vào lịch uống”.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Bổ sung kiểm tra cơ bản để giảm dữ liệu OCR sai trước khi lưu.
    final badDosage = toAdd.any((m) {
      final d = m.dosage.trim();
      if (d.isEmpty) return true;
      if (d.toLowerCase() == 'theo đơn') return false;
      return !RegExp(r'\d').hasMatch(d);
    });
    if (badDosage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Một số mục chưa có liều lượng hợp lệ. Vui lòng kiểm tra lại trước khi lưu.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bloc = context.read<MedicationBloc>();
    final countBefore = bloc.state.medications.length;
    final n = toAdd.length;
    setState(() => _busy = true);
    bloc.add(AddMedicationsBatch(medications: toAdd));
    try {
      await bloc.stream
          .timeout(const Duration(seconds: 90))
          .firstWhere(
        (s) =>
            s.medications.length >= countBefore + n ||
            s.errorMessage != null,
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Hết thời gian chờ khi lưu. Kiểm tra kết nối và thử lại.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (bloc.state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bloc.state.errorMessage!),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasEntries = _entries != null;
    final maxH = MediaQuery.sizeOf(context).height * (hasEntries ? 0.84 : 0.72);
    final maxW = hasEntries ? AppSize.shellMaxWidth : 560.0;

    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxW,
          maxHeight: maxH,
        ),
        child: SizedBox(
          height: hasEntries ? maxH : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Column(
              mainAxisSize: hasEntries ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MedicationDialogHeader(
                  title: 'Quét đơn thuốc',
                  subtitle: 'Chọn ảnh rồi chỉnh nhanh tên, liều và giờ nhắc.',
                  closeEnabled: !_busy,
                  onClose: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                ),
                const SizedBox(height: 8),
                MedicationSectionCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        kIsWeb
                            ? 'Tải ảnh đơn thuốc từ thiết bị để bắt đầu nhận diện.'
                            : 'Chụp hoặc chọn ảnh đơn thuốc để bắt đầu nhận diện.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _busy ? null : _chooseSource,
                        icon: Icon(
                          kIsWeb ? Icons.image_rounded : Icons.add_a_photo_rounded,
                          size: 20,
                        ),
                        label: Text(kIsWeb ? 'Chọn ảnh đơn' : 'Chụp hoặc chọn ảnh'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasEntries && _error == null && !_busy) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mẹo: ảnh rõ nét, đủ sáng sẽ cho kết quả chính xác hơn.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                if (hasEntries)
                  Expanded(child: _buildAnimatedStateContent())
                else
                  _buildAnimatedStateContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanItemCard extends StatelessWidget {
  const _PlanItemCard({
    super.key,
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onIncludeChanged,
  });

  final int index;
  final _DraftEntry entry;
  final VoidCallback onRemove;
  final ValueChanged<bool> onIncludeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadowList,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$index',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textGrey, size: 22),
                  tooltip: 'Xóa',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (entry.allergyHints.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.allergyHints.join(' · '),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error, height: 1.3),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            LabeledColumn(
              label: 'Tên thuốc',
              requiredField: true,
              child: TextField(
                controller: entry.name,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(context, 'Ví dụ: Amoxicillin 500mg'),
              ),
            ),
            const SizedBox(height: 10),
            LabeledColumn(
              label: 'Liều lượng',
              requiredField: true,
              child: TextField(
                controller: entry.dosage,
                decoration: _decoration(context, 'Ví dụ: 500 mg, 1 viên'),
              ),
            ),
            const SizedBox(height: 10),
            LabeledColumn(
              label: 'Cách dùng',
              child: TextField(
                controller: entry.instructions,
                minLines: 2,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                decoration: _decoration(context, 'Sau ăn, số lần/ngày…'),
              ),
            ),
            const SizedBox(height: 10),
            LabeledColumn(
              label: 'Lịch',
              hintInParens: 'giờ HH:mm, cách nhau bởi dấu phẩy',
              child: TextField(
                controller: entry.times,
                decoration: _decoration(context, '08:00, 20:00'),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                'Thêm vào lịch uống',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                entry.includeInSchedule
                    ? 'Tạo nhắc theo giờ ở trên'
                    : 'Không nhắc (vd. thuốc bôi)',
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              value: entry.includeInSchedule,
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
              ),
              onChanged: onIncludeChanged,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String hint) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );
}

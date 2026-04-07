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
import 'dart:async';

import 'package:fe/presentation/auth/bloc/auth_bloc.dart';
import 'package:fe/presentation/medications/bloc/medication_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  bool _busy = false;
  String? _error;
  List<_DraftEntry>? _entries;

  @override
  void dispose() {
    _disposeEntries();
    super.dispose();
  }

  void _disposeEntries() {
    if (_entries == null) return;
    for (final e in _entries!) {
      e.dispose();
    }
    _entries = null;
  }

  void _applyParsedPlan(String raw) {
    final parsed = parsePrescriptionPlan(raw);
    _disposeEntries();
    _entries = parsed.map((p) => _DraftEntry.fromParsed(p)).toList();
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

  Future<void> _runOcr(XFile file) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await recognizePrescriptionImage(file);
      if (!mounted) return;
      final trimmed = text.trim();
      setState(() {
        _applyParsedPlan(trimmed);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = UserFacingError.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
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
    await _runOcr(file);
  }

  Future<void> _chooseSource() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chọn ảnh đơn',
                style: AppTextStyles.h4.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                kIsWeb
                    ? 'Chọn file ảnh từ thiết bị.'
                    : 'Chụp mới hoặc chọn từ thư viện.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 18),
              if (!kIsWeb) ...[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pick(ImageSource.camera);
                  },
                  icon: const Icon(Icons.photo_camera_rounded, size: 22),
                  label: const Text('Chụp ảnh'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
                icon: Icon(
                  kIsWeb ? Icons.image_rounded : Icons.photo_library_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
                label: Text(kIsWeb ? 'Chọn ảnh từ máy' : 'Thư viện ảnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
    );
  }

  void _removeEntry(int index) {
    setState(() {
      _entries![index].dispose();
      _entries!.removeAt(index);
      if (_entries!.isEmpty) _entries = null;
    });
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
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppSize.shellMaxWidth,
          maxHeight: maxH,
        ),
        child: SizedBox(
          height: _entries != null ? maxH : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quét đơn thuốc',
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chọn ảnh — chỉnh tên, liều, cách dùng và giờ nhắc.',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _chooseSource,
                  icon: Icon(
                    kIsWeb ? Icons.image_rounded : Icons.add_a_photo_rounded,
                    size: 22,
                  ),
                  label: Text(kIsWeb ? 'Chọn ảnh đơn' : 'Chụp hoặc chọn ảnh'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
                      Text('Đang đọc đơn…', style: AppTextStyles.caption),
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
                ],
                if (_entries != null) ...[
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(right: 8, top: 4),
                      children: [
                        ...List.generate(_entries!.length, (index) {
                          final e = _entries![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PlanItemCard(
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
        ),
      ),
    );
  }
}

class _PlanItemCard extends StatelessWidget {
  const _PlanItemCard({
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
              activeThumbColor: AppColors.primary,
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

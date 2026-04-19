// Parser đơn thuốc tiếng Việt (OCR) → gợi ý lịch uống; mở rộng allergyHints sau.

final _numberedStart = RegExp(
  r'^\s*(?:[^\w\n]{0,4})\s*(\d+)\s*(?:[.)-]\s*|\s+)',
  multiLine: true,
);
final _slLine = RegExp(
  r'SL\s*[:\s]*(\d+)\s*([^\n]*)',
  caseSensitive: false,
);
final _timesPerDay = RegExp(
  r'(?:một\s+)?ngày\s+uống\s+(\d+)\s+lần|uống\s+(\d+)\s+lần\s*/?\s*ngày',
  caseSensitive: false,
);
final _timesPerDayShort = RegExp(
  r'ngày\s*uống\s*(\d+)\s*lần|uống\s*(\d+)\s*lần',
  caseSensitive: false,
);
final _topicalOrCare = RegExp(
  r'rửa|bôi|nhỏ|chăm\s*sóc|vết\s*mổ|rốn|không\s*uống|nhỏ\s*tai|mắt',
  caseSensitive: false,
);
final _oralHint = RegExp(
  r'uống|viên|mg\b|ml\b|cal\b',
  caseSensitive: false,
);
final _dayDrinkHint = RegExp(r'ngày\s*uống|mỗi\s*lần', caseSensitive: false);
final _perDosePattern = RegExp(
  r'mỗi\s*lần\s*[:\-]?\s*([0-9]+(?:[.,][0-9]+)?\s*(?:viên|gói|ống|giọt|ml|mg))',
  caseSensitive: false,
);
final _momentPattern = RegExp(
  r'\(([^)]*(?:sáng|trưa|chiều|tối)[^)]*)\)',
  caseSensitive: false,
);
final _quantityPattern = RegExp(
  r'([0-9]{1,4})\s*(viên|gói|ống|chai|lọ)\b',
  caseSensitive: false,
);

/// Một dòng thuốc / vật tư sau khi parse (chưa chỉnh tay).
class ParsedPrescriptionLine {
  final String name;
  final String dosage;
  final String instructions;
  final int timesPerDay;
  final List<String> suggestedTimes;
  /// false: dụng cụ, bôi rửa — mặc định không thêm vào lịch uống.
  final bool likelyOral;
  final List<String> allergyHints;

  const ParsedPrescriptionLine({
    required this.name,
    required this.dosage,
    required this.instructions,
    required this.timesPerDay,
    required this.suggestedTimes,
    required this.likelyOral,
    this.allergyHints = const [],
  });

  factory ParsedPrescriptionLine.fromMap(Map<String, dynamic> map) {
    return ParsedPrescriptionLine(
      name: (map['name'] ?? '').toString(),
      dosage: (map['dosage'] ?? '').toString(),
      instructions: (map['instructions'] ?? '').toString(),
      timesPerDay: (map['times_per_day'] as int?) ?? 1,
      suggestedTimes: ((map['suggested_times'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      likelyOral: (map['likely_oral'] as bool?) ?? false,
      allergyHints: ((map['allergy_hints'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'instructions': instructions,
      'times_per_day': timesPerDay,
      'suggested_times': suggestedTimes,
      'likely_oral': likelyOral,
      'allergy_hints': allergyHints,
    };
  }
}

/// Gợi ý cảnh báo dị ứng (mở rộng: đồng bộ hồ sơ dị ứng người dùng).
List<String> suggestAllergyHintsForDrugName(String name) {
  final n = name.toLowerCase();
  final hints = <String>[];
  if (n.contains('penicillin') ||
      n.contains('amoxicillin') ||
      n.contains('unasyn') ||
      n.contains('ampicillin') ||
      n.contains('sultamicillin')) {
    hints.add('Nhóm beta-lactam — kiểm tra tiền sử dị ứng penicillin.');
  }
  if (n.contains('cephalosporin') || n.contains('cefixim')) {
    hints.add('Cephalosporin — chú ý nếu dị ứng penicillin nặng.');
  }
  if (n.contains('sulfa') || n.contains('bactrim')) {
    hints.add('Nhóm sulfonamide — chú ý dị ứng sulfa.');
  }
  return hints;
}

List<String> _inferTimes(int timesPerDay, String text) {
  final t = text.toLowerCase();
  if (timesPerDay <= 0) return ['09:00'];

  if (timesPerDay == 1) {
    if (t.contains('sau ăn sáng') ||
        (t.contains('sáng') && t.contains('sau') && t.contains('ăn'))) {
      return ['08:00'];
    }
    if (t.contains('sau ăn trưa') || t.contains('bữa trưa')) {
      return ['13:00'];
    }
    if (t.contains('sau ăn tối') || t.contains('buổi tối')) {
      return ['19:00'];
    }
    if (t.contains('tối') && t.contains('sau')) {
      return ['19:00'];
    }
    return ['08:00'];
  }

  if (timesPerDay == 2) {
    if (t.contains('sáng') && t.contains('chiều')) {
      return const ['08:00', '16:30'];
    }
    if (t.contains('sáng') && t.contains('tối')) {
      return const ['08:00', '20:00'];
    }
    return const ['08:00', '20:00'];
  }
  if (timesPerDay == 3) {
    return const ['08:00', '13:00', '19:00'];
  }
  if (timesPerDay == 4) {
    return const ['08:00', '12:00', '16:00', '20:00'];
  }
  return List.generate(timesPerDay, (i) {
    final h = (8 + (13 * i / (timesPerDay - 1))).round().clamp(6, 22);
    return '${h.toString().padLeft(2, '0')}:00';
  });
}

String _extractDosageFromName(String name) {
  final m = RegExp(
    r'(\d+(?:[.,]\d+)?\s*(?:mg|g|gram|ml|mL|ML|%|IU|UI|mcg|µg))',
    caseSensitive: false,
  ).firstMatch(name);
  return m?.group(1)?.replaceAll(',', '.') ?? '';
}

String _normalizeOcrVietnamese(String raw) {
  final normalizedLine = raw
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[“”]'), '"')
      .replaceAll(RegExp(r'[–—]'), '-')
      .replaceAllMapped(
        RegExp(r'(\d)\s*[lI]\s*ần', caseSensitive: false),
        (m) => '${m.group(1)} lần',
      )
      .replaceAllMapped(
        RegExp(r'ng[aàảãáạ]y\s*u[oôốồổỗộơờớởỡợ]?ng', caseSensitive: false),
        (_) => 'ngày uống',
      )
      .replaceAllMapped(
        RegExp(r'm[oôốồổỗộơờớởỡợ]?i\s*l[aàảãáạ]n', caseSensitive: false),
        (_) => 'mỗi lần',
      );

  final lines = normalizedLine
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .toList();
  return lines.join('\n').trim();
}

String _normalizeMomentText(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[;|/]'), ',')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' ,', ',')
      .replaceAll(', ', ', ')
      .trim();
}

String? _extractPerDose(String body) {
  final m = _perDosePattern.firstMatch(body);
  if (m == null) return null;
  return m.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _extractMoment(String body) {
  final matches = _momentPattern.allMatches(body);
  for (final m in matches) {
    final g = (m.group(1) ?? '').trim();
    if (g.isEmpty) continue;
    if (RegExp(r'sáng|trưa|chiều|tối', caseSensitive: false).hasMatch(g)) {
      return _normalizeMomentText(g);
    }
  }
  return null;
}

String? _extractQuantity(String body) {
  final matches = _quantityPattern.allMatches(body);
  if (matches.isEmpty) return null;
  final m = matches.last;
  final n = m.group(1);
  final u = m.group(2);
  if (n == null || u == null) return null;
  return '$n ${u.toLowerCase()}';
}

List<String>? _inferTimesFromMomentText(String? moment) {
  if (moment == null || moment.isEmpty) return null;
  final m = moment.toLowerCase();
  final out = <String>[];
  if (m.contains('sáng')) out.add('08:00');
  if (m.contains('trưa')) out.add('12:30');
  if (m.contains('chiều')) out.add('16:30');
  if (m.contains('tối')) out.add('20:00');
  if (out.isEmpty) return null;
  return out;
}

/// Tách các khối bắt đầu bằng `1.` `2)` … (bỏ phần header đơn không có số).
List<String> _splitNumberedBlocks(String raw) {
  final normalized = raw.replaceAll('\r', '\n');
  final lines = normalized
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  final blocks = <String>[];
  final buf = StringBuffer();
  var started = false;

  for (final line in lines) {
    if (_numberedStart.hasMatch(line)) {
      if (started && buf.isNotEmpty) {
        blocks.add(buf.toString());
        buf.clear();
      }
      started = true;
    }
    if (!started) continue;
    if (buf.isNotEmpty) buf.writeln();
    buf.write(line);
  }
  if (buf.isNotEmpty) blocks.add(buf.toString());
  return blocks;
}

/// Fallback splitter khi OCR làm vỡ layout:
/// tách theo mốc "1 ...", "2 ...", ... ngay trong cùng đoạn text.
List<String> _splitInlineNumberedBlocks(String raw) {
  final text = raw.replaceAll('\r', '\n');
  final marker =
      RegExp(r'(?=(?:^|[\s\n\|\]\[\(\):;,\-\\])(\d{1,2})\s+[A-Za-zÀ-ỹ])');
  final matches = marker.allMatches(text).toList();
  if (matches.length < 2) return const [];

  final blocks = <String>[];
  for (var i = 0; i < matches.length; i++) {
    final start = matches[i].start;
    final end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
    final part = text.substring(start, end).trim();
    if (part.isNotEmpty) blocks.add(part);
  }
  return blocks;
}

ParsedPrescriptionLine _parseBlock(String block) {
  var body = block
      .replaceFirst(
        RegExp(r'^\s*(?:[^\w\n]{0,4})\s*\d+\s*(?:[.)-]\s*|\s+)'),
        '',
      )
      .trim();
  body = _normalizeOcrVietnamese(body);
  final fullLower = body.toLowerCase();

  var cut = -1;
  final dayIdx = fullLower.indexOf('một ngày');
  final dayDrinkIdx = fullLower.indexOf('ngày uống');
  final eachDoseIdx = fullLower.indexOf('mỗi lần');
  final slIdx = fullLower.indexOf('sl');
  for (final i in [dayIdx, dayDrinkIdx, eachDoseIdx, slIdx]) {
    if (i >= 0 && (cut < 0 || i < cut)) cut = i;
  }

  var namePart = body;
  var instrPart = '';
  if (cut >= 0) {
    namePart = body.substring(0, cut).trim();
    instrPart = body.substring(cut).trim();
  }

  // Gộp phần hướng dẫn: ưu tiên dòng có "Một ngày" / sau SL
  final nameLines = namePart
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  var name = nameLines.isNotEmpty ? nameLines.first : 'Thuốc';
  if (_slLine.hasMatch(name)) {
    name = nameLines.length > 1 ? nameLines[1] : name;
  }
  name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (name.length > 120) name = name.substring(0, 120);

  final slMatch = _slLine.firstMatch(body);
  var qtyNote = '';
  if (slMatch != null) {
    final n = slMatch.group(1);
    final u = slMatch.group(2)?.trim() ?? '';
    qtyNote = u.isNotEmpty ? 'SL: $n $u' : 'SL: $n';
  }

  final instr = [if (qtyNote.isNotEmpty) qtyNote, instrPart]
      .where((s) => s.trim().isNotEmpty)
      .join('\n')
      .trim();

  var timesPerDay = 1;
  final merged = '$instr $body';
  final m1 = _timesPerDay.firstMatch(merged) ?? _timesPerDayShort.firstMatch(merged);
  if (m1 != null) {
    final g = m1.group(1) ?? m1.group(2);
    if (g != null) timesPerDay = int.tryParse(g) ?? 1;
  }
  if (timesPerDay == 1) {
    final lower = merged.toLowerCase();
    final moments = <String>[
      if (lower.contains('sáng')) 'sáng',
      if (lower.contains('trưa')) 'trưa',
      if (lower.contains('chiều')) 'chiều',
      if (lower.contains('tối')) 'tối',
    ];
    final uniqueCount = moments.toSet().length;
    if (uniqueCount >= 2) {
      timesPerDay = uniqueCount;
    }
  }

  final likelyOral = !_topicalOrCare.hasMatch(body) &&
      (_oralHint.hasMatch(body) || _oralHint.hasMatch(name) || _dayDrinkHint.hasMatch(body));

  final perDose = _extractPerDose(merged);
  final moment = _extractMoment(merged);
  final quantity = _extractQuantity(merged);
  final timesFromMoment = _inferTimesFromMomentText(moment);

  var times = timesFromMoment ?? _inferTimes(timesPerDay, instr + body);
  if (timesFromMoment != null && timesFromMoment.isNotEmpty) {
    timesPerDay = timesFromMoment.length;
  }
  if (!likelyOral) {
    timesPerDay = 1;
    times = ['09:00'];
  }

  var dosage = _extractDosageFromName(name);
  if (dosage.isEmpty) {
    final dm = RegExp(
      r'(\d+(?:[.,]\d+)?\s*(?:mg|g|gram|ml|mL|ML|%|IU|UI|mcg|µg))',
      caseSensitive: false,
    ).firstMatch(instr);
    if (dm != null) dosage = dm.group(1)!.replaceAll(',', '.');
  }
  dosage = dosage
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(RegExp(r'\bgram\b', caseSensitive: false), (_) => 'g')
      .replaceAllMapped(RegExp(r'\bmL\b|\bML\b'), (_) => 'ml')
      .replaceAllMapped(RegExp(r'\bUI\b'), (_) => 'IU')
      .trim();
  if (dosage.isEmpty) dosage = 'Theo đơn';

  final hints = suggestAllergyHintsForDrugName(name);

  final keyInstructionParts = <String>[
    if (perDose != null) 'Mỗi lần: $perDose',
    if (moment != null) 'Thời điểm: (${moment.replaceAll(',', ', ')})',
    if (quantity != null) 'Số lượng: $quantity',
    'Ngày uống: $timesPerDay lần',
  ];
  final keyInstruction = keyInstructionParts.join('\n');

  return ParsedPrescriptionLine(
    name: name,
    dosage: dosage.isEmpty ? '—' : dosage,
    instructions: keyInstruction,
    timesPerDay: timesPerDay,
    suggestedTimes: times,
    likelyOral: likelyOral,
    allergyHints: hints,
  );
}

/// Parse toàn bộ văn bản OCR → danh sách dòng thuốc.
List<ParsedPrescriptionLine> parsePrescriptionPlan(String raw) {
  final trimmed = _normalizeOcrVietnamese(raw).trim();
  if (trimmed.isEmpty) return [];

  var blocks = _splitNumberedBlocks(trimmed);
  if (blocks.length <= 1) {
    final inlineBlocks = _splitInlineNumberedBlocks(trimmed);
    if (inlineBlocks.length > blocks.length) {
      blocks = inlineBlocks;
    }
  }
  if (blocks.isNotEmpty) {
    final out = <ParsedPrescriptionLine>[];
    for (final b in blocks) {
      final p = _parseBlock(b);
      final name = p.name.trim();
      if (name.isEmpty || name == 'Thuốc') continue;
      final lower = b.toLowerCase();
      final hasMedicationSignal = RegExp(
        r'\b(?:mg|ml|mcg|iu|ui|viên|gói|ống|giọt|sulfat|folic|carbonat|calci|vitamin)\b',
        caseSensitive: false,
      ).hasMatch(lower);
      final hasUsageSignal =
          lower.contains('ngày uống') || lower.contains('mỗi lần');
      if (!(hasMedicationSignal || hasUsageSignal)) continue;
      out.add(p);
    }
    return out;
  }

  // Fallback: một khối duy nhất (đơn không đánh số rõ)
  return [_parseBlock(trimmed)];
}

/// Hàm isolate-friendly cho [compute]:
/// nhận raw OCR text và trả List<Map> để gửi qua isolate an toàn.
List<Map<String, dynamic>> parsePrescriptionPlanInBackground(String raw) {
  return parsePrescriptionPlan(raw).map((e) => e.toMap()).toList();
}

// Parser đơn thuốc tiếng Việt (OCR) → gợi ý lịch uống; mở rộng allergyHints sau.

final _numberedStart = RegExp(r'^(\d+)[.)]\s*', multiLine: true);
final _slLine = RegExp(
  r'SL\s*[:\s]*(\d+)\s*([^\n]*)',
  caseSensitive: false,
);
final _timesPerDay = RegExp(
  r'(?:một\s+)?ngày\s+uống\s+(\d+)\s+lần|uống\s+(\d+)\s+lần\s*/?\s*ngày',
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
    r'(\d+(?:[.,]\d+)?\s*(?:mg|g|ml|mL|ML|%|IU|mcg|UI))',
    caseSensitive: false,
  ).firstMatch(name);
  return m?.group(1)?.replaceAll(',', '.') ?? '';
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

ParsedPrescriptionLine _parseBlock(String block) {
  var body = block.replaceFirst(RegExp(r'^\d+[.)]\s*'), '').trim();
  final fullLower = body.toLowerCase();

  var cut = -1;
  final dayIdx = fullLower.indexOf('một ngày');
  final slIdx = fullLower.indexOf('sl');
  for (final i in [dayIdx, slIdx]) {
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
  final m1 = _timesPerDay.firstMatch(instr + body);
  if (m1 != null) {
    final g = m1.group(1) ?? m1.group(2);
    if (g != null) timesPerDay = int.tryParse(g) ?? 1;
  }

  final likelyOral = !_topicalOrCare.hasMatch(body) &&
      (_oralHint.hasMatch(body) || _oralHint.hasMatch(name));

  var times = _inferTimes(timesPerDay, instr + body);
  if (!likelyOral) {
    timesPerDay = 1;
    times = ['09:00'];
  }

  var dosage = _extractDosageFromName(name);
  if (dosage.isEmpty) {
    final dm = RegExp(
      r'(\d+(?:[.,]\d+)?\s*(?:mg|g|ml|%|IU|mcg))',
      caseSensitive: false,
    ).firstMatch(instr);
    if (dm != null) dosage = dm.group(1)!.replaceAll(',', '.');
  }
  if (dosage.isEmpty) dosage = 'Theo đơn';

  final hints = suggestAllergyHintsForDrugName(name);

  return ParsedPrescriptionLine(
    name: name,
    dosage: dosage.isEmpty ? '—' : dosage,
    instructions: instr.isEmpty ? body : instr,
    timesPerDay: timesPerDay,
    suggestedTimes: times,
    likelyOral: likelyOral,
    allergyHints: hints,
  );
}

/// Parse toàn bộ văn bản OCR → danh sách dòng thuốc.
List<ParsedPrescriptionLine> parsePrescriptionPlan(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return [];

  final blocks = _splitNumberedBlocks(trimmed);
  if (blocks.isNotEmpty) {
    return blocks.map(_parseBlock).toList();
  }

  // Fallback: một khối duy nhất (đơn không đánh số rõ)
  return [_parseBlock(trimmed)];
}

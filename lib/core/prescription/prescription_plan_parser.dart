// Parser đơn thuốc tiếng Việt: văn bản OCR thô → danh sách dòng thuốc + giờ
// uống gợi ý. Mô tả đầy đủ input/output và toàn bộ heuristic nằm ở doc của
// [parsePrescriptionPlan] gần cuối file — đọc chỗ đó trước khi sửa regex nào.
//
// Toàn bộ regex dưới đây bám vào cách viết đơn của bệnh viện Việt Nam
// ("Một ngày uống 2 lần", "Mỗi lần: 1 viên", "SL: 20 viên", "(sáng, tối)").
// Chúng cố tình lỏng vì OCR hay nuốt dấu và nhầm ký tự; đừng siết chặt lại nếu
// chưa có ảnh đơn thật để kiểm chứng.

/// Đầu một mục thuốc: `1.` `2)` `3 -` … (cho phép vài ký tự rác OCR ở đầu).
final _numberedStart = RegExp(
  r'^\s*(?:[^\w\n]{0,4})\s*(\d+)\s*(?:[.)-]\s*|\s+)',
  multiLine: true,
);
/// Dòng số lượng trên đơn: `SL: 20 viên`.
final _slLine = RegExp(
  r'SL\s*[:\s]*(\d+)\s*([^\n]*)',
  caseSensitive: false,
);
/// Số lần uống/ngày, dạng đầy đủ: "một ngày uống 2 lần", "uống 3 lần/ngày".
final _timesPerDay = RegExp(
  r'(?:một\s+)?ngày\s+uống\s+(\d+)\s+lần|uống\s+(\d+)\s+lần\s*/?\s*ngày',
  caseSensitive: false,
);
/// Bản rút gọn của [_timesPerDay], dùng làm phương án hai khi OCR mất chữ.
final _timesPerDayShort = RegExp(
  r'ngày\s*uống\s*(\d+)\s*lần|uống\s*(\d+)\s*lần',
  caseSensitive: false,
);
/// Dấu hiệu thuốc bôi / nhỏ / vật tư chăm sóc → KHÔNG đưa vào lịch uống.
final _topicalOrCare = RegExp(
  r'rửa|bôi|nhỏ|chăm\s*sóc|vết\s*mổ|rốn|không\s*uống|nhỏ\s*tai|mắt',
  caseSensitive: false,
);
/// Dấu hiệu thuốc uống (đơn vị liều, chữ "uống").
final _oralHint = RegExp(
  r'uống|viên|mg\b|ml\b|cal\b',
  caseSensitive: false,
);
/// Dấu hiệu có hướng dẫn dùng theo ngày — cũng được tính là thuốc uống.
final _dayDrinkHint = RegExp(r'ngày\s*uống|mỗi\s*lần', caseSensitive: false);
/// Liều mỗi lần: "mỗi lần: 1,5 viên", "mỗi lần 10 ml".
final _perDosePattern = RegExp(
  r'mỗi\s*lần\s*[:\-]?\s*([0-9]+(?:[.,][0-9]+)?\s*(?:viên|gói|ống|giọt|ml|mg))',
  caseSensitive: false,
);
/// Thời điểm uống nằm trong ngoặc: "(sáng, tối)", "(sáng - chiều)".
final _momentPattern = RegExp(
  r'\(([^)]*(?:sáng|trưa|chiều|tối)[^)]*)\)',
  caseSensitive: false,
);
/// Tổng số lượng cấp phát: "20 viên", "2 lọ".
final _quantityPattern = RegExp(
  r'([0-9]{1,4})\s*(viên|gói|ống|chai|lọ)\b',
  caseSensitive: false,
);

/// Một dòng thuốc / vật tư sau khi parse — dữ liệu GỢI Ý, chưa được người
/// dùng xác nhận.
///
/// Dùng chung cho hai nguồn: parser cục bộ trong file này và kết quả trả về từ
/// OCR service của backend (xem `ApiOcrService`). Vì vậy nó bất biến và chỉ
/// mang dữ liệu — mọi chỉnh sửa của người dùng diễn ra trên các
/// `TextEditingController` ở `prescription_scan_dialog.dart`, không sửa vào đây.
class ParsedPrescriptionLine {
  /// Tên thuốc như đọc được trên đơn (đã cắt tối đa 120 ký tự).
  final String name;

  /// Hàm lượng đã chuẩn hoá đơn vị, hoặc "Theo đơn" khi không rút được.
  final String dosage;

  /// Hướng dẫn dùng đã gom lại thành các dòng "Mỗi lần / Thời điểm / Số lượng
  /// / Ngày uống" để hiển thị thẳng cho người dùng.
  final String instructions;

  /// Số lần uống trong ngày; luôn khớp độ dài [suggestedTimes].
  final int timesPerDay;

  /// Giờ nhắc gợi ý dạng `HH:mm`.
  final List<String> suggestedTimes;

  /// false: dụng cụ, bôi rửa — mặc định không thêm vào lịch uống.
  final bool likelyOral;

  /// Cảnh báo theo NHÓM thuốc (beta-lactam, sulfonamide…), chưa đối chiếu hồ sơ
  /// dị ứng của người dùng. Việc đối chiếu do `AllergyMatcher` làm ở tầng UI.
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

  /// Dựng lại object từ map.
  ///
  /// Hai chỗ dùng: (1) nhận kết quả từ `compute()` — xem
  /// [parsePrescriptionPlanInBackground]; (2) đọc JSON của OCR service.
  /// Vì vậy tên khoá là **snake_case theo hợp đồng backend**
  /// (`times_per_day`, `suggested_times`, `likely_oral`, `allergy_hints`) —
  /// đổi tên khoá ở đây là phá tương thích với server, đừng "dọn" thành
  /// camelCase.
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

  /// Ngược của [ParsedPrescriptionLine.fromMap]. Giữ đúng bộ khoá snake_case.
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

/// Gợi ý cảnh báo dị ứng theo NHÓM thuốc, suy từ tên hoạt chất.
///
/// Chỉ là lưới lọc thô bằng so khớp chuỗi, cố tình "thà báo thừa còn hơn bỏ
/// sót". Không thay thế bước đối chiếu hồ sơ dị ứng thật của người dùng
/// (`AllergyMatcher` ở tầng UI) và không phải tư vấn y khoa.
///
/// Mở rộng danh sách: thêm nhánh `if` mới, giữ nguyên định dạng câu tiếng Việt
/// vì chuỗi này hiển thị thẳng cho người dùng.
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

/// Quy đổi số lần uống/ngày thành các mốc giờ nhắc mặc định.
///
/// Ưu tiên manh mối chữ trong [text] ("sau ăn sáng", "buổi tối"…); không có
/// manh mối thì dùng khung giờ quy ước: 1 lần → 08:00, 2 lần → 08:00 + 20:00,
/// 3 lần → 08:00/13:00/19:00, 4 lần → 08:00/12:00/16:00/20:00. Từ 5 lần trở
/// lên thì rải đều trong khoảng 08:00–21:00 và kẹp trong 06:00–22:00.
///
/// Đây chỉ là gợi ý ban đầu — người dùng luôn sửa lại được ở dialog quét đơn.
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

/// Rút hàm lượng lẫn trong tên thuốc ("Amoxicillin 500mg" → "500mg").
String _extractDosageFromName(String name) {
  final m = RegExp(
    r'(\d+(?:[.,]\d+)?\s*(?:mg|g|gram|ml|mL|ML|%|IU|UI|mcg|µg))',
    caseSensitive: false,
  ).firstMatch(name);
  return m?.group(1)?.replaceAll(',', '.') ?? '';
}

/// Vá các lỗi OCR tiếng Việt hay gặp trước khi chạy regex.
///
/// Cụ thể: chuẩn hoá nháy/gạch ngang lạ, ghép lại "2 Iần" → "2 lần" (chữ `l`
/// bị đọc thành `I`), và ép mọi biến thể mất dấu của "ngày uống" / "mỗi lần"
/// về đúng chính tả — hai cụm này là mỏ neo chính của parser, sai một dấu là
/// hỏng cả dòng. Cuối cùng gộp khoảng trắng và bỏ dòng rỗng.
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

/// Đưa cụm thời điểm về dạng "sáng, tối" (mọi dấu `;` `|` `/` thành dấu phẩy).
String _normalizeMomentText(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[;|/]'), ',')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' ,', ',')
      .replaceAll(', ', ', ')
      .trim();
}

/// Lấy liều mỗi lần, hoặc null nếu đơn không ghi.
String? _extractPerDose(String body) {
  final m = _perDosePattern.firstMatch(body);
  if (m == null) return null;
  return m.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Lấy cụm trong ngoặc đầu tiên có chứa sáng/trưa/chiều/tối. Bỏ qua các ngoặc
/// khác (tên biệt dược, ghi chú) để tránh nhiễu.
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

/// Lấy tổng số lượng. Cố tình lấy match CUỐI vì đầu dòng thường là hàm lượng
/// ("Paracetamol 500mg … 20 viên") — số cuối mới là số lượng cấp phát.
String? _extractQuantity(String body) {
  final matches = _quantityPattern.allMatches(body);
  if (matches.isEmpty) return null;
  final m = matches.last;
  final n = m.group(1);
  final u = m.group(2);
  if (n == null || u == null) return null;
  return '$n ${u.toLowerCase()}';
}

/// Đổi cụm thời điểm thành giờ cụ thể: sáng→08:00, trưa→12:30, chiều→16:30,
/// tối→20:00. Trả null nếu không nhận ra buổi nào (để [_inferTimes] lo tiếp).
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
///
/// Đây là cách tách CHÍNH, dùng khi OCR còn giữ được xuống dòng.
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

/// Fallback splitter khi OCR làm vỡ layout: tách theo mốc "1 …", "2 …" nằm
/// ngay giữa đoạn text thay vì ở đầu dòng.
///
/// Trả về danh sách rỗng khi tìm được <2 mốc — một mốc duy nhất thường là số
/// nhiễu (số nhà, mã đơn), tách theo nó sẽ hại nhiều hơn lợi.
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

/// Parse một khối văn bản (một mục thuốc) thành [ParsedPrescriptionLine].
///
/// Trình tự heuristic:
/// 1. Bỏ số thứ tự đầu khối, chuẩn hoá text OCR.
/// 2. Cắt khối làm hai tại mốc sớm nhất trong {"một ngày", "ngày uống",
///    "mỗi lần", "sl"} — trước mốc là TÊN thuốc, sau mốc là HƯỚNG DẪN dùng.
/// 3. Tên = dòng đầu của phần tên (nếu dòng đầu lại là dòng `SL:` thì lấy dòng
///    kế tiếp), cắt tối đa 120 ký tự.
/// 4. Số lần/ngày: đọc từ "ngày uống N lần"; không có thì đếm số buổi khác nhau
///    xuất hiện trong text (phải ≥2 buổi mới tính, tránh đếm nhầm 1 buổi).
/// 5. Có phải thuốc uống không: có dấu hiệu bôi/nhỏ/rửa → không; ngược lại cần
///    ít nhất một dấu hiệu uống. Không phải thuốc uống thì ép về 1 lần/ngày lúc
///    09:00 và mặc định KHÔNG bật vào lịch (`likelyOral == false`).
/// 6. Giờ nhắc: ưu tiên suy từ cụm buổi trong ngoặc — khi có, số lần/ngày lấy
///    theo số buổi và đè lên kết quả bước 4; không có thì dùng khung mặc định.
/// 7. Liều: tìm trong tên trước, rồi tới phần hướng dẫn; chuẩn hoá đơn vị
///    (gram→g, mL/ML→ml, UI→IU). Không tìm được thì để "Theo đơn".
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

/// Parse toàn bộ văn bản OCR của một đơn thuốc thành danh sách dòng thuốc.
///
/// ## Input
/// [raw] là text thô do `recognizePrescriptionImage()` trả về (ML Kit trên
/// mobile, Tesseract.js trên web). Chấp nhận text bẩn: mất dấu, nhầm `l`/`I`,
/// vỡ layout, lẫn header/footer của bệnh viện.
///
/// ## Output
/// Danh sách [ParsedPrescriptionLine] theo đúng thứ tự xuất hiện trên đơn.
/// Có thể trả về danh sách RỖNG — nghĩa là "không đọc được gì đáng tin"; UI
/// phải coi đó là kết quả hợp lệ (mời chụp lại) chứ không phải lỗi.
/// Kết quả luôn chỉ là GỢI Ý: người dùng sửa lại ở dialog quét đơn trước khi
/// lưu, và không mục nào tự vào lịch mà không qua xác nhận.
///
/// ## Cách tách mục
/// 1. Chuẩn hoá text ([_normalizeOcrVietnamese]).
/// 2. Tách theo dòng đánh số `1.` `2)` … ([_splitNumberedBlocks]).
/// 3. Nếu chỉ ra được ≤1 khối (OCR làm vỡ xuống dòng) thì thử tách theo mốc số
///    ngay giữa đoạn ([_splitInlineNumberedBlocks]) và chọn cách cho nhiều
///    khối hơn.
/// 4. Không tách được khối nào → coi cả đơn là một mục duy nhất.
///
/// ## Bộ lọc rác
/// Một khối chỉ được giữ khi tên khác rỗng, khác giá trị mặc định "Thuốc", VÀ
/// có ít nhất một tín hiệu: đơn vị/hoạt chất quen thuộc (`mg`, `ml`, `viên`,
/// `folic`, `vitamin`…) hoặc cụm hướng dẫn ("ngày uống", "mỗi lần"). Bộ lọc
/// này loại phần lớn header bệnh viện và dòng chẩn đoán.
///
/// Chi tiết heuristic cho từng mục xem [_parseBlock].
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

/// Bản chạy nền của [parsePrescriptionPlan], dành cho `compute()`.
///
/// Phải là hàm top-level và chỉ nhận/trả kiểu gửi qua isolate được, nên nó trả
/// `List<Map>` thay vì `List<ParsedPrescriptionLine>`; phía gọi dựng lại object
/// bằng [ParsedPrescriptionLine.fromMap]. Đừng gọi thẳng [parsePrescriptionPlan]
/// trên UI thread với đơn dài — chuỗi regex ở đây đủ nặng để làm giật khung hình.
///
/// Lưu ý nền tảng: trên web `compute()` chạy ngay trên luồng chính (không có
/// isolate), nên dùng nó chỉ an toàn về API chứ không giúp mượt hơn ở web.
List<Map<String, dynamic>> parsePrescriptionPlanInBackground(String raw) {
  return parsePrescriptionPlan(raw).map((e) => e.toMap()).toList();
}

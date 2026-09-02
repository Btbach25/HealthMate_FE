/// Đối chiếu thuốc trong đơn đã quét với danh sách dị ứng của người dùng
/// (giai đoạn 1 — MVP).
///
/// Chạy HOÀN TOÀN trên máy, dựa trên hồ sơ dị ứng lưu cục bộ: không gửi tên
/// thuốc lên server, và vẫn hoạt động khi mất mạng.
///
/// **Đây là công cụ nhắc nhở, KHÔNG phải kiểm tra y tế.** Nó so khớp chuỗi
/// chứ không hiểu dược lý: không biết biệt dược nào chứa hoạt chất nào, không
/// biết phản ứng chéo giữa các nhóm thuốc. Bỏ sót là chuyện có thể xảy ra —
/// giao diện phải luôn nhắc người dùng đối chiếu đơn gốc và hỏi bác sĩ, tuyệt
/// đối không diễn đạt kết quả ở đây thành "an toàn".
///
/// Xem [AllergyMatcher.checkItem] để biết ba tầng so khớp.
library;

/// Cách một thuốc bị coi là trùng với dị ứng đã khai — xem
/// [AllergyMatcher.checkItem].
enum AllergyMatchType { exact, contains, groupHint, none }

/// Mức cảnh báo hiển thị cho một dòng thuốc.
///
/// - [highRisk]: khớp chắc chắn và OCR đọc rõ → cảnh báo đỏ.
/// - [reviewRequired]: nghi ngờ, hoặc OCR không chắc chắn → nhắc kiểm tra lại.
/// - [none]: không thấy dấu hiệu trùng (KHÔNG có nghĩa là an toàn).
enum AllergySeverity { highRisk, reviewRequired, none }

/// Kết quả đối chiếu một dòng thuốc với hồ sơ dị ứng.
class AllergyMatch {
  const AllergyMatch({
    required this.itemName,
    required this.severity,
    required this.matchType,
    required this.reason,
    required this.confidence,
    this.matchedAllergy,
  });

  final String itemName;
  final AllergySeverity severity;
  final AllergyMatchType matchType;

  /// Câu giải thích tiếng Việt hiển thị ngay dưới dòng thuốc.
  /// Rỗng khi không có cảnh báo.
  final String reason;

  /// Độ tin cậy của phép khớp (0–1), dùng để xếp thứ tự cảnh báo.
  /// Đây là độ chắc chắn của việc SO KHỚP CHUỖI, không phải mức độ nguy hiểm.
  final double confidence;

  /// Mục trong hồ sơ dị ứng đã gây ra cảnh báo — hiển thị lại cho người dùng
  /// biết vì sao bị nhắc. `null` khi cảnh báo không xuất phát từ một mục cụ
  /// thể (trường hợp OCR không chắc chắn).
  final String? matchedAllergy;

  /// `true` nếu dòng thuốc này cần hiện cảnh báo.
  bool get hasWarning => severity != AllergySeverity.none;
}

/// Bộ đối chiếu thuốc ↔ dị ứng. Không có trạng thái, gọi tĩnh.
class AllergyMatcher {
  /// Độ dài tối thiểu để một chuỗi được tham gia so khớp kiểu "chứa nhau".
  ///
  /// Chặn các chuỗi quá ngắn khớp bừa: không có ngưỡng này thì mục dị ứng
  /// 2-3 ký tự sẽ nằm lọt trong hàng loạt tên thuốc không liên quan và làm
  /// người dùng ngập trong cảnh báo sai.
  static const int _minContainsLen = 5;

  /// Đối chiếu MỘT dòng thuốc với hồ sơ dị ứng.
  ///
  /// Ba tầng, dừng ở tầng đầu tiên khớp:
  /// 1. **Trùng khớp** — tên thuốc và mục dị ứng bằng nhau sau chuẩn hoá.
  /// 2. **Chứa nhau** — một bên nằm trong bên kia (bắt "Amoxicillin 500mg" ↔
  ///    "amoxicillin"), chỉ áp dụng khi mục dị ứng đủ dài ([_minContainsLen]).
  /// 3. **Trùng nhóm thuốc** — gợi ý nhóm từ OCR chồng lấn với hồ sơ dị ứng;
  ///    luôn chỉ ở mức [AllergySeverity.reviewRequired] vì đây là suy đoán.
  ///
  /// Khi [ocrUncertain] là `true`, mức cảnh báo bị HẠ TRẦN xuống
  /// `reviewRequired` kể cả khi khớp chính xác, và không khớp gì cũng vẫn trả
  /// về `reviewRequired` — chữ đọc không chắc thì kết luận nào cũng không
  /// chắc, thà nhắc người dùng tự soi lại đơn gốc.
  ///
  /// Hồ sơ dị ứng rỗng thì trả [AllergySeverity.none] ngay, không phải là
  /// "đã kiểm tra và an toàn".
  ///
  /// [itemName]       Tên thuốc từ OCR (vd. "Amoxicillin 500mg").
  /// [itemGroupHints] Gợi ý nhóm thuốc từ OCR (vd. `["Penicillin"]`).
  /// [userAllergies]  Danh sách dị ứng phẳng trong hồ sơ người dùng.
  /// [ocrUncertain]   `true` khi độ tin cậy OCR trung bình < 0.65.
  static AllergyMatch checkItem({
    required String itemName,
    required List<String> itemGroupHints,
    required List<String> userAllergies,
    bool ocrUncertain = false,
  }) {
    if (userAllergies.isEmpty) {
      return AllergyMatch(
        itemName: itemName,
        severity: AllergySeverity.none,
        matchType: AllergyMatchType.none,
        confidence: 0,
        reason: '',
      );
    }

    final normItem = _normalize(itemName);

    for (final allergy in userAllergies) {
      final normAllergy = _normalize(allergy);
      if (normAllergy.isEmpty) continue;

      // Tầng 1 — trùng khớp hoàn toàn sau chuẩn hoá
      if (normItem == normAllergy) {
        return AllergyMatch(
          itemName: itemName,
          severity: ocrUncertain
              ? AllergySeverity.reviewRequired
              : AllergySeverity.highRisk,
          matchType: AllergyMatchType.exact,
          confidence: 1.0,
          reason: 'Tên thuốc khớp với dị ứng đã khai báo: "$allergy"',
          matchedAllergy: allergy,
        );
      }

      // Tầng 2 — một bên chứa bên kia (đã chặn chuỗi quá ngắn)
      if (normAllergy.length >= _minContainsLen &&
          (normItem.contains(normAllergy) || normAllergy.contains(normItem))) {
        return AllergyMatch(
          itemName: itemName,
          severity: ocrUncertain
              ? AllergySeverity.reviewRequired
              : AllergySeverity.highRisk,
          matchType: AllergyMatchType.contains,
          confidence: 0.92,
          reason: 'Tên thuốc chứa hoạt chất trùng với dị ứng: "$allergy"',
          matchedAllergy: allergy,
        );
      }
    }

    // Tầng 3 — gợi ý nhóm thuốc từ OCR chồng lấn hồ sơ dị ứng
    for (final hint in itemGroupHints) {
      final normHint = _normalize(hint);
      if (normHint.isEmpty || normHint.length < _minContainsLen) continue;
      for (final allergy in userAllergies) {
        final normAllergy = _normalize(allergy);
        if (normAllergy.isEmpty) continue;
        if (normHint.contains(normAllergy) || normAllergy.contains(normHint)) {
          return AllergyMatch(
            itemName: itemName,
            severity: AllergySeverity.reviewRequired,
            matchType: AllergyMatchType.groupHint,
            confidence: 0.75,
            reason:
                'Thuốc thuộc nhóm có thể liên quan đến dị ứng "$allergy" - cần kiểm tra lại',
            matchedAllergy: allergy,
          );
        }
      }
    }

    // OCR không chắc mà không khớp gì: vẫn nhắc người dùng tự kiểm tra
    if (ocrUncertain) {
      return AllergyMatch(
        itemName: itemName,
        severity: AllergySeverity.reviewRequired,
        matchType: AllergyMatchType.none,
        confidence: 0,
        reason:
            'OCR đọc tên thuốc với độ tin cậy thấp - cần đối chiếu đơn gốc trước khi dùng',
      );
    }

    return AllergyMatch(
      itemName: itemName,
      severity: AllergySeverity.none,
      matchType: AllergyMatchType.none,
      confidence: 0,
      reason: '',
    );
  }

  /// Chuẩn hoá tên thuốc / tên dị ứng trước khi so sánh: về chữ thường, bỏ
  /// hàm lượng kèm đơn vị, chỉ giữ lại chữ cái `a-z` và khoảng trắng.
  ///
  /// Chỉ giữ chữ cái latin là đủ cho giai đoạn 1 vì tên hoạt chất in trên đơn
  /// thuốc Việt Nam đều viết theo chữ latin không dấu ("Amoxicillin",
  /// "Paracetamol") — nhờ vậy không phải thêm package bỏ dấu.
  ///
  /// **Hệ quả cần biết:** mọi ký tự tiếng Việt có dấu đều bị thay bằng khoảng
  /// trắng, nên mục dị ứng người dùng tự gõ bằng tiếng Việt sẽ bị băm nhỏ
  /// ("hải sản" → "h i s n") và gần như không khớp được gì. Hồ sơ dị ứng vì
  /// thế chỉ hoạt động đúng với tên hoạt chất viết không dấu. Muốn đỡ cả tên
  /// tiếng Việt thì phải bỏ dấu thay vì loại bỏ ký tự — đây là việc của giai
  /// đoạn sau.
  static String _normalize(String s) {
    // về chữ thường
    var n = s.toLowerCase().trim();
    // bỏ hàm lượng kèm đơn vị: "500mg", "1 ml", "250 mcg"…
    n = n.replaceAll(
      RegExp(r'\d+(?:[.,]\d+)?\s*(?:mg|ml|g|mcg|iu|ui)\b'),
      ' ',
    );
    // chỉ giữ chữ cái latin và khoảng trắng
    n = n.replaceAll(RegExp(r'[^a-z\s]'), ' ');
    // gộp khoảng trắng thừa
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }
}

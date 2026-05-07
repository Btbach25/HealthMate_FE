// Allergy matching engine — Phase 1 MVP.
// Runs entirely on-device against the user's locally-stored allergy list.
// Three-tier strategy: exact -> contains -> OCR group-hint overlap.
// OCR uncertainty caps severity at REVIEW_REQUIRED regardless of match tier.

enum AllergyMatchType { exact, contains, groupHint, none }

enum AllergySeverity { highRisk, reviewRequired, none }

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

  /// Human-readable reason shown in the per-item warning row.
  final String reason;

  final double confidence;

  /// The entry from the user's allergy profile that triggered the match.
  final String? matchedAllergy;

  bool get hasWarning => severity != AllergySeverity.none;
}

class AllergyMatcher {
  // Minimum token length to participate in contains-matching.
  // Prevents short tokens like "al" in "Calci" matching "Aspirin".
  static const int _minContainsLen = 5;

  /// Check a single parsed prescription item against the user's allergy list.
  ///
  /// [itemName]      Normalized drug name from OCR (e.g. "Amoxicillin 500mg").
  /// [itemGroupHints] Drug-class hints from OCR-service (e.g. ["Penicillin"]).
  /// [userAllergies] Flat list of allergy strings from the user's profile.
  /// [ocrUncertain]  True when avg OCR confidence < 0.65 — caps at REVIEW.
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

      // Tier 1 — exact after normalize
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

      // Tier 2 — one side contains the other (guards against short tokens)
      if (normAllergy.length >= _minContainsLen &&
          (normItem.contains(normAllergy) ||
              normAllergy.contains(normItem))) {
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

    // Tier 3 — OCR group-hint overlap with user allergy list
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

    // OCR uncertain with no match → still flag for manual review
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

  /// Normalize a drug/allergy name for comparison:
  /// lowercase, remove dosage units, collapse whitespace, keep [a-z] only.
  ///
  /// Vietnamese drug names on prescriptions are Latin-script, so this is
  /// sufficient for Phase 1 without a diacritic-removal package.
  static String _normalize(String s) {
    // lowercase
    var n = s.toLowerCase().trim();
    // remove dosage amounts with units: "500mg", "1 ml", "250 mcg" etc.
    n = n.replaceAll(
      RegExp(r'\d+(?:[.,]\d+)?\s*(?:mg|ml|g|mcg|iu|ui)\b'),
      ' ',
    );
    // keep only latin letters and spaces
    n = n.replaceAll(RegExp(r'[^a-z\s]'), ' ');
    // collapse spaces
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }
}

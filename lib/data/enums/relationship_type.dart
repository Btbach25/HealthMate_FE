/// Enum for family relationship types
/// Used to manage relationship options in a type-safe way
enum RelationshipType {
  father,
  mother,
  son,
  daughter,
  olderBrother,
  olderSister,
  youngerBrother,
  youngerSister,
  grandfather,
  grandmother,
  other;

  /// Returns the Vietnamese display label for the relationship
  String get displayLabel {
    switch (this) {
      case RelationshipType.father:
        return 'Bố';
      case RelationshipType.mother:
        return 'Mẹ';
      case RelationshipType.son:
        return 'Con trai';
      case RelationshipType.daughter:
        return 'Con gái';
      case RelationshipType.olderBrother:
        return 'Anh';
      case RelationshipType.olderSister:
        return 'Chị';
      case RelationshipType.youngerBrother:
        return 'Em trai';
      case RelationshipType.youngerSister:
        return 'Em gái';
      case RelationshipType.grandfather:
        return 'Ông';
      case RelationshipType.grandmother:
        return 'Bà';
      case RelationshipType.other:
        return 'Khác';
    }
  }

  /// Returns the string value for API/backend (same as displayLabel for now)
  String get value => displayLabel;

  /// Creates RelationshipType from a string value
  static RelationshipType? fromValue(String? value) {
    if (value == null) return null;

    switch (value) {
      case 'Bố':
        return RelationshipType.father;
      case 'Mẹ':
        return RelationshipType.mother;
      case 'Con trai':
        return RelationshipType.son;
      case 'Con gái':
        return RelationshipType.daughter;
      case 'Anh':
        return RelationshipType.olderBrother;
      case 'Chị':
        return RelationshipType.olderSister;
      case 'Em trai':
        return RelationshipType.youngerBrother;
      case 'Em gái':
        return RelationshipType.youngerSister;
      case 'Ông':
        return RelationshipType.grandfather;
      case 'Bà':
        return RelationshipType.grandmother;
      case 'Khác':
        return RelationshipType.other;
      default:
        return null;
    }
  }

  /// Returns all available relationship types
  static List<RelationshipType> get all => RelationshipType.values;

  /// Returns all relationship types as display labels
  static List<String> get allLabels =>
      RelationshipType.values.map((r) => r.displayLabel).toList();
}

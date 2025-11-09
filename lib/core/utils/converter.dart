DateTime? cvToDate(String? dateString) {
  if (dateString == null) {
    return null;
  }
  return DateTime.tryParse(dateString);
}

DateTime cvToDateRequired(String dateString) {
  return DateTime.parse(dateString);
}
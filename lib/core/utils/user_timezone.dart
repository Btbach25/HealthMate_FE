String resolveUserTimezone() {
  final now = DateTime.now();
  final name = now.timeZoneName.trim();

  // Go service side often needs an IANA timezone.
  // For Vietnam devices, normalize common names to Asia/Ho_Chi_Minh.
  const vnNames = {'ICT', 'Indochina Time', 'GMT+07:00', '+07', '+07:00'};
  if (vnNames.contains(name)) {
    return 'Asia/Ho_Chi_Minh';
  }

  if (name.isNotEmpty && name.contains('/')) {
    return name;
  }

  final offset = now.timeZoneOffset;
  if (offset.inHours == 7 && offset.inMinutes.remainder(60) == 0) {
    return 'Asia/Ho_Chi_Minh';
  }

  // Fallback still provides a stable value even if not IANA.
  return name.isNotEmpty ? name : 'UTC';
}

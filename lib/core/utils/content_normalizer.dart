String normalizeContent(String input) {
  final normalized = input.replaceFirst(RegExp(r'\s+$'), '');
  if (normalized.trim().isEmpty) {
    throw ArgumentError.value(input, 'content');
  }
  return normalized;
}

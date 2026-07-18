String relativeSurfacedAge(DateTime surfacedAt, DateTime now) {
  final difference = now.difference(surfacedAt);
  if (difference.isNegative || difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${difference.inDays ~/ 7}w ago';
}

String rescueMetadata(int rescueCount) =>
    rescueCount > 0 ? '↑ $rescueCount' : '';

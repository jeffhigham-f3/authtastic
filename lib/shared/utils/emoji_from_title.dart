String emojiFromTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('git')) return '🐙';
  if (lower.contains('mail') || lower.contains('gmail')) return '📧';
  if (lower.contains('aws')) return '☁️';
  if (lower.contains('netflix')) return '🎬';
  if (lower.contains('spotify')) return '🎵';
  if (lower.contains('slack')) return '💬';
  if (lower.contains('discord')) return '🎮';
  if (lower.contains('twitter') || lower.contains('x.com')) return '🐦';
  if (lower.contains('google')) return '🔍';
  if (lower.contains('microsoft')) return '🪟';
  return '🔐';
}

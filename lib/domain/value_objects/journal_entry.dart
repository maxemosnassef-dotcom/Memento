class JournalEntry {
  static const int maxLength = 20000;

  final String text;

  const JournalEntry._(this.text);

  factory JournalEntry.of(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'journal', 'must not be empty');
    }
    if (trimmed.length > maxLength) {
      throw ArgumentError.value(
        trimmed.length,
        'journal',
        'exceeds $maxLength characters',
      );
    }
    return JournalEntry._(trimmed);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is JournalEntry && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

final _prefixPattern = RegExp(r'^[\p{L}\p{N}_-]+:', unicode: true);

String? parsePrefix(String content) => _prefixPattern.stringMatch(content);

int prefixPaletteIndex(String prefix, int paletteLength) {
  if (paletteLength <= 0) {
    throw ArgumentError.value(paletteLength, 'paletteLength');
  }

  var hash = 0x811c9dc5;
  for (final rune in prefix.toLowerCase().runes) {
    hash ^= rune;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash % paletteLength;
}

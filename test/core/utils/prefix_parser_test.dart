import 'package:flutter_test/flutter_test.dart';
import 'package:tide/core/utils/prefix_parser.dart';

void main() {
  test('detects only an initial unicode prefix token', () {
    expect(parsePrefix('todo: ship'), 'todo:');
    expect(parsePrefix('étude: revoir'), 'étude:');
    expect(parsePrefix('two words: no'), isNull);
    expect(parsePrefix(' text: no'), isNull);
    expect(parsePrefix('body todo: no'), isNull);
  });

  test('prefix palette hash is case insensitive and deterministic', () {
    expect(prefixPaletteIndex('IDEA:', 6), prefixPaletteIndex('idea:', 6));
    expect(prefixPaletteIndex('IDEA:', 6), prefixPaletteIndex('IDEA:', 6));
  });
}

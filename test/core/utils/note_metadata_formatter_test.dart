import 'package:flutter_test/flutter_test.dart';
import 'package:tide/core/utils/note_metadata_formatter.dart';

void main() {
  final now = DateTime(2026, 7, 19, 12);

  test('relative surfaced age uses compact stable units', () {
    expect(
      relativeSurfacedAge(now.subtract(const Duration(seconds: 20)), now),
      'now',
    );
    expect(
      relativeSurfacedAge(now.subtract(const Duration(minutes: 8)), now),
      '8m ago',
    );
    expect(
      relativeSurfacedAge(now.subtract(const Duration(hours: 3)), now),
      '3h ago',
    );
    expect(
      relativeSurfacedAge(now.subtract(const Duration(days: 2)), now),
      '2d ago',
    );
    expect(
      relativeSurfacedAge(now.subtract(const Duration(days: 15)), now),
      '2w ago',
    );
  });

  test('future surfaced time is treated as now', () {
    expect(
      relativeSurfacedAge(now.add(const Duration(minutes: 2)), now),
      'now',
    );
  });

  test('rescue metadata is absent at zero and compact otherwise', () {
    expect(rescueMetadata(0), isEmpty);
    expect(rescueMetadata(1), '↑ 1');
    expect(rescueMetadata(12), '↑ 12');
  });
}

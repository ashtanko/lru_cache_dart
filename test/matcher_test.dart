import 'package:test/test.dart';

void main() {
  group('Matcher Tests', () {
    test('should work with throwsA and isA', () {
      expect(() => throw AssertionError('test'), throwsA(isA<AssertionError>()));
      expect(() => throw StateError('test'), throwsA(isA<StateError>()));
    });

    test('should work with isNull', () {
      expect(null, isNull);
      expect('not null', isNot(isNull));
    });

    test('should work with isEmpty and isNotEmpty', () {
      expect([], isEmpty);
      expect([1, 2, 3], isNotEmpty);
    });

    test('should work with contains', () {
      expect([1, 2, 3], contains(2));
      expect(['a', 'b', 'c'], contains('b'));
    });

    test('should work with greaterThan and lessThan', () {
      expect(5, greaterThan(3));
      expect(3, lessThan(5));
      expect(5, lessThanOrEqualTo(5));
    });

    test('should work with closeTo', () {
      expect(3.14159, closeTo(3.14, 0.01));
    });
  });
}
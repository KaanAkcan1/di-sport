import 'package:disport/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ok carries value and reports success', () {
    const Result<int> r = Ok(42);
    expect(r.isOk, isTrue);
    expect(r.valueOrNull, 42);
  });

  test('Err carries failure and no value', () {
    const Result<int> r = Err(Failure(message: 'boom'));
    expect(r.isOk, isFalse);
    expect(r.valueOrNull, isNull);
    expect((r as Err<int>).failure.message, 'boom');
  });

  test('switch destructures both cases', () {
    String describe(Result<int> r) => switch (r) {
      Ok(:final value) => 'ok:$value',
      Err(:final failure) => 'err:${failure.message}',
    };
    expect(describe(const Ok(7)), 'ok:7');
    expect(describe(const Err(Failure(message: 'x'))), 'err:x');
  });
}

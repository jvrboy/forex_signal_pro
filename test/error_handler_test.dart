import 'package:flutter_test/flutter_test.dart';
import 'package:forex_signal_pro/core/error/app_exceptions.dart';

void main() {
  group('AppException', () {
    test('creates with message and optional code', () {
      final ex = AppException('Test error', code: 'ERR001');
      expect(ex.message, 'Test error');
      expect(ex.code, 'ERR001');
    });

    test('toString includes code when present', () {
      final ex = AppException('Test error', code: 'ERR001');
      expect(ex.toString(), contains('ERR001'));
      expect(ex.toString(), contains('Test error'));
    });
  });

  group('Result', () {
    test('success creates result with data', () {
      final result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 42);
    });

    test('failure creates result with error', () {
      final error = AppException('Something wrong');
      final result = Result<int>.failure(error);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.error, error);
    });

    test('fold calls correct callback', () {
      final success = Result<int>.success(42);
      final failure = Result<int>.failure(AppException('error'));

      expect(success.fold((d) => 'got $d', (e) => 'error'), 'got 42');
      expect(failure.fold((d) => 'got $d', (e) => 'error'), 'error');
    });

    test('getOrThrow returns data or throws', () {
      expect(Result<int>.success(42).getOrThrow(), 42);
      expect(() => Result<int>.failure(AppException('e')).getOrThrow(), throwsException);
    });

    test('getOrNull returns data or null', () {
      expect(Result<int>.success(42).getOrNull(), 42);
      expect(Result<int>.failure(AppException('e')).getOrNull(), isNull);
    });
  });

  group('NetworkException', () {
    test('inherits from AppException', () {
      final ex = NetworkException('Connection failed');
      expect(ex, isA<AppException>());
      expect(ex.message, 'Connection failed');
    });
  });

  group('DerivException', () {
    test('includes optional errorCode', () {
      final ex = DerivException('Invalid token', errorCode: 101);
      expect(ex.errorCode, 101);
    });
  });

  group('AuthException', () {
    test('creates auth-specific exception', () {
      final ex = AuthException('Unauthorized');
      expect(ex.message, 'Unauthorized');
    });
  });

  group('DataException', () {
    test('creates data-specific exception', () {
      final ex = DataException('Parse error');
      expect(ex.message, 'Parse error');
    });
  });
}

class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.stackTrace});
}

class DerivException extends AppException {
  final int? errorCode;

  const DerivException(super.message, {this.errorCode, super.code, super.stackTrace});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.stackTrace});
}

class SignalException extends AppException {
  const SignalException(super.message, {super.code, super.stackTrace});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.stackTrace});
}

class DataException extends AppException {
  const DataException(super.message, {super.code, super.stackTrace});
}

class IndicatorException extends AppException {
  const IndicatorException(super.message, {super.code, super.stackTrace});
}

class StrategyException extends AppException {
  const StrategyException(super.message, {super.code, super.stackTrace});
}

class AiException extends AppException {
  const AiException(super.message, {super.code, super.stackTrace});
}

class ChartException extends AppException {
  const ChartException(super.message, {super.code, super.stackTrace});
}

class ParsingException extends AppException {
  const ParsingException(super.message, {super.code, super.stackTrace});
}

class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.code, super.stackTrace});
}

class Result<T> {
  final T? data;
  final AppException? error;

  const Result({this.data, this.error});

  bool get isSuccess => data != null && error == null;
  bool get isFailure => error != null;

  static Result<T> success<T>(T data) => Result<T>(data: data);
  static Result<T> failure<T>(AppException error) => Result<T>(error: error);

  R fold<R>(R Function(T) onSuccess, R Function(AppException) onFailure) {
    if (isSuccess) return onSuccess(data as T);
    return onFailure(error!);
  }

  T? getOrNull() => data;
  T getOrThrow() {
    if (isSuccess) return data as T;
    throw error!;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'app_exceptions.dart';

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 120),
  );
});

final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler(ref.read(loggerProvider));
});

class ErrorHandler {
  final Logger _logger;
  final List<AppException> _recentErrors = [];
  static const _maxRecentErrors = 20;

  ErrorHandler(this._logger);

  void handle(AppException exception, {String? context}) {
    _logger.e('${context ?? "Error"}: ${exception.message}', error: exception, stackTrace: exception.stackTrace);
    _recentErrors.add(exception);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
  }

  void log(String message) {
    _logger.i(message);
  }

  void logWarning(String message) {
    _logger.w(message);
  }

  List<AppException> get recentErrors => List.unmodifiable(_recentErrors);
  void clearErrors() => _recentErrors.clear();

  static void showSnackBar(BuildContext context, AppException exception) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(exception.message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension AppExceptionHandler on WidgetRef {
  void handleError(AppException exception, {String? context}) {
    read(errorHandlerProvider).handle(exception, context: context);
  }
}

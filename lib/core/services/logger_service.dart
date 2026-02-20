import 'package:flutter/foundation.dart';

/// Log levels: DEBUG, INFO, WARNING, ERROR
enum LogLevel { debug, info, warning, error }

/// Logger service to centralize all logging in the app
/// Replace all print() and debugPrint() calls with this service
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal();

  /// Log a message with optional level and tag
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Error? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    final levelStr = level.toString().split('.').last.toUpperCase();

    if (error != null) {
      if (kDebugMode) {
        print('$timestamp $levelStr $tagStr: $message\nError: $error');
      }
    } else {
      if (kDebugMode) {
        print('$timestamp $levelStr $tagStr: $message');
      }
    }
    if (stackTrace != null) {
      if (kDebugMode) {
        print('StackTrace:\n$stackTrace');
      }
    }
  }

  /// Convenience methods for each level
  void debug(String message, {String? tag}) =>
      log(message, level: LogLevel.debug, tag: tag);

  void info(String message, {String? tag}) =>
      log(message, level: LogLevel.info, tag: tag);

  void warning(String message, {String? tag}) =>
      log(message, level: LogLevel.warning, tag: tag);

  void error(
    String message, {
    String? tag,
    Error? error,
    StackTrace? stackTrace,
  }) => log(
    message,
    level: LogLevel.error,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Convenience getter
final logger = LoggerService();

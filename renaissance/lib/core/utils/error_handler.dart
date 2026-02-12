import 'dart:developer' as developer;
import 'package:flutter/material.dart';

// 错误处理工具类
class ErrorHandler {
  static void handleError(Object error, StackTrace stackTrace, {String? context}) {
    // 记录错误日志
    _logError(error, stackTrace, context: context);

    // 根据错误类型处理
    if (error is NetworkException) {
      _handleNetworkError(error);
    } else if (error is AudioException) {
      _handleAudioError(error);
    } else if (error is StorageException) {
      _handleStorageError(error);
    } else {
      _handleUnknownError(error);
    }
  }

  static void _logError(Object error, StackTrace stackTrace, {String? context}) {
    final message = StringBuffer();
    message.writeln('╔═══════════════════════════════════════════════════════════');
    message.writeln('║ ❌ ERROR ${context != null ? '[$context]' : ''}');
    message.writeln('╠═══════════════════════════════════════════════════════════');
    message.writeln('║ Type: ${error.runtimeType}');
    message.writeln('║ Message: $error');
    message.writeln('╠═══════════════════════════════════════════════════════════');
    message.writeln('║ Stack Trace:');
    
    final stackLines = stackTrace.toString().split('\n');
    for (var i = 0; i < stackLines.length && i < 10; i++) {
      message.writeln('║ ${stackLines[i]}');
    }
    
    message.writeln('╚═══════════════════════════════════════════════════════════');

    developer.log(
      message.toString(),
      name: 'RenaissanceError',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _handleNetworkError(NetworkException error) {
    developer.log('Network error: ${error.message}', name: 'Network');
  }

  static void _handleAudioError(AudioException error) {
    developer.log('Audio error: ${error.message}', name: 'Audio');
  }

  static void _handleStorageError(StorageException error) {
    developer.log('Storage error: ${error.message}', name: 'Storage');
  }

  static void _handleUnknownError(Object error) {
    developer.log('Unknown error: $error', name: 'Unknown');
  }

  // 显示错误对话框
  static void showErrorDialog(BuildContext context, String message, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? '错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示错误提示
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// 自定义异常类
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

class AudioException implements Exception {
  final String message;
  final AudioErrorType type;

  AudioException(this.message, {this.type = AudioErrorType.unknown});

  @override
  String toString() => 'AudioException: $message (Type: $type)';
}

enum AudioErrorType {
  loadFailed,
  playFailed,
  seekFailed,
  unknown,
}

class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

// 日志工具类
class Logger {
  static const String _name = 'Renaissance';

  static void debug(String message, {String? tag}) {
    _log('DEBUG', message, tag: tag, color: '\x1B[34m');
  }

  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag, color: '\x1B[32m');
  }

  static void warning(String message, {String? tag}) {
    _log('WARNING', message, tag: tag, color: '\x1B[33m');
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag: tag, color: '\x1B[31m', error: error, stackTrace: stackTrace);
  }

  static void _log(
    String level,
    String message, {
    String? tag,
    String? color,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '[$timestamp] $level $tagStr: $message';

    developer.log(
      logMessage,
      name: _name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

// 全局错误边界
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    // 设置全局错误处理
    FlutterError.onError = (details) {
      setState(() {
        _error = details;
      });
      ErrorHandler.handleError(
        details.exception,
        details.stack ?? StackTrace.empty,
        context: 'FlutterError',
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _defaultErrorWidget(_error!);
    }
    return widget.child;
  }

  Widget _defaultErrorWidget(FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '出错了',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details.exception.toString(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

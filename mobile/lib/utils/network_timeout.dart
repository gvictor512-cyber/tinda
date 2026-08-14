import 'dart:async';
import '../utils/secure_logger.dart';

class NetworkTimeout {
  // Default timeout durations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration downloadTimeout = Duration(minutes: 2);

  /// Execute a future with a timeout
  static Future<T> execute<T>(
    Future<T> future, {
    Duration? timeout,
    String? operationName,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final result = await future.timeout(
        effectiveTimeout,
        onTimeout: () {
          stopwatch.stop();
          SecureLogger.warning(
            'Operation timeout',
            data: {
              'operation': operationName ?? 'unknown',
              'timeout': effectiveTimeout.inSeconds,
            },
          );
          throw TimeoutException(
            'La operación excedió el tiempo límite de ${effectiveTimeout.inSeconds} segundos',
            effectiveTimeout,
          );
        },
      );

      stopwatch.stop();
      SecureLogger.logPerformance(
        operationName ?? 'Network operation',
        stopwatch.elapsed,
      );

      return result;
    } on TimeoutException catch (e) {
      SecureLogger.error(
        'Operation timed out',
        error: e,
        data: {
          'operation': operationName ?? 'unknown',
          'timeout': effectiveTimeout.inSeconds,
        },
      );
      rethrow;
    } catch (e) {
      SecureLogger.error(
        'Operation failed',
        error: e,
        data: {
          'operation': operationName ?? 'unknown',
        },
      );
      rethrow;
    }
  }

  /// Execute with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    int attempts = 0;
    List<dynamic> errors = [];

    while (attempts < maxAttempts) {
      attempts++;
      
      try {
        return await execute(
          operation(),
          timeout: timeout,
          operationName: operationName != null 
              ? '$operationName (attempt $attempts/$maxAttempts)' 
              : null,
        );
      } catch (e) {
        errors.add(e);
        
        if (attempts >= maxAttempts) {
          SecureLogger.error(
            'Operation failed after $maxAttempts attempts',
            error: errors.last,
            data: {
              'operation': operationName ?? 'unknown',
              'attempts': attempts,
            },
          );
          throw NetworkException(
            'La operación falló después de $maxAttempts intentos',
            errors: errors,
          );
        }

        // Exponential backoff
        final delay = retryDelay * (1 << (attempts - 1));
        SecureLogger.warning(
          'Operation attempt $attempts failed, retrying in ${delay.inSeconds}s',
          data: {
            'operation': operationName ?? 'unknown',
            'error': e.toString(),
          },
        );
        
        await Future.delayed(delay);
      }
    }

    throw NetworkException(
      'La operación falló después de $maxAttempts intentos',
      errors: errors,
    );
  }

  /// Execute multiple futures in parallel with individual timeouts
  static Future<List<T>> executeAll<T>(
    List<Future<T>> futures, {
    Duration? timeout,
    String? operationName,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final results = await Future.wait(
        futures.map((future) => future.timeout(effectiveTimeout)),
      ).timeout(effectiveTimeout);

      stopwatch.stop();
      SecureLogger.logPerformance(
        operationName ?? 'Parallel operations',
        stopwatch.elapsed,
        context: {
          'count': futures.length,
        },
      );

      return results;
    } on TimeoutException catch (e) {
      SecureLogger.error(
        'Parallel operations timed out',
        error: e,
        data: {
          'operation': operationName ?? 'unknown',
          'count': futures.length,
        },
      );
      rethrow;
    } catch (e) {
      SecureLogger.error(
        'Parallel operations failed',
        error: e,
        data: {
          'operation': operationName ?? 'unknown',
        },
      );
      rethrow;
    }
  }

  /// Execute futures in sequence with individual timeouts
  static Future<List<T>> executeSequential<T>(
    List<Future<T>> futures, {
    Duration? timeout,
    String? operationName,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;
    final results = <T>[];

    for (int i = 0; i < futures.length; i++) {
      try {
        final result = await execute(
          futures[i],
          timeout: effectiveTimeout,
          operationName: operationName != null 
              ? '$operationName (step ${i + 1}/${futures.length})' 
              : null,
        );
        results.add(result);
      } catch (e) {
        SecureLogger.error(
          'Sequential operation failed at step ${i + 1}',
          error: e,
          data: {
            'operation': operationName ?? 'unknown',
            'step': i + 1,
            'total': futures.length,
          },
        );
        rethrow;
      }
    }

    return results;
  }

  /// Execute with circuit breaker pattern
  static Future<T> executeWithCircuitBreaker<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    int failureThreshold = 5,
    Duration recoveryTimeout = const Duration(minutes: 1),
    String? operationName,
  }) async {
    final circuitBreaker = _CircuitBreaker(
      failureThreshold: failureThreshold,
      recoveryTimeout: recoveryTimeout,
      operationName: operationName ?? 'unknown',
    );

    if (circuitBreaker.isOpen) {
      throw CircuitBreakerException(
        'Circuit breaker is open for ${operationName ?? "operation"}',
      );
    }

    try {
      final result = await execute(
        operation(),
        timeout: timeout,
        operationName: operationName,
      );
      
      circuitBreaker.recordSuccess();
      return result;
    } catch (e) {
      circuitBreaker.recordFailure();
      rethrow;
    }
  }
}

class _CircuitBreaker {
  final int failureThreshold;
  final Duration recoveryTimeout;
  final String operationName;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  _CircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
    required this.operationName,
  });

  bool get isOpen {
    if (!_isOpen) return false;
    
    // Check if recovery timeout has passed
    if (_lastFailureTime != null) {
      final elapsed = DateTime.now().difference(_lastFailureTime!);
      if (elapsed > recoveryTimeout) {
        _isOpen = false;
        _failureCount = 0;
        SecureLogger.info('Circuit breaker reset', data: {
          'operation': operationName,
        });
        return false;
      }
    }
    
    return true;
  }

  void recordSuccess() {
    if (_failureCount > 0) {
      _failureCount--;
      if (_failureCount == 0) {
        _isOpen = false;
        SecureLogger.info('Circuit breaker closed', data: {
          'operation': operationName,
        });
      }
    }
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _isOpen = true;
      SecureLogger.warning('Circuit breaker opened', data: {
        'operation': operationName,
        'failures': _failureCount,
      });
    }
  }
}

class NetworkException implements Exception {
  final String message;
  final List<dynamic>? errors;

  NetworkException(
    this.message, {
    this.errors,
  });

  @override
  String toString() => 'NetworkException: $message';
}

class CircuitBreakerException implements Exception {
  final String message;

  CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message';
}

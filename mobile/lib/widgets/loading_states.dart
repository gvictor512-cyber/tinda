import 'package:flutter/material.dart';
import '../config/theme.dart';

class LoadingStates {
  /// Full page loading indicator
  static Widget fullPage({
    String? message,
  }) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textDarkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Inline loading indicator
  static Widget inline({
    double size = 24,
    double strokeWidth = 2,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        strokeWidth: strokeWidth,
      ),
    );
  }

  /// Button loading state
  static Widget button({
    required bool isLoading,
    required Widget child,
    double size = 20,
  }) {
    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      );
    }
    return child;
  }

  /// Card loading skeleton
  static Widget cardSkeleton({
    double height = 200,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      ),
    );
  }

  /// List loading skeleton
  static Widget listSkeleton({
    int itemCount = 5,
    double itemHeight = 80,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    bool isLoading = true,
  }) {
    if (!isLoading) return child;
    
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

class ErrorStates {
  /// Full page error display
  static Widget fullPage({
    required String message,
    String? details,
    VoidCallback? onRetry,
    IconData icon = Icons.error_outline,
  }) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 80,
                  color: AppTheme.error.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (details != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDarkSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Intentar de nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Inline error display
  static Widget inline({
    required String message,
    VoidCallback? onRetry,
    bool showIcon = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon)
            const Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 20,
            ),
          if (showIcon) const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              color: AppTheme.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  /// Empty state display
  static Widget empty({
    required String message,
    String? subMessage,
    IconData icon = Icons.inbox_outlined,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textDarkSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDarkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Network error display
  static Widget network({
    VoidCallback? onRetry,
  }) {
    return fullPage(
      message: 'Error de conexión',
      details: 'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  /// Timeout error display
  static Widget timeout({
    VoidCallback? onRetry,
  }) {
    return fullPage(
      message: 'Tiempo de espera agotado',
      details: 'La operación tardó demasiado tiempo. Intenta de nuevo.',
      icon: Icons.access_time,
      onRetry: onRetry,
    );
  }

  /// Permission error display
  static Widget permission({
    required String permission,
    VoidCallback? onRequest,
  }) {
    return fullPage(
      message: 'Permiso requerido',
      details: 'Esta aplicación necesita acceso a $permission para funcionar.',
      icon: Icons.lock_outline,
      onRetry: onRequest,
    );
  }
}

class FutureBuilderWrapper<T> extends StatelessWidget {
  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final bool Function(T) isEmpty;

  const FutureBuilderWrapper({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ?? 
              LoadingStates.fullPage();
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ?? 
              ErrorStates.fullPage(
                message: 'Ocurrió un error',
                details: snapshot.error.toString(),
              );
        }

        if (!snapshot.hasData || isEmpty(snapshot.data as T)) {
          return emptyBuilder?.call(context) ?? 
              ErrorStates.empty(
                message: 'No hay datos disponibles',
              );
        }

        return builder(context, snapshot.data as T);
      },
    );
  }
}

class StreamBuilderWrapper<T> extends StatelessWidget {
  final Stream<T>? stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final bool Function(T) isEmpty;

  const StreamBuilderWrapper({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ?? 
              LoadingStates.fullPage();
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ?? 
              ErrorStates.fullPage(
                message: 'Ocurrió un error',
                details: snapshot.error.toString(),
              );
        }

        if (!snapshot.hasData || isEmpty(snapshot.data as T)) {
          return emptyBuilder?.call(context) ?? 
              ErrorStates.empty(
                message: 'No hay datos disponibles',
              );
        }

        return builder(context, snapshot.data as T);
      },
    );
  }
}

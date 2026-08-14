import 'package:flutter/material.dart';

/// Custom page transitions for the app
class PageTransitions {
  /// Slide transition from right to left
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Offset beginOffset = const Offset(1.0, 0.0),
    Offset endOffset = Offset.zero,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        var tween = Tween(begin: beginOffset, end: endOffset).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Fade transition
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Scale transition
  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    double beginScale = 0.8,
    double endScale = 1.0,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOut;
        var tween = Tween(begin: beginScale, end: endScale).chain(
          CurveTween(curve: curve),
        );
        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Slide and fade transition combination
  static PageRouteBuilder<T> slideAndFadeTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Offset beginOffset = const Offset(1.0, 0.0),
    Offset endOffset = Offset.zero,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        var slideTween = Tween(begin: beginOffset, end: endOffset).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }
}

import 'package:flutter/material.dart';

class HomeShadows {
  static BoxShadow soft({
    double alpha = 0.08,
    double blur = 20,
    double spread = 2,
    Offset offset = const Offset(0, 6),
  }) => BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      );

  static BoxShadow deeper({
    double alpha = 0.10,
    double blur = 24,
    double spread = 2,
    Offset offset = const Offset(0, 8),
  }) => BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      );
}

class HomeGradients {
  static LinearGradient card(
    Color a,
    Color b, {
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    double alpha = 0.85,
  }) => LinearGradient(
        begin: begin,
        end: end,
        colors: [
          a.withValues(alpha: alpha),
          b.withValues(alpha: alpha),
        ],
      );

  static LinearGradient shimmer(
    double t,
    Color surface,
    Color surfaceVariant, {
    double alpha = 0.6,
  }) => LinearGradient(
        begin: Alignment(-1 + t * 2, 0),
        end: Alignment(1 + t * 2, 0),
        colors: [
          surface,
          surfaceVariant.withValues(alpha: alpha),
          surface,
        ],
      );
}
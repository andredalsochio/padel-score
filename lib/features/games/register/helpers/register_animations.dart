import 'package:flutter/material.dart';

/// Shared animation durations and curves for subtle, purposeful motion.
class RegisterAnimations {
  const RegisterAnimations._();

  static const Duration tap = Duration(milliseconds: 120);
  static const Duration enter = Duration(milliseconds: 250);
  static const Duration exit = Duration(milliseconds: 200);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
}

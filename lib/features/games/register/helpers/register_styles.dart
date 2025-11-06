import 'package:flutter/material.dart';

/// Shared styles for the Register Game feature.
class RegisterStyles {
  const RegisterStyles._();

  static BorderRadius get cardRadius =>
      const BorderRadius.all(Radius.circular(16));

  static BoxShadow elevatedShadow(ColorScheme scheme) => BoxShadow(
    color: scheme.shadow.withValues(alpha: 0.12),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );

  static EdgeInsets get sectionPadding =>
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static EdgeInsets get cardPadding => const EdgeInsets.all(12);

  static Color surfaceHigh(ColorScheme scheme) =>
      scheme.surfaceContainerHighest;
  static Color surfaceLow(ColorScheme scheme) => scheme.surfaceContainerLowest;
}

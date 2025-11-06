import 'package:flutter/material.dart';

class HorizontalCards extends StatelessWidget {
  const HorizontalCards({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      scrollDirection: Axis.horizontal,
      children: children,
    );
  }
}

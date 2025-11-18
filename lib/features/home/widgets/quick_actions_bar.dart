import 'package:flutter/material.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key, required this.actions});
  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, i) => _ActionButton(action: actions[i]),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: actions.length,
      ),
    );
  }
}

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _ActionButton extends StatefulWidget {
  final QuickAction action;
  const _ActionButton({required this.action});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final scale = _pressed ? 0.96 : 1.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.action.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(widget.action.icon, color: scheme.primary),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                widget.action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class DuplaPlayerChip extends StatefulWidget {
  final String playerId;
  final String name;
  final int? team;
  final VoidCallback? onRemove;
  const DuplaPlayerChip({super.key, required this.playerId, required this.name, this.team, this.onRemove});

  @override
  State<DuplaPlayerChip> createState() => _DuplaPlayerChipState();
}

class _DuplaPlayerChipState extends State<DuplaPlayerChip> {
  bool _showDelete = false;
  Timer? _hideTimer;

  void _showDeleteTemporarily() {
    setState(() => _showDelete = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _showDelete = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.team == 1
        ? scheme.primaryContainer
        : (widget.team == 2 ? scheme.tertiaryContainer : scheme.surfaceContainerLow);
    final onBg = widget.team == 1
        ? scheme.onPrimaryContainer
        : (widget.team == 2 ? scheme.onTertiaryContainer : scheme.onSurface);
    final initials = _initials(widget.name);

    final chip = Chip(
      avatar: CircleAvatar(backgroundColor: onBg, foregroundColor: bg, child: Text(initials)),
      label: Text(widget.name),
      backgroundColor: bg,
      labelStyle: TextStyle(color: onBg),
    );

    return Draggable<String>(
      data: widget.playerId,
      feedback: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        elevation: 8,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(widget.name, style: TextStyle(color: onBg))),
      ),
      onDragStarted: () {
        _hideTimer?.cancel();
        setState(() => _showDelete = false);
      },
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: widget.onRemove == null
          ? chip
          : GestureDetector(
              onLongPress: _showDeleteTemporarily,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  chip,
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    right: _showDelete ? -6 : -24,
                    top: _showDelete ? -6 : -24,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _showDelete ? 1 : 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(scheme.errorContainer),
                          foregroundColor: WidgetStatePropertyAll(scheme.onErrorContainer),
                        ),
                        iconSize: 18,
                        onPressed: () {
                          _hideTimer?.cancel();
                          widget.onRemove?.call();
                          setState(() => _showDelete = false);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r"\s+"));
    final a = parts.isNotEmpty ? parts.first.characters.first : '';
    final b = parts.length > 1 ? parts[1].characters.first : '';
    return (a + b).toUpperCase();
  }
}
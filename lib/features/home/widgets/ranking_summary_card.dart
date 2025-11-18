import 'package:flutter/material.dart';
import '../helpers/home_styles.dart';
import 'stat_chip.dart';

class RankingSummaryCard extends StatelessWidget {
  const RankingSummaryCard({
    super.key,
    required this.expanded,
    required this.onToggle,
  });
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surface,
        boxShadow: [HomeShadows.soft()],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Your Ranking Summary',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: expanded
                    ? Padding(
                        key: const ValueKey('expanded'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                StatChip(label: 'Rating', value: '1,245'),
                                StatChip(label: 'Level', value: 'Pro'),
                                StatChip(label: 'Streak', value: '3'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: CustomPaint(
                                painter: _SparklinePainter([
                                  5,
                                  6,
                                  5,
                                  7,
                                  8,
                                  7,
                                  9,
                                  8,
                                  10,
                                ]),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ranking em evolução — continue jogando! ',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('collapsed')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> points;
  _SparklinePainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (points.isEmpty) return;
    final max = points.reduce((a, b) => a > b ? a : b).toDouble();
    final min = points.reduce((a, b) => a < b ? a : b).toDouble();
    final range = (max - min).abs() == 0 ? 1 : (max - min);
    final dx = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = size.height - ((points[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paintLine = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final paintFill = Paint()
      ..color = Colors.purple.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

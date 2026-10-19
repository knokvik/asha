import 'package:flutter/material.dart';

import '../domain/growth_models.dart';

/// Interactive visual widget plotting child weight against WHO growth percentile bands.
class GrowthChartWidget extends StatelessWidget {
  final List<GrowthMeasurement> measurements;
  final String sex;

  const GrowthChartWidget({
    super.key,
    required this.measurements,
    required this.sex,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text('No growth measurements recorded yet.'),
      );
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WHO Weight-for-Age Growth Curve',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  _legendDot('Normal', Colors.green),
                  const SizedBox(width: 8),
                  _legendDot('MAM / -2 SD', Colors.orange),
                  const SizedBox(width: 8),
                  _legendDot('SAM / -3 SD', Colors.red),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _WhoGrowthChartPainter(measurements: measurements, sex: sex),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Birth (0m)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              Text('1 Year (12m)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              Text('2 Years (24m)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              Text('3 Years (36m)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              Text('5 Years (60m)', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _WhoGrowthChartPainter extends CustomPainter {
  final List<GrowthMeasurement> measurements;
  final String sex;

  _WhoGrowthChartPainter({required this.measurements, required this.sex});

  @override
  void paint(Canvas canvas, Size size) {
    const maxMonths = 60.0;
    const maxWeight = 25.0; // kg max axis

    // Draw background WHO curve bands
    final paintGreenBand = Paint()..color = Colors.green.shade50.withValues(alpha: 0.6);

    // Simple band zones
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paintGreenBand);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1.0 - (i * 5.0 / maxWeight));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Reference Curves (-3 SD, -2 SD, Median 0 SD)
    final refMedianPaint = Paint()
      ..color = Colors.green.shade600
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final refMamPaint = Paint()
      ..color = Colors.orange.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final refSamPaint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Approximate WHO median and SD lines from 0 to 60 months
    final medianPath = Path();
    final mamPath = Path();
    final samPath = Path();

    for (double m = 0; m <= maxMonths; m += 3) {
      final x = (m / maxMonths) * size.width;
      // Linearized standard reference for boys/girls
      final medKg = sex == 'M' ? (3.3 + 0.23 * m) : (3.2 + 0.22 * m);
      final mamKg = medKg * 0.80; // approximate -2 SD threshold
      final samKg = medKg * 0.70; // approximate -3 SD threshold

      final yMed = size.height * (1.0 - (medKg / maxWeight));
      final yMam = size.height * (1.0 - (mamKg / maxWeight));
      final ySam = size.height * (1.0 - (samKg / maxWeight));

      if (m == 0) {
        medianPath.moveTo(x, yMed);
        mamPath.moveTo(x, yMam);
        samPath.moveTo(x, ySam);
      } else {
        medianPath.lineTo(x, yMed);
        mamPath.lineTo(x, yMam);
        samPath.lineTo(x, ySam);
      }
    }

    canvas.drawPath(medianPath, refMedianPaint);
    canvas.drawPath(mamPath, refMamPaint);
    canvas.drawPath(samPath, refSamPaint);

    // Plot child's recorded measurements
    final childLinePaint = Paint()
      ..color = Colors.indigo.shade800
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final childPointPaint = Paint()
      ..color = Colors.indigo.shade900
      ..style = PaintingStyle.fill;

    final childPath = Path();
    bool isFirst = true;

    for (final m in measurements) {
      final x = (m.ageInMonths.clamp(0.0, maxMonths) / maxMonths) * size.width;
      final y = size.height * (1.0 - (m.weightKg.clamp(0.0, maxWeight) / maxWeight));

      if (isFirst) {
        childPath.moveTo(x, y);
        isFirst = false;
      } else {
        childPath.lineTo(x, y);
      }

      // Point circle with border
      canvas.drawCircle(Offset(x, y), 5.0, childPointPaint);
      canvas.drawCircle(
        Offset(x, y),
        5.0,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    if (measurements.length > 1) {
      canvas.drawPath(childPath, childLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhoGrowthChartPainter oldDelegate) {
    return oldDelegate.measurements != measurements;
  }
}

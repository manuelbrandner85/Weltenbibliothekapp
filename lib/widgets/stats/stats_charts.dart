import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ============================================
/// CHARTS - Pie Chart & Line Chart
/// Custom painted charts without dependencies
/// ============================================

/// 1. SIMPLE PIE CHART
class SimplePieChart extends StatefulWidget {
  final Map<String, double> data; // {label: value}
  final Map<String, Color> colors; // {label: color}
  final double size;

  const SimplePieChart({
    super.key,
    required this.data,
    required this.colors,
    this.size = 200,
  });

  @override
  State<SimplePieChart> createState() => _SimplePieChartState();
}

class _SimplePieChartState extends State<SimplePieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pie Chart
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: PieChartPainter(
                  data: widget.data,
                  colors: widget.colors,
                  progress: _animation.value,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: widget.data.entries.map((entry) {
            final percentage = (entry.value /
                    widget.data.values.reduce((a, b) => a + b) *
                    100)
                .toStringAsFixed(1);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: widget.colors[entry.key] ?? Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.key} ($percentage%)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colors;
  final double progress;

  PieChartPainter({
    required this.data,
    required this.colors,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final total = data.values.reduce((a, b) => a + b);

    double startAngle = -math.pi / 2; // Start from top

    data.forEach((label, value) {
      final sweepAngle = (value / total) * 2 * math.pi * progress;
      final color = colors[label] ?? Colors.grey;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // White border between segments
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    });

    // Center white circle (donut effect)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 2. SIMPLE LINE CHART
class SimpleLineChart extends StatefulWidget {
  final List<double> dataPoints;
  final List<String> labels;
  final Color lineColor;
  final double height;
  final String? yAxisLabel;

  const SimpleLineChart({
    super.key,
    required this.dataPoints,
    required this.labels,
    required this.lineColor,
    this.height = 200,
    this.yAxisLabel,
  });

  @override
  State<SimpleLineChart> createState() => _SimpleLineChartState();
}

class _SimpleLineChartState extends State<SimpleLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.yAxisLabel != null) ...[
          Text(
            widget.yAxisLabel!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: widget.height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.lineColor.withValues(alpha: 0.2),
            ),
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: LineChartPainter(
                  dataPoints: widget.dataPoints,
                  labels: widget.labels,
                  lineColor: widget.lineColor,
                  progress: _animation.value,
                  isDark: isDark,
                ),
                size: Size(double.infinity, widget.height - 32),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final Color lineColor;
  final double progress;
  final bool isDark;

  LineChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.lineColor,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final maxValue = dataPoints.reduce(math.max);
    final minValue = dataPoints.reduce(math.min);
    final range = maxValue - minValue;

    // Grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate points
    final points = <Offset>[];
    final spacing = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final normalizedValue = range > 0 ? (dataPoints[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8 + size.height * 0.1);
      points.add(Offset(x, y));
    }

    // Draw gradient fill
    final gradientPath = Path();
    gradientPath.moveTo(points.first.dx, size.height);
    for (final point in points) {
      gradientPath.lineTo(point.dx, point.dy);
    }
    gradientPath.lineTo(points.last.dx, size.height);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3 * progress),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(gradientPath, gradientPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final currentProgress = progress * points.length;
      if (i <= currentProgress) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final currentProgress = progress * points.length;
      if (i <= currentProgress) {
        final pointPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;

        canvas.drawCircle(points[i], 4, pointPaint);

        final borderPaint = Paint()
          ..color = isDark ? Colors.grey[900]! : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(points[i], 4, borderPaint);
      }
    }

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < labels.length; i++) {
      final labelSpacing = size.width / labels.length;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(i * labelSpacing, size.height + 4),
      );
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 3. ACTIVITY HEATMAP (Streak Tracker)
class ActivityHeatmap extends StatelessWidget {
  final List<ActivityDay> days; // Last 30 days
  final Color activeColor;

  const ActivityHeatmap({
    super.key,
    required this.days,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivität (Letzte 30 Tage)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final intensity = day.articlesRead > 0
                ? (day.articlesRead / 5).clamp(0.2, 1.0)
                : 0.0;

            return Tooltip(
              message: '${day.date}\n${day.articlesRead} Artikel',
              child: Container(
                decoration: BoxDecoration(
                  color: intensity > 0
                      ? activeColor.withValues(alpha: intensity)
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Weniger',
              style: TextStyle(
                fontSize: 11,
                color:
                    (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              return Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: (index + 1) / 5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              'Mehr',
              style: TextStyle(
                fontSize: 11,
                color:
                    (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ActivityDay {
  final String date; // e.g., "2024-01-18"
  final int articlesRead;

  ActivityDay({required this.date, required this.articlesRead});
}

/// ============================================
/// PREMIUM STATS COMPONENTS
/// ============================================

/// 4. ANIMATED COUNTER CARD
class AnimatedCounterCard extends StatefulWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String suffix;

  const AnimatedCounterCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  State<AnimatedCounterCard> createState() => _AnimatedCounterCardState();
}

class _AnimatedCounterCardState extends State<AnimatedCounterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _counterAnimation = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color.withValues(alpha: 0.1),
            widget.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            widget.icon,
            color: widget.color,
            size: 28,
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _counterAnimation,
            builder: (context, child) {
              return Text(
                '${_counterAnimation.value}${widget.suffix}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. CATEGORY PIE CHART (Premium Version)
class CategoryPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data; // [{category, count, color}]
  final String world;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.world,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    // Konvertiere für SimplePieChart
    final chartData = <String, double>{};
    final chartColors = <String, Color>{};

    for (var item in data) {
      final category = item['category'] as String;
      final count = (item['count'] as int).toDouble();
      final color = item['color'] as Color;

      chartData[category] = count;
      chartColors[category] = color;
    }

    return SimplePieChart(
      data: chartData,
      colors: chartColors,
      size: 220,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 220,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Keine Daten verfügbar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lies ein paar Artikel, um Statistiken zu sehen!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 6. READING PROGRESS CHART (Premium Version)
class ReadingProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>> data; // [{date, progress}]
  final String world;

  const ReadingProgressChart({
    super.key,
    required this.data,
    required this.world,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    final worldColor = world == 'materie'
        ? const Color(0xFF1E88E5)
        : const Color(0xFF7E57C2);

    // Konvertiere für SimpleLineChart
    final dataPoints = data.map((e) => (e['progress'] as int).toDouble()).toList();
    final labels = <String>[];

    // Zeige nur jeden 5. Tag als Label
    for (int i = 0; i < data.length; i++) {
      if (i % 5 == 0 || i == data.length - 1) {
        final date = data[i]['date'] as DateTime;
        labels.add('${date.day}.${date.month}');
      } else {
        labels.add('');
      }
    }

    return SimpleLineChart(
      dataPoints: dataPoints,
      labels: labels,
      lineColor: worldColor,
      height: 200,
      yAxisLabel: 'Fortschritt (%)',
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Keine Verlaufsdaten',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 7. STREAK HEATMAP (GitHub-Style)
class StreakHeatmap extends StatelessWidget {
  final Map<String, int> data; // {"2024-01-18": 3, ...}
  final String world;

  const StreakHeatmap({
    super.key,
    required this.data,
    required this.world,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worldColor = world == 'materie'
        ? const Color(0xFF1E88E5)
        : const Color(0xFF7E57C2);

    // Sortiere Daten nach Datum
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Gruppiere nach Woche (7 Tage)
    final weeks = <List<MapEntry<String, int>>>[];
    for (int i = 0; i < sortedEntries.length; i += 7) {
      final end = (i + 7 < sortedEntries.length) ? i + 7 : sortedEntries.length;
      weeks.add(sortedEntries.sublist(i, end));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday Labels
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              _buildWeekdayLabel('Mo'),
              const Spacer(),
              _buildWeekdayLabel('Mi'),
              const Spacer(),
              _buildWeekdayLabel('Fr'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Heatmap Grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weeks.map((week) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: week.map((entry) {
                    final intensity = entry.value > 0
                        ? (entry.value / 5).clamp(0.15, 1.0)
                        : 0.0;

                    return Tooltip(
                      message: '${entry.key}\n${entry.value} Artikel',
                      child: Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: intensity > 0
                              ? worldColor.withValues(alpha: intensity)
                              : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Legend
        Row(
          children: [
            Text(
              'Weniger',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              return Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: worldColor.withValues(alpha: (index + 1) / 5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              'Mehr',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

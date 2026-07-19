import 'dart:math';

import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:babyland/core/theme/premium_app_theme.dart';

/// Smooth area + line chart for 7-day recovery scores.
class RecoveryTrendChart extends StatelessWidget {
  final List<DailyRecoveryPoint> points;
  final double height;

  const RecoveryTrendChart({
    super.key,
    required this.points,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final scores = points.map((p) => p.score).toList();
    final hasData = scores.any((s) => s > 0);
    final maxY = hasData ? max(100.0, scores.reduce(max) * 1.15) : 100.0;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DashboardTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly recovery trend',
            style: AppTextStylesPremium.h3(color: DashboardTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Recovery score by day (0–100)',
            style: AppTextStylesPremium.caption(color: DashboardTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: DashboardTheme.stroke,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 25,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: AppTextStylesPremium.caption(
                                color: DashboardTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  TrackerMath.chartDayLabel(now, points[i].date),
                                  style: AppTextStylesPremium.caption(
                                    color: DashboardTheme.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => DashboardTheme.textPrimary,
                          getTooltipItems: (spots) => spots.map((s) {
                            final i = s.x.toInt();
                            final score = s.y.toStringAsFixed(0);
                            return LineTooltipItem(
                              '${points[i].date.day}/${points[i].date.month}\n$score%',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            points.length,
                            (i) => FlSpot(i.toDouble(), scores[i]),
                          ),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: DashboardTheme.accentRose,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: DashboardTheme.accentRose,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                DashboardTheme.accentRose.withValues(alpha: 0.35),
                                DashboardTheme.accentRose.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                  )
                : Center(
                    child: Text(
                      'Log daily progress to see your trend',
                      style: AppTextStylesPremium.body(
                        color: DashboardTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

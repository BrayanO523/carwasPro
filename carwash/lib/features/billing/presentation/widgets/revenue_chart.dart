import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RevenueChart extends StatelessWidget {
  final Map<DateTime, double> dailyRevenue;

  const RevenueChart({super.key, required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    // 1. Sort dates
    final sortedDates = dailyRevenue.keys.toList()..sort();

    // 2. Prepare limits
    double maxRevenue = 0;
    for (var val in dailyRevenue.values) {
      if (val > maxRevenue) maxRevenue = val;
    }
    // Add 20% buffer
    final maxY = maxRevenue * 1.2;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade50),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingresos por Día',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    size: 16,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxY == 0 ? 1000 : maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          const Color(0xFF1E293B), // Slate 800
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'L. ${NumberFormat("#,##0.00", "en_US").format(rod.toY)}',
                          GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }
                          final date = sortedDates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              DateFormat(
                                'E',
                                'es',
                              ).format(date).toUpperCase(), // LUN, MAR
                              style: GoogleFonts.outfit(
                                color: Colors.blueGrey[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Clean look
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade100,
                      strokeWidth: 1,
                      dashArray: [5, 5], // Dotted visual
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedDates.length, (index) {
                    final date = sortedDates[index];
                    final value = dailyRevenue[date] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF60A5FA),
                            ], // Blue Gradient
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 12, // Thinner bars for elegance
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.grey.shade50,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../domain/entities/invoice.dart';

enum ChartViewMode { daily, weekly, monthly }

class RevenueChartData {
  final String label;
  final double revenue;
  final int count;

  RevenueChartData(this.label, this.revenue, this.count);
}

class RevenueChart extends StatefulWidget {
  final List<Invoice> invoices;

  const RevenueChart({super.key, required this.invoices});

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  ChartViewMode _viewMode = ChartViewMode.daily;
  late TrackballBehavior _trackballBehavior;

  // Premium Colors
  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _accentBlue = Color(0xFF60A5FA);
  static const Color _darkBlue = Color(0xFF1E40AF);

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: InteractiveTooltip(
        enable: true,
        color: const Color(0xFF1E293B),
        textStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      lineType: TrackballLineType.vertical,
      lineColor: _primaryBlue.withOpacity(0.3),
      lineWidth: 1,
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
        height: 8,
        width: 8,
        borderWidth: 2,
        color: Colors.white,
        borderColor: _primaryBlue,
      ),
    );
  }

  List<RevenueChartData> _getChartData() {
    final now = DateTime.now();

    switch (_viewMode) {
      case ChartViewMode.daily:
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final todayInvoices = widget.invoices
            .where(
              (inv) =>
                  inv.createdAt.isAfter(
                    todayStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  inv.createdAt.isBefore(todayEnd),
            )
            .toList();

        Map<int, double> hourlyData = {};
        Map<int, int> hourlyCounts = {};

        for (var inv in todayInvoices) {
          final hour = inv.createdAt.hour;
          hourlyData[hour] = (hourlyData[hour] ?? 0) + inv.totalAmount;
          hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + 1;
        }

        List<RevenueChartData> result = [];
        // Fixed Business Hours: 7am to 9pm (to ensure line continuity)
        for (int h = 7; h <= 21; h++) {
          final label = h < 12 ? '${h}am' : (h == 12 ? '12pm' : '${h - 12}pm');

          result.add(
            RevenueChartData(label, hourlyData[h] ?? 0, hourlyCounts[h] ?? 0),
          );
        }
        return result;

      case ChartViewMode.weekly:
        final weekday = now.weekday;
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));

        final weekInvoices = widget.invoices
            .where(
              (inv) =>
                  inv.createdAt.isAfter(
                    weekStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  inv.createdAt.isBefore(weekEnd),
            )
            .toList();

        Map<int, double> dailyData = {};
        Map<int, int> dailyCounts = {};

        for (var inv in weekInvoices) {
          final day = inv.createdAt.weekday;
          dailyData[day] = (dailyData[day] ?? 0) + inv.totalAmount;
          dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
        }

        const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
        List<RevenueChartData> weekResult = [];
        for (int d = 1; d <= 7; d++) {
          weekResult.add(
            RevenueChartData(
              dayNames[d - 1],
              dailyData[d] ?? 0,
              dailyCounts[d] ?? 0,
            ),
          );
        }
        return weekResult;

      case ChartViewMode.monthly:
        final monthStart = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);

        final monthInvoices = widget.invoices
            .where(
              (inv) =>
                  inv.createdAt.isAfter(
                    monthStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  inv.createdAt.isBefore(nextMonth),
            )
            .toList();

        Map<int, double> monthlyData = {};
        Map<int, int> monthlyCounts = {};

        for (var inv in monthInvoices) {
          final day = inv.createdAt.day;
          monthlyData[day] = (monthlyData[day] ?? 0) + inv.totalAmount;
          monthlyCounts[day] = (monthlyCounts[day] ?? 0) + 1;
        }

        List<RevenueChartData> monthResult = [];
        final maxDay = now.day;
        for (int d = 1; d <= maxDay; d++) {
          monthResult.add(
            RevenueChartData('$d', monthlyData[d] ?? 0, monthlyCounts[d] ?? 0),
          );
        }
        return monthResult;
    }
  }

  String _getTitle() {
    final now = DateTime.now();
    switch (_viewMode) {
      case ChartViewMode.daily:
        return 'Hoy ${DateFormat('dd MMM', 'es').format(now)}';
      case ChartViewMode.weekly:
        return 'Esta Semana';
      case ChartViewMode.monthly:
        return DateFormat('MMMM yyyy', 'es').format(now);
    }
  }

  String _getSubtitle() {
    final chartData = _getChartData();
    final total = chartData.fold<double>(0, (sum, item) => sum + item.revenue);
    final count = chartData.fold<int>(0, (sum, item) => sum + item.count);
    return 'L. ${NumberFormat('#,##0', 'es').format(total)} • $count facturas';
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
            child: SizedBox(
              height: 200,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                trackballBehavior: _trackballBehavior,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: AxisLine(width: 0.5, color: Colors.grey.shade200),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.blueGrey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  labelRotation: chartData.length > 12 ? -45 : 0,
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compact(locale: 'es'),
                  majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: Colors.grey.shade100,
                    dashArray: const [4, 4],
                  ),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.blueGrey[400],
                  ),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                series: <CartesianSeries>[
                  // Fast Line Series
                  FastLineSeries<RevenueChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (data, _) => data.label,
                    yValueMapper: (data, _) => data.revenue,
                    color: _primaryBlue,
                    width: 2.5,
                    animationDuration: 800,
                    enableTooltip: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryBlue, _accentBlue],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _getSubtitle(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem('D', ChartViewMode.daily),
          _buildToggleItem('S', ChartViewMode.weekly),
          _buildToggleItem('M', ChartViewMode.monthly),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, ChartViewMode mode) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_darkBlue, _primaryBlue])
              : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.blueGrey[500],
          ),
        ),
      ),
    );
  }
}

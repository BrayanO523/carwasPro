import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/balance_provider.dart';

/// Revenue Chart Widget - Uses BalanceProvider for data aggregation (MVVM Compliant)
class RevenueChart extends StatefulWidget {
  const RevenueChart({super.key});

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
      lineColor: _primaryBlue.withValues(alpha: 0.3),
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

  String _getSubtitle(List<RevenueChartData> chartData) {
    final total = chartData.fold<double>(0, (sum, item) => sum + item.revenue);
    final count = chartData.fold<int>(0, (sum, item) => sum + item.count);
    return 'L. ${NumberFormat('#,##0', 'es').format(total)} • $count facturas';
  }

  @override
  Widget build(BuildContext context) {
    // Get data from Provider (MVVM: Logic in Provider, not Widget)
    final balanceProvider = context.watch<BalanceProvider>();
    final chartData = balanceProvider.getChartData(_viewMode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(chartData),
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

  Widget _buildHeader(List<RevenueChartData> chartData) {
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
                  color: _primaryBlue.withValues(alpha: 0.25),
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
                  _getSubtitle(chartData),
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
                    color: _primaryBlue.withValues(alpha: 0.3),
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

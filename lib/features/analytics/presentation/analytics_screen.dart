import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Supply Chain Analytics & Telemetry', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Strip
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isWide ? 2.0 : 1.7,
              children: const [
                StatCard(
                  label: 'Total Consignments',
                  value: '1,248',
                  color: AppColors.textPrimary,
                  subtitle: '+12% this month',
                ),
                StatCard(
                  label: 'On-Time Logistics Rate',
                  value: '94.3%',
                  color: AppColors.success,
                  subtitle: 'Target: 92.0%',
                ),
                StatCard(
                  label: 'HMAC Authenticity',
                  value: '99.98%',
                  color: AppColors.primary,
                  subtitle: '2 tamper alarms',
                ),
                StatCard(
                  label: 'Average Transit Time',
                  value: '4.2 days',
                  color: AppColors.textSecondary,
                  subtitle: '↓ 0.4d optimized',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Charts Area
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildDeliveryPerformanceChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildConsignmentStatusPie()),
                ],
              )
            else ...[
              _buildDeliveryPerformanceChart(),
              const SizedBox(height: 16),
              _buildConsignmentStatusPie(),
            ],

            const SizedBox(height: 20),

            // Performance breakdown
            _buildSupplierScorecards(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPerformanceChart() {
    final spots = [
      const FlSpot(1, 91.2),
      const FlSpot(2, 93.4),
      const FlSpot(3, 89.8),
      const FlSpot(4, 94.3),
      const FlSpot(5, 92.1),
      const FlSpot(6, 95.0),
      const FlSpot(7, 94.3),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('On-Time Delivery Trend (% by week)', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('W1 - W7 (Aug 2026)', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.cardBorder, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 34,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const w = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'];
                        final i = v.toInt() - 1;
                        if (i < 0 || i >= w.length) return const SizedBox();
                        return Text(w[i], style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 80,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: AppColors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsignmentStatusPie() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consignment Distribution', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  PieChartSectionData(value: 48, color: AppColors.success, title: '48%', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), radius: 36),
                  PieChartSectionData(value: 28, color: AppColors.primary, title: '28%', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), radius: 36),
                  PieChartSectionData(value: 18, color: AppColors.warning, title: '18%', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), radius: 36),
                  PieChartSectionData(value: 6, color: AppColors.danger, title: '6%', titleStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), radius: 36),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _legendItem(AppColors.success, 'Delivered to Retail (48%)'),
          _legendItem(AppColors.primary, 'In Transit / Logistics (28%)'),
          _legendItem(AppColors.warning, 'Warehouse Staging (18%)'),
          _legendItem(AppColors.danger, 'Exceptions / Delayed (6%)'),
        ],
      ),
    );
  }

  Widget _legendItem(Color c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSupplierScorecards() {
    final suppliers = [
      ('Guwahati Food Corp', '98.4%', '4.9/5.0', 'Optimal', AppColors.success),
      ('Siliguri Logistics Hub', '91.2%', '4.2/5.0', 'At Risk (Monsoon)', AppColors.warning),
      ('Kolkata Central Warehouse', '99.1%', '4.9/5.0', 'Optimal', AppColors.success),
      ('Metro Retailers Network', '95.6%', '4.6/5.0', 'Nominal', AppColors.primary),
    ];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('PARTNER NODE', style: _thStyle())),
                Expanded(flex: 2, child: Text('ON-TIME', style: _thStyle())),
                Expanded(flex: 2, child: Text('RATING', style: _thStyle())),
                Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.right, style: _thStyle())),
              ],
            ),
          ),
          ...suppliers.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cardBorder))),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(s.$1, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
                    Expanded(flex: 2, child: Text(s.$2, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12))),
                    Expanded(flex: 2, child: Text(s.$3, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12))),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SeverityBadge(severity: s.$4, small: true),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  TextStyle _thStyle() => GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5);
}

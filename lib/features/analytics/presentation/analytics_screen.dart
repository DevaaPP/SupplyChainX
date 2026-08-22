import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Analytics Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Aug 2026',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top KPI cards
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.6 : 1.4,
              children: const [
                StatCard(
                  label: 'Total Products',
                  value: '1,248',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.primary,
                  subtitle: '+12% this month',
                ),
                StatCard(
                  label: 'Deliveries On-Time',
                  value: '94.3%',
                  icon: Icons.local_shipping_rounded,
                  color: AppColors.low,
                  subtitle: '↑ 2.1% vs last month',
                ),
                StatCard(
                  label: 'QR Verifications',
                  value: '3,892',
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.secondary,
                  subtitle: '99.7% authentic',
                ),
                StatCard(
                  label: 'Avg Delivery Days',
                  value: '4.2',
                  icon: Icons.schedule_rounded,
                  color: AppColors.medium,
                  subtitle: '↓ 0.8 days improved',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts row
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildDeliveryChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildStatusPieChart()),
                ],
              )
            else ...[
              _buildDeliveryChart(),
              const SizedBox(height: 16),
              _buildStatusPieChart(),
            ],
            const SizedBox(height: 20),

            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildInventoryBar()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSupplierRatings()),
                ],
              )
            else ...[
              _buildInventoryBar(),
              const SizedBox(height: 16),
              _buildSupplierRatings(),
            ],
            const SizedBox(height: 20),

            // Regional demand
            _buildRegionalDemand(),
            const SizedBox(height: 20),

            // Recent activity table
            _buildActivityTable(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryChart() {
    final spots = [
      const FlSpot(1, 88),
      const FlSpot(2, 91),
      const FlSpot(3, 87),
      const FlSpot(4, 93),
      const FlSpot(5, 90),
      const FlSpot(6, 95),
      const FlSpot(7, 94),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Delivery Performance'),
          const SizedBox(height: 4),
          const Text('On-time delivery % — last 7 weeks',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.cardBorder, strokeWidth: 1),
                  getDrawingVerticalLine: (_) => const FlLine(
                      color: Colors.transparent),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('${v.round()}%',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const weeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'];
                        final i = v.round() - 1;
                        if (i < 0 || i >= weeks.length) return const SizedBox();
                        return Text(weeks[i],
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 80,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeColor: AppColors.background,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Product Status'),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                      value: 45,
                      color: AppColors.low,
                      title: '45%',
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                      radius: 50),
                  PieChartSectionData(
                      value: 28,
                      color: AppColors.primary,
                      title: '28%',
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                      radius: 50),
                  PieChartSectionData(
                      value: 18,
                      color: AppColors.medium,
                      title: '18%',
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                      radius: 50),
                  PieChartSectionData(
                      value: 9,
                      color: AppColors.high,
                      title: '9%',
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                      radius: 50),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _legend(AppColors.low, 'Delivered (45%)'),
          _legend(AppColors.primary, 'In Transit (28%)'),
          _legend(AppColors.medium, 'At Warehouse (18%)'),
          _legend(AppColors.high, 'Delayed (9%)'),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );

  Widget _buildInventoryBar() {
    final data = [
      ('Rice', 248.0, 300.0),
      ('Tea', 87.0, 200.0),
      ('Pickle', 312.0, 350.0),
      ('Spices', 45.0, 200.0),
      ('Oil', 180.0, 250.0),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Inventory Levels'),
          const SizedBox(height: 4),
          const Text('Current stock vs capacity',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 16),
          ...data.map((d) {
            final ratio = d.$2 / d.$3;
            final color = ratio < 0.3
                ? AppColors.critical
                : ratio < 0.5
                    ? AppColors.medium
                    : AppColors.low;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(d.$1,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                      Text(
                          '${d.$2.round()} / ${d.$3.round()} units',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.surfaceElevated,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSupplierRatings() {
    final suppliers = [
      ('XYZ Manufacturing', 4.9, 98),
      ('Fast Distributors', 4.2, 91),
      ('Central Warehouse', 4.8, 99),
      ('Metro Retailers', 4.5, 95),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Supplier Ratings'),
          const SizedBox(height: 16),
          ...suppliers.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryDim,
                      child: Text(s.$1[0],
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              ...List.generate(
                                  5,
                                  (i) => Icon(
                                      i < s.$2.round()
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: AppColors.medium,
                                      size: 12)),
                              const SizedBox(width: 4),
                              Text('${s.$2}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lowDim,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${s.$3}%',
                          style: const TextStyle(
                              color: AppColors.low,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRegionalDemand() {
    final regions = [
      ('Northeast India', 38),
      ('West Bengal', 27),
      ('Maharashtra', 19),
      ('Karnataka', 11),
      ('Others', 5),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Regional Demand Distribution'),
          const SizedBox(height: 16),
          ...regions.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                        width: 130,
                        child: Text(r.$1,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.$2 / 100,
                          backgroundColor: AppColors.surfaceElevated,
                          color: AppColors.secondary,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 36,
                      child: Text('${r.$2}%',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActivityTable() {
    final rows = [
      ['SCX-00134', 'Mango Pickle 500ml', 'Manufacturer', 'Registered', '3h ago'],
      ['SCX-00098', 'Darjeeling Tea 250g', 'Distributor', 'In Transit', '2d ago'],
      ['SCX-00112', 'Organic Rice 5kg', 'Retailer', 'Delivered', '3d ago'],
      ['SCX-00091', 'Mustard Oil 1L', 'Warehouse', 'Stored', '5d ago'],
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recent Activity'),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1),
            },
            children: [
              const TableRow(
                children: [
                  _TableHeader('Product ID'),
                  _TableHeader('Name'),
                  _TableHeader('Stage'),
                  _TableHeader('Status'),
                  _TableHeader('Time'),
                ],
              ),
              ...rows.map((r) => TableRow(
                    decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppColors.cardBorder))),
                    children: [
                      _TableCell(r[0], mono: true),
                      _TableCell(r[1]),
                      _TableCell(r[2]),
                      _TableCell(r[3], badge: true),
                      _TableCell(r[4], muted: true),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool mono;
  final bool badge;
  final bool muted;

  const _TableCell(this.text, {this.mono = false, this.badge = false, this.muted = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: badge
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(text,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)))
            : Text(text,
                style: TextStyle(
                    color: muted ? AppColors.textMuted : AppColors.textPrimary,
                    fontSize: 12,
                    fontFamily: mono ? 'monospace' : null)),
      );
}

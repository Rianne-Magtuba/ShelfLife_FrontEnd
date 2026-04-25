import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────

class _StatData {
  static const int totalAdded = 142;
  static const int totalExpired = 23;
  static const int wasteSaved = 119;
  static const double estimatedWasteCost = 47.80; // PHP or USD, locale-based
  static const double consumedRatio = 0.84; // 84% consumed vs wasted

  static const List<_CategoryStat> categoryBreakdown = [
    _CategoryStat('Fridge', 45, AppColors.mediumBlue),
    _CategoryStat('Pantry', 25, Color(0xFF6B4A2B)),
    _CategoryStat('Freezer', 20, AppColors.lightBlue),
    _CategoryStat('Others', 10, Color(0xFFB0BEC5)),
  ];

  static const List<_WeeklyExpiry> weeklyExpiry = [
    _WeeklyExpiry('Mon', 2),
    _WeeklyExpiry('Tue', 5),
    _WeeklyExpiry('Wed', 3),
    _WeeklyExpiry('Thu', 8),
    _WeeklyExpiry('Fri', 28),
    _WeeklyExpiry('Sat', 11),
    _WeeklyExpiry('Sun', 4),
  ];

  static const List<_CategoryStat> wastedByCategory = [
    _CategoryStat('Fridge', 8, AppColors.mediumBlue),
    _CategoryStat('Pantry', 3, Color(0xFF6B4A2B)),
    _CategoryStat('Freezer', 2, AppColors.lightBlue),
    _CategoryStat('Others', 1, Color(0xFFB0BEC5)),
  ];
}

class _CategoryStat {
  final String label;
  final int count;
  final Color color;
  const _CategoryStat(this.label, this.count, this.color);
}

class _WeeklyExpiry {
  final String day;
  final int count;
  const _WeeklyExpiry(this.day, this.count);
}

// ─── Statistics Page ──────────────────────────────────────────────────────────

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int? _touchedDonutIndex;
  int? _touchedWastedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const StatisticsHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildSummaryRow(),
                    const SizedBox(height: 20),
                    _buildConsumedRatioCard(),
                    const SizedBox(height: 20),
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 20),
                    _buildExpiryTimeline(),
                    const SizedBox(height: 20),
                    _buildMostWastedCategory(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary metric cards ──

  Widget _buildSummaryRow() {
    return const Row(
      children: [
        _MetricCard(
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.mediumBlue,
          value: '${_StatData.totalAdded}',
          label: 'Items Added',
        ),
        SizedBox(width: 10),
        _MetricCard(
          icon: Icons.trending_down,
          iconColor: AppColors.expired,
          value: '${_StatData.totalExpired}',
          label: 'Expired',
        ),
        SizedBox(width: 10),
        _MetricCard(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.fresh,
          value: '${_StatData.wasteSaved}',
          label: 'Waste Saved',
        ),
      ],
    );
  }

  // ── Consumed vs wasted ratio ──

  Widget _buildConsumedRatioCard() {
    final consumed = (_StatData.consumedRatio * 100).toStringAsFixed(0);
    final wasted = ((1 - _StatData.consumedRatio) * 100).toStringAsFixed(0);
    return _SectionCard(
      title: 'Consumed vs Wasted',
      icon: Icons.pie_chart_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: AppColors.fresh, label: 'Consumed: $consumed%'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.expired, label: 'Wasted: $wasted%'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (_StatData.consumedRatio * 100).round(),
                  child: Container(height: 18, color: AppColors.fresh),
                ),
                Expanded(
                  flex: 100 - (_StatData.consumedRatio * 100).round(),
                  child: Container(height: 18, color: AppColors.expired),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated waste cost: \$${_StatData.estimatedWasteCost.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Category donut ──

  Widget _buildCategoryBreakdown() {
    final total = _StatData.categoryBreakdown.fold(0, (s, e) => s + e.count);
    return _SectionCard(
      title: 'Storage Category Breakdown',
      icon: Icons.bar_chart,
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (ev, resp) {
                        setState(() {
                          if (!ev.isInterestedForInteractions ||
                              resp == null ||
                              resp.touchedSection == null) {
                            _touchedDonutIndex = -1;
                            return;
                          }
                          _touchedDonutIndex =
                              resp.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    sections:
                        List.generate(_StatData.categoryBreakdown.length, (i) {
                      final cat = _StatData.categoryBreakdown[i];
                      final isTouched = i == _touchedDonutIndex;
                      final pct = (cat.count / total * 100);
                      return PieChartSectionData(
                        color: cat.color,
                        value: cat.count.toDouble(),
                        title: isTouched ? '' : '${pct.toStringAsFixed(0)}%',
                        radius: isTouched ? 65 : 55,
                        titleStyle: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        badgeWidget: isTouched
                            ? _DonutBadge(label: cat.label, count: cat.count)
                            : null,
                        badgePositionPercentageOffset: 1.3,
                      );
                    }),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$total',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('items',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _StatData.categoryBreakdown
                .map((c) =>
                    _LegendDot(color: c.color, label: '${c.label}: ${c.count}'))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Expiry timeline bar chart ──

  Widget _buildExpiryTimeline() {
    final maxVal = _StatData.weeklyExpiry
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return _SectionCard(
      title: 'Expiry Timeline',
      icon: Icons.timeline,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxVal + 5,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final day = _StatData.weeklyExpiry[groupIndex].day;
                  return BarTooltipItem(
                    '$day\n${rod.toY.toInt()} items',
                    GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final i = val.toInt();
                    if (i >= _StatData.weeklyExpiry.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_StatData.weeklyExpiry[i].day,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textSecondary)),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (val, meta) => Text(
                    val.toInt().toString(),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (val) => const FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
              ),
            ),
            barGroups: List.generate(_StatData.weeklyExpiry.length, (i) {
              final item = _StatData.weeklyExpiry[i];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: item.count.toDouble(),
                    color: AppColors.mediumBlue,
                    width: 22,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Most wasted category ──

  Widget _buildMostWastedCategory() {
    final total = _StatData.wastedByCategory.fold(0, (s, e) => s + e.count);
    final sorted = [..._StatData.wastedByCategory]
      ..sort((a, b) => b.count.compareTo(a.count));

    return _SectionCard(
      title: 'Most Wasted Category',
      icon: Icons.warning_amber_outlined,
      child: Column(
        children: sorted.map((cat) {
          final frac = total > 0 ? cat.count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(cat.label,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 10,
                          backgroundColor: AppColors.divider,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${cat.count} expired',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.mediumBlue.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.mediumBlue.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.mediumBlue, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DonutBadge extends StatelessWidget {
  final String label;
  final int count;
  const _DonutBadge({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label\n$count',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class StatisticsHeader extends StatelessWidget {
  const StatisticsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkBlue, AppColors.mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding:
          EdgeInsets.only(top: topPad + 12, left: 8, right: 20, bottom: 20),
      child: Row(
        children: [
          // FIX: Back button — context.pop() works because we pushed via
          // context.push() from the profile page.
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(
              'Statistics & Insights',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

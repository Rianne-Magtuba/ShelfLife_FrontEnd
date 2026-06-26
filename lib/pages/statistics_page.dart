import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../core/business/providers/inventory_provider.dart';
import '../core/business/services/analytics_service.dart';

const _categoryColors = {
  'Fridge':  AppColors.mediumBlue,
  'Pantry':  Color(0xFF6B4A2B),
  'Freezer': AppColors.lightBlue,
  'Others':  Color(0xFFB0BEC5),
};

Color _colorFor(String label) =>
    _categoryColors[label] ?? AppColors.mediumBlue;

// ─── Statistics Page ──────────────────────────────────────────────────────────

class StatisticsPage extends ConsumerStatefulWidget  {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  int? _touchedDonutIndex;
  int? _touchedWastedIndex;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(analyticsProvider);

    // ── Loading ─────────────────────────────────────────────────────────
    if (asyncData.isLoading) {
      return AppBackground(
        child: Column(
          children: [
            const StatisticsHeader(),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.mediumBlue),
              ),
            ),
          ],
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────
    if (asyncData.hasError) {
      return AppBackground(
        child: Column(
          children: [
            const StatisticsHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 52, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load statistics',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check your connection and try again.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Data ─────────────────────────────────────────────────────────────
    final data = asyncData.value!;

    if (data.isEmpty) {
      return AppBackground(
        child: Column(
          children: [
            const StatisticsHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bar_chart,
                        size: 72, color: AppColors.lightBlue),
                    const SizedBox(height: 16),
                    Text('Not enough data yet',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Add items to your pantry to see insights.',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Normal content ────────────────────────────────────────────────────
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
                    _buildSummaryRow(data),
                    const SizedBox(height: 20),
                    _buildConsumedRatioCard(data),
                    const SizedBox(height: 20),
                    _buildCategoryBreakdown(data),
                    const SizedBox(height: 20),
                    _buildExpiryTimeline(data),
                    const SizedBox(height: 20),
                    _buildMostWastedCategory(data),
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

  Widget _buildSummaryRow(AnalyticsResult data) {
    return Row(
      children: [
        _MetricCard(
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.mediumBlue,
          value: '${data.totalAdded}',
          label: 'Items Added',
        ),
        const SizedBox(width: 10),
        _MetricCard(
          icon: Icons.trending_down,
          iconColor: AppColors.expired,
          value: '${data.totalExpired}',
          label: 'Expired',
        ),
        const SizedBox(width: 10),
        _MetricCard(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.fresh,
          value: '${data.totalConsumed}',
          label: 'Consumed',
        ),
      ],
    );
  }

  // ── Consumed vs wasted ratio ──

  Widget _buildConsumedRatioCard(AnalyticsResult data) {
    final hasActions =
        data.totalConsumed + data.totalDiscarded > 0;

    final consumedPct =
    hasActions
        ? (data.consumedRatio * 100).toStringAsFixed(0)
        : '0';

    final wastedPct =
    hasActions
        ? ((1 - data.consumedRatio) * 100).toStringAsFixed(0)
        : '0';

    final consumedFlex =
    hasActions
        ? (data.consumedRatio * 100).round().clamp(1, 99)
        : 50;

    return _SectionCard(
      title: 'Consumed vs Expired',
      icon: Icons.pie_chart_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(
                  color: AppColors.fresh,
                  label: 'Consumed: $consumedPct%'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.expired,
                  label: 'Expired: $wastedPct%'),
            ],
          ),
          const SizedBox(height: 12),
          if (hasActions)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    flex: consumedFlex,
                    child: Container(
                      height: 18,
                      color: AppColors.fresh,
                    ),
                  ),
                  Expanded(
                    flex: 100 - consumedFlex,
                    child: Container(
                      height: 18,
                      color: AppColors.expired,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Estimated waste cost: ₱${data.estimatedWasteCost.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Category donut ──

  Widget _buildCategoryBreakdown(AnalyticsResult data) {
    final entries = data.categoryBreakdown.entries.toList();
    final total   = entries.fold(0, (s, e) => s + e.value);

    if (entries.isEmpty) {
      return _SectionCard(
        title: 'Storage Category Breakdown',
        icon: Icons.bar_chart,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No data yet',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

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
                    sections: List.generate(entries.length, (i) {
                      final entry     = entries[i];
                      final isTouched = i == _touchedDonutIndex;
                      final pct       = entry.value / total * 100;
                      return PieChartSectionData(
                        color: _colorFor(entry.key),
                        value: entry.value.toDouble(),
                        title: isTouched ? '' : '${pct.toStringAsFixed(0)}%',
                        radius: isTouched ? 65 : 55,
                        titleStyle: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        badgeWidget: isTouched
                            ? _DonutBadge(
                            label: entry.key, count: entry.value)
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
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries
                .map((e) => _LegendDot(
              color: _colorFor(e.key),
              label: '${e.key}: ${e.value}',
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
  // ── Expiry timeline bar chart ──

  Widget _buildExpiryTimeline(AnalyticsResult data) {
    final entries = data.expiryByDay;

    final maxVal = entries.isEmpty
        ? 5.0
        : entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return _SectionCard(
      title: 'Consumed Timeline (Last 7 Days)',
      icon: Icons.timeline,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxVal + 2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final label = AnalyticsService
                      .dayKeyToLabel(entries[groupIndex].key);
                  return BarTooltipItem(
                    '$label\n${rod.toY.toInt()} items',
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
                    if (i >= entries.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AnalyticsService.dayKeyToLabel(entries[i].key),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
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
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (val) => const FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
              ),
            ),
            barGroups: List.generate(entries.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value.toDouble(),
                    color: AppColors.mediumBlue,
                    width: 22,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
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

  Widget _buildMostWastedCategory(AnalyticsResult data) {
    final entries = data.wastedByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0, (s, e) => s + e.value);

    if (entries.isEmpty) {
      return _SectionCard(
        title: 'Most Expired Category',
        icon: Icons.warning_amber_outlined,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No expired items — great job!',
              style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ),
      );
    }

    return _SectionCard(
      title: 'Most Expired Category',
      icon: Icons.warning_amber_outlined,
      child: Column(
        children: entries.map((entry) {
          final frac = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(entry.key,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 10,
                      backgroundColor: AppColors.divider,
                      color: _colorFor(entry.key),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entry.value} expired',
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

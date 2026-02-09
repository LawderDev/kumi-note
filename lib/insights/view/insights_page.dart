import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kumi_app/core/theme/kumi_colors.dart';
import 'package:kumi_app/core/theme/kumi_text_styles.dart';
import 'package:kumi_app/core/widgets/kumi_card.dart';
import 'package:kumi_app/insights/cubit/insights_cubit.dart';
import 'package:kumi_app/insights/cubit/insights_state.dart';
import 'package:kumi_repository/kumi_repository.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Insights page showing analytics and statistics about notes
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InsightsCubit(
        repository: context.read<KumiRepository>(),
      )..loadStats(),
      child: Scaffold(
        backgroundColor: KumiColors.creamBackground,
        appBar: AppBar(
          title: Text('Insights', style: KumiTextStyles.headlineM),
          backgroundColor: KumiColors.creamBackground,
          elevation: 0,
          centerTitle: false,
        ),
        body: BlocBuilder<InsightsCubit, InsightsState>(
          builder: (context, state) {
            if (state is InsightsLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: KumiColors.orangeAccent,
                ),
              );
            }

            if (state is InsightsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      size: 48,
                      color: KumiColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${state.message}',
                      style: KumiTextStyles.bodyL,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<InsightsCubit>().loadStats(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KumiColors.orangeAccent,
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            if (state is InsightsLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: LucideIcons.bookOpen,
                            label: 'Total Notes',
                            value: '${state.totalNotes}',
                            color: KumiColors.orangeAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: LucideIcons.calendar,
                            label: 'Moyenne/jour',
                            value: state.avgNotesPerDay.toStringAsFixed(1),
                            color: KumiColors.sageGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date range card
                    if (state.oldestNote != null && state.newestNote != null)
                      KumiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 20,
                                  color: KumiColors.info,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Période',
                                  style: KumiTextStyles.bodyM.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Première note',
                                      style: KumiTextStyles.caption,
                                    ),
                                    Text(
                                      DateFormat.MMMd(
                                        'fr_FR',
                                      ).format(state.oldestNote!),
                                      style: KumiTextStyles.bodyM.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Dernière note',
                                      style: KumiTextStyles.caption,
                                    ),
                                    Text(
                                      DateFormat.MMMd(
                                        'fr_FR',
                                      ).format(state.newestNote!),
                                      style: KumiTextStyles.bodyM.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Chart section
                    Text(
                      '7 derniers jours',
                      style: KumiTextStyles.headlineS,
                    ),
                    const SizedBox(height: 16),

                    KumiCard(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 200,
                        child: _buildChart(state.notesLast7Days),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tips card
                    KumiCard(
                      color: KumiColors.sageGreen.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            color: KumiColors.sageGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Plus tu écris de notes, meilleure sera la mémoire de Kumi! 🐕',
                              style: KumiTextStyles.bodyM.copyWith(
                                color: KumiColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildChart(Map<DateTime, int> notesLast7Days) {
    final sortedEntries = notesLast7Days.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Handle empty data
    if (sortedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.barChart3,
              size: 48,
              color: KumiColors.warmGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Pas encore de données',
              style: KumiTextStyles.bodyM.copyWith(
                color: KumiColors.warmGray,
              ),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value.toDouble()));
    }

    final maxY = sortedEntries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: KumiColors.warmGray.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length) {
                  final date = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat.E(
                        'fr_FR',
                      ).format(date).substring(0, 1).toUpperCase(),
                      style: KumiTextStyles.caption,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: maxY > 0 ? (maxY / 3).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: KumiTextStyles.caption,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedEntries.length - 1).toDouble(),
        minY: 0,
        maxY: maxY > 0 ? maxY + 1 : 3,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: KumiColors.orangeAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: KumiColors.orangeAccent,
                  strokeWidth: 2,
                  strokeColor: KumiColors.creamBackground,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: KumiColors.orangeAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return KumiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: KumiTextStyles.headlineM.copyWith(color: color),
          ),
          Text(
            label,
            style: KumiTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

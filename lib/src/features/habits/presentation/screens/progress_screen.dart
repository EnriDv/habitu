import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/entities/habit_template_models.dart';
import '../notifiers/progress_hub_notifier.dart';
import 'recommendations_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressHubNotifier>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProgressHubNotifier>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Progreso',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Métricas'),
              Tab(text: 'Sugerencias'),
            ],
          ),
        ),
        body: notifier.isLoading && notifier.analytics == null
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : Column(
                children: [
                  if (notifier.errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        notifier.errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _MetricsTab(analytics: notifier.analytics),
                        _RecommendationsTab(recommendations: notifier.recommendations),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetricsTab extends StatelessWidget {
  final AnalyticsSummary? analytics;

  const _MetricsTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return const Center(
        child: Text('Sin métricas disponibles todavía.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ProgressHubNotifier>().refreshAnalytics(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          _MetricHeroCard(analytics: analytics!),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricMiniCard(
                  label: 'Últimos 7 días',
                  value: '${analytics!.totalCompletedLast7Days}',
                  caption: '${(analytics!.weeklySuccessRate * 100).round()}% de cumplimiento',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricMiniCard(
                  label: 'Últimos 30 días',
                  value: '${analytics!.totalCompletedLast30Days}',
                  caption: '${(analytics!.monthlySuccessRate * 100).round()}% mensual',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Ritmo',
            subtitle: 'Dónde se está moviendo mejor tu constancia.',
          ),
          const SizedBox(height: 12),
          _InfoStrip(
            icon: Icons.calendar_today_outlined,
            title: 'Día más fuerte',
            value: analytics!.mostProductiveWeekday,
          ),
          const SizedBox(height: 10),
          _InfoStrip(
            icon: Icons.schedule_outlined,
            title: 'Franja más activa',
            value: analytics!.bestCompletionWindow,
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Mapa de consistencia',
            subtitle: 'Últimos 120 días de actividad.',
          ),
          const SizedBox(height: 12),
          _HeatmapCard(points: analytics!.heatmap),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Hábitos fuertes',
            subtitle: 'Los que más empujan tu progreso.',
          ),
          const SizedBox(height: 12),
          ...analytics!.topHabits.map(_HabitStatTile.new),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Necesitan atención',
            subtitle: 'Los que más se están enfriando.',
          ),
          const SizedBox(height: 12),
          ...analytics!.needsAttentionHabits.map(_HabitStatTile.new),
        ],
      ),
    );
  }
}

class _RecommendationsTab extends StatelessWidget {
  final List<HabitRecommendation> recommendations;

  const _RecommendationsTab({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          _EmptyPanel(
            title: 'Todavía no hay sugerencias',
            subtitle: 'Mientras tanto puedes seguir creando hábitos manualmente desde Hoy.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: recommendations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecommendationsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        recommendation.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation.description,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Text(
                  recommendation.reason,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricHeroCard extends StatelessWidget {
  final AnalyticsSummary analytics;

  const _MetricHeroCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.18),
            AppTheme.surfaceContainerHighest.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pulso actual',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${analytics.maxActiveStreak} días',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            analytics.maxActiveStreak == 0
                ? 'Todavía no hay racha activa. El foco es retomar hoy.'
                : 'Tu mejor racha activa sigue viva. Mantén el ritmo.',
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const _MetricMiniCard({
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoStrip({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  final List<AnalyticsHeatmapPoint> points;

  const _HeatmapCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: points.map((point) {
          Color color;
          if (point.count == 0) {
            color = Colors.white.withOpacity(0.06);
          } else if (point.count == 1) {
            color = AppTheme.primaryColor.withOpacity(0.35);
          } else if (point.count == 2) {
            color = AppTheme.primaryColor.withOpacity(0.6);
          } else {
            color = AppTheme.primaryColor;
          }

          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HabitStatTile extends StatelessWidget {
  final AnalyticsHabitStat stat;

  const _HabitStatTile(this.stat);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 40,
            decoration: BoxDecoration(
              color: Color(int.parse(stat.colorHex.replaceAll('#', '0xFF'))),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${stat.completions} completados · racha ${stat.currentStreak}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            'Máx ${stat.longestStreak}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

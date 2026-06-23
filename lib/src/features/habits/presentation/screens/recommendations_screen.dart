import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../notifiers/progress_hub_notifier.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressHubNotifier>().loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProgressHubNotifier>();
    final recommendations = notifier.recommendations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerencias'),
      ),
      body: recommendations.isEmpty
          ? const Center(
              child: Text(
                'No hay recomendaciones disponibles todavía.',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                );
              },
            ),
    );
  }
}

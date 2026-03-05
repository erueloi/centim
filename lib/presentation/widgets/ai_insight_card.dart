import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/ai_coach_provider.dart';
import 'package:shimmer/shimmer.dart';

class AiInsightCard extends ConsumerWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiCoachProvider);

    if (!aiState.isVisible) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ActionChip(
            avatar: const Icon(Icons.auto_awesome,
                color: AppTheme.copper, size: 18),
            label: const Text(
              'Què diu el Coach?',
              style: TextStyle(
                color: AppTheme.anthracite,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.copper.withAlpha(25),
            side: BorderSide(
              color: AppTheme.copper.withAlpha(76),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () {
              ref.read(aiCoachProvider.notifier).refresh();
            },
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.copper.withValues(alpha: 0.05),
              AppTheme.sand.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppTheme.copper.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.copper.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded, // Robot icon
                      color: AppTheme.copper,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "L'opinió de Cèntim",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.anthracite,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      ref.read(aiCoachProvider.notifier).dismiss();
                    },
                    tooltip: 'Tancar consell',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (aiState.isLoading)
                _buildShimmer()
              else if (aiState.error != null)
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                )
              else if (aiState.insight != null)
                Text(
                  aiState.insight!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppTheme.anthracite,
                  ),
                )
              else
                const Text(
                  "No hi ha cap consell disponible actualment.",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 14.0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8.0),
          ),
          Container(
            width: double.infinity,
            height: 14.0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8.0),
          ),
          Container(
            width: 200.0,
            height: 14.0,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

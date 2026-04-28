import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:centim/l10n/app_localizations.dart';
import '../screens/dashboard/coach_chat_screen.dart';

class AiInsightCard extends ConsumerWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ActionChip(
          avatar: const Icon(Icons.smart_toy_rounded,
              color: AppTheme.copper, size: 18),
          label: Text(
            l10n.coachAskButton,
            style: const TextStyle(
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
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const Center(child: CoachChatSheet()),
            );
          },
        ),
      ),
    );
  }
}

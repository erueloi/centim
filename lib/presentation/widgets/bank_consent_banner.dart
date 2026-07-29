import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/services/bank_consent_service.dart';
import '../../domain/services/bank_sync_service.dart';
import '../providers/bank_consent_provider.dart';

class BankConsentBanner extends ConsumerStatefulWidget {
  const BankConsentBanner({super.key});

  @override
  ConsumerState<BankConsentBanner> createState() => _BankConsentBannerState();
}

class _BankConsentBannerState extends ConsumerState<BankConsentBanner> {
  bool _starting = false;

  Future<void> _reconnect() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'De moment la reconnexió bancària s’ha de fer des de la versió web.',
          ),
        ),
      );
      return;
    }
    setState(() => _starting = true);
    try {
      final start = await ref.read(bankSyncServiceProvider).startAuth(
            redirectUrl: '${Uri.base.origin}/bank-callback',
          );
      await launchUrl(Uri.parse(start.authUrl), webOnlyWindowName: '_self');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No s’ha pogut reconnectar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(bankConsentStatusProvider).valueOrNull;
    if (status == null || !status.needsAttention) {
      return const SizedBox.shrink();
    }
    final expired = status.state == BankConsentState.expired;
    final color = expired ? Colors.red : Colors.orange;
    final until = status.validUntil?.toLocal();
    final date = until == null ? '' : DateFormat('dd/MM/yyyy').format(until);
    final text = expired
        ? 'L’accés al banc ha caducat. Cal reconnectar.'
        : 'L’accés al banc caduca en ${status.daysRemaining} '
            'dia${status.daysRemaining == 1 ? '' : 's'} ($date).';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.key_off_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _starting ? null : _reconnect,
            child: _starting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reconnecta'),
          ),
        ],
      ),
    );
  }
}

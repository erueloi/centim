import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/annual_report.dart';
import '../../domain/services/annual_report_service.dart';
import 'transaction_notifier.dart';
import 'category_notifier.dart';
import 'billing_cycle_provider.dart';
import 'debt_provider.dart';

part 'annual_view_provider.g.dart';

enum AnnualDisplayMode { real, projected }

@riverpod
class AnnualDisplayModeNotifier extends _$AnnualDisplayModeNotifier {
  static const _prefKey = 'annual_display_mode';

  @override
  AnnualDisplayMode build() {
    _loadPreference();
    return AnnualDisplayMode.real;
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = SharedPreferencesAsync();
      final saved = await prefs.getString(_prefKey);
      if (saved == 'projected') {
        state = AnnualDisplayMode.projected;
      } else if (saved == 'real') {
        state = AnnualDisplayMode.real;
      }
    } catch (_) {
      // Fallback segur a mode Real
    }
  }

  Future<void> setMode(AnnualDisplayMode mode) async {
    state = mode;
    try {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }
}

@riverpod
class AnnualSelectedYearNotifier extends _$AnnualSelectedYearNotifier {
  @override
  int build() {
    return DateTime.now().year;
  }

  void setYear(int year) {
    state = year;
  }

  void nextYear() {
    state = state + 1;
  }

  void previousYear() {
    state = state - 1;
  }
}

@riverpod
class AnnualReportNotifier extends _$AnnualReportNotifier {
  @override
  Future<AnnualReportData> build() async {
    final year = ref.watch(annualSelectedYearNotifierProvider);
    final transactions = await ref.watch(transactionNotifierProvider.future);
    final categories = await ref.watch(categoryNotifierProvider.future);
    final cycles = await ref.watch(billingCycleNotifierProvider.future);
    final debts = await ref.watch(debtNotifierProvider.future);

    return AnnualReportService.calculateAnnualReport(
      targetYear: year,
      transactions: transactions,
      categories: categories,
      cycles: cycles,
      debts: debts,
      currentDate: DateTime.now(),
    );
  }
}

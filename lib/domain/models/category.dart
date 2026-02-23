import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

enum TransactionType { expense, income }

@Freezed(toJson: true, fromJson: true)
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon, // Emoji or IconData string
    @Default([]) List<SubCategory> subcategories,
    @Default(TransactionType.expense) TransactionType type,
    int? order,
    int? color, // Color value as int (0xAARRGGBB)
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

enum PaymentTiming { specificDay, firstBusinessDay, lastBusinessDay }

@freezed
class SubCategory with _$SubCategory {
  const factory SubCategory({
    required String id,
    required String name,
    required double monthlyBudget,
    @Default(false) bool isFixed,
    @Default(false) bool isWatched,
    String? defaultPayerId, // Who usually pays this
    int? paymentDay, // Day of month (1-31) for fixed expenses
    @Default(PaymentTiming.specificDay) PaymentTiming paymentTiming,
    String?
        linkedSavingsGoalId, // ID of the savings goal to contribute to automatically
    String? linkedDebtId, // ID of the debt to auto-pay via transfer
  }) = _SubCategory;

  factory SubCategory.fromJson(Map<String, dynamic> json) =>
      _$SubCategoryFromJson(json);
}

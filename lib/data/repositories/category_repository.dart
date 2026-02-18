import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Category>> getCategoriesStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('categories')
        .snapshots() // Remove orderBy to include docs without 'order' field
        .map((snapshot) {
          final categories = snapshot.docs
              .map((doc) => Category.fromJson(doc.data()))
              .toList();

          // Client-side sort: existing orders first, nulls last (or by name/date)
          categories.sort((a, b) {
            if (a.order != null && b.order != null) {
              return a.order!.compareTo(b.order!);
            }
            if (a.order != null) {
              return -1; // a has order, b doesn't -> a comes first
            }
            if (b.order != null) {
              return 1; // b has order, a doesn't -> b comes first
            }
            return a.name.compareTo(b.name); // Fallback to name
          });

          return categories;
        });
  }

  Future<void> addCategory(String groupId, Category category) async {
    final data = category.toJson();
    // Ensure subcategories are properly serialized as maps
    data['subcategories'] = category.subcategories
        .map((s) => s.toJson())
        .toList();

    // If order is not set, set it to a high value so it appears at the end.
    // However, to respect the separation between Expense (0+) and Income (10000+),
    // we should ideally query the max order for the type.
    // For simplicity, we use:
    // Expense: current timestamp (which is large, so it goes to end of expense block? No, it mixes with Income if we use timestamp)
    // Actually, timestamp is 17xxxxxxxxxxx.
    // If we use 0-N for Expenses and 10000-N for Income, we need to be careful.
    // Let's change the strategy:
    // Expenses: 0 - 9999
    // Income: 10000+
    // If we use timestamp, it breaks this.
    // So for new categories, we should probably fetch the count or max order.
    // But for a quick solution that doesn't require extra read:
    // We can use a large number base for Income.
    // Expense: DateTime.now().millisecondsSinceEpoch (13 digits)
    // Income: DateTime.now().millisecondsSinceEpoch + 10^14.
    // This ensures sorting works and Income is always after Expense (if that's desired).
    // The previous UI implementation uses 0-based index and 10000 offset.
    // If we stick to that 0-based reordering, newly added validation might fail if we just throw a timestamp in.
    // But reordering overrides everything anyway.
    // Let's just use the timestamp approach but with a huge offset for Income.

    if (category.order == null) {
      final baseOrder = DateTime.now().millisecondsSinceEpoch;
      // If type is Income, add a prefix/offset to ensure it sorts after Expenses
      // Expenses: 1xxxxxxxxxxxx
      // Income:   2xxxxxxxxxxxx (by adding offset)
      // This way they are naturally grouped if sorted by 'order'.

      // Wait, in ManageCategories we filter by type. So interleaving in DB doesn't matter for the UI list!
      // It only matters if we show them mixed somewhere.
      // But typically we show them separated.
      // So simple timestamp is fine for "end of list" behavior.

      data['order'] = baseOrder;
    }

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('categories')
        .doc(category.id)
        .set(data);
  }

  Future<void> updateCategory(String groupId, Category category) async {
    final data = category.toJson();
    // Ensure subcategories are properly serialized as maps
    data['subcategories'] = category.subcategories
        .map((s) => s.toJson())
        .toList();

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('categories')
        .doc(category.id)
        .update(data);
  }

  Future<void> updateCategoriesOrder(
    String groupId,
    List<Category> categories,
  ) async {
    final batch = _firestore.batch();
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final docRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('categories')
          .doc(category.id);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  Future<void> deleteCategory(String groupId, String categoryId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }
}

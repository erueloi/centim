import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/category.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_providers.dart';

part 'category_notifier.g.dart';

@riverpod
class CategoryNotifier extends _$CategoryNotifier {
  @override
  Stream<List<Category>> build() {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final groupId = userProfile?.currentGroupId;

    if (groupId == null) return Stream.value([]);

    final repository = ref.watch(categoryRepositoryProvider);
    return repository.getCategoriesStream(groupId);
  }

  Future<void> addCategory(Category category) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;
    final repository = ref.read(categoryRepositoryProvider);
    await repository.addCategory(groupId, category);
  }

  Future<void> updateCategory(Category category) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;
    final repository = ref.read(categoryRepositoryProvider);
    await repository.updateCategory(groupId, category);
  }

  Future<void> deleteCategory(String categoryId) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;
    final repository = ref.read(categoryRepositoryProvider);
    await repository.deleteCategory(groupId, categoryId);
  }

  Future<void> updateCategoriesOrder(List<Category> categories) async {
    final groupId = await ref.read(currentGroupIdProvider.future);
    if (groupId == null) return;
    final repository = ref.read(categoryRepositoryProvider);
    await repository.updateCategoriesOrder(groupId, categories);
  }
}

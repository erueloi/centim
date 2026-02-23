import 'package:uuid/uuid.dart';
import '../../domain/models/category.dart';
import '../repositories/category_repository.dart';

/// Service to seed categories from raw text (e.g., Excel column paste).
class CategorySeederService {
  final CategoryRepository _repository;

  CategorySeederService(this._repository);

  /// Parse raw text and create categories/subcategories in Firestore.
  ///
  /// Format:
  /// - Lines in UPPERCASE = new Category
  /// - Lines in lowercase = SubCategory under current Category
  Future<int> seedFromText(String groupId, String rawText) async {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return 0;

    final categories = <Category>[];
    Category? currentCategory;

    for (final line in lines) {
      if (_isUpperCase(line)) {
        // Create new category
        if (currentCategory != null) {
          categories.add(currentCategory);
        }
        currentCategory = Category(
          id: const Uuid().v4(),
          name: _capitalize(line),
          icon: _getIconForCategory(line),
          subcategories: [],
        );
      } else if (currentCategory != null) {
        // Add subcategory to current category
        final newSub = SubCategory(
          id: const Uuid().v4(),
          name: _capitalize(line),
          monthlyBudget: 0.0,
          isFixed: false,
        );
        currentCategory = currentCategory.copyWith(
          subcategories: [...currentCategory.subcategories, newSub],
        );
      }
    }

    // Don't forget the last category
    if (currentCategory != null) {
      categories.add(currentCategory);
    }

    // Save all categories to Firestore
    for (final category in categories) {
      await _repository.addCategory(groupId, category);
    }

    return categories.length;
  }

  /// Check if a string is all uppercase (ignoring non-letters)
  bool _isUpperCase(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ]'), '');
    return letters.isNotEmpty && letters == letters.toUpperCase();
  }

  /// Capitalize first letter of each word
  String _capitalize(String text) {
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Get icon based on category name keywords
  String _getIconForCategory(String name) {
    final upper = name.toUpperCase();

    if (upper.contains('SUPERMERCAT') ||
        upper.contains('ALIMENTACIO') ||
        upper.contains('ALIMENTACIÓ')) {
      return '🛒';
    }
    if (upper.contains('COTXE') ||
        upper.contains('TRANSPORT') ||
        upper.contains('MOTO')) {
      return '🚗';
    }
    if (upper.contains('LLAR') || upper.contains('CASA')) {
      return '🏠';
    }
    if (upper.contains('MASIA') ||
        upper.contains('REFORMA') ||
        upper.contains('OBRES')) {
      return '🛠';
    }
    if (upper.contains('OCI') ||
        upper.contains('VIATGES') ||
        upper.contains('VIATGE')) {
      return '🍺';
    }
    if (upper.contains('SALUT') || upper.contains('MEDIC')) {
      return '💊';
    }
    if (upper.contains('EDUCACIO') ||
        upper.contains('EDUCACIÓ') ||
        upper.contains('FORMACIO')) {
      return '🎓';
    }
    if (upper.contains('ROBA') || upper.contains('VESTIR')) {
      return '👕';
    }
    if (upper.contains('MASCOTA') || upper.contains('ANIMALS')) {
      return '🐶';
    }
    if (upper.contains('TECNOLOGIA') || upper.contains('ELECTRONICA')) {
      return '📱';
    }
    if (upper.contains('BANC') ||
        upper.contains('IMPOSTOS') ||
        upper.contains('ESTALVI')) {
      return '🏦';
    }
    if (upper.contains('SUBSCRIPCIONS') || upper.contains('SERVEIS')) {
      return '🌐';
    }

    return '📂'; // Default
  }

  /// Seeds default income categories
  Future<int> seedIncomeCategories(String groupId) async {
    final incomeCategories = [
      Category(
        id: const Uuid().v4(),
        name: 'Nòmina',
        icon: '💰',
        type: TransactionType.income,
        subcategories: [
          SubCategory(
            id: const Uuid().v4(),
            name: 'Eloi',
            monthlyBudget: 0,
            isFixed: true,
          ),
          SubCategory(
            id: const Uuid().v4(),
            name: 'Jose',
            monthlyBudget: 0,
            isFixed: true,
          ),
        ],
      ),
      Category(
        id: const Uuid().v4(),
        name: 'Rendiments',
        icon: '📈',
        type: TransactionType.income,
        subcategories: [
          SubCategory(
            id: const Uuid().v4(),
            name: 'Interessos',
            monthlyBudget: 0,
            isFixed: false,
          ),
          SubCategory(
            id: const Uuid().v4(),
            name: 'Dividends',
            monthlyBudget: 0,
            isFixed: false,
          ),
        ],
      ),
      Category(
        id: const Uuid().v4(),
        name: 'Regals/Extres',
        icon: '🎁',
        type: TransactionType.income,
        subcategories: [
          SubCategory(
            id: const Uuid().v4(),
            name: 'Aniversaris',
            monthlyBudget: 0,
            isFixed: false,
          ),
          SubCategory(
            id: const Uuid().v4(),
            name: 'Vendes 2a mà',
            monthlyBudget: 0,
            isFixed: false,
          ),
        ],
      ),
      Category(
        id: const Uuid().v4(),
        name: 'Lloguers/Immobles',
        icon: '🏠',
        type: TransactionType.income,
        subcategories: [], // No subcategories specified
      ),
      Category(
        id: const Uuid().v4(),
        name: 'Devolucions',
        icon: '↩️',
        type: TransactionType.income,
        subcategories: [
          SubCategory(
            id: const Uuid().v4(),
            name: 'Hisenda',
            monthlyBudget: 0,
            isFixed: false,
          ),
          SubCategory(
            id: const Uuid().v4(),
            name: 'Retorns compres',
            monthlyBudget: 0,
            isFixed: false,
          ),
        ],
      ),
    ];

    int count = 0;
    for (final category in incomeCategories) {
      await _repository.addCategory(groupId, category);
      count++;
    }

    return count;
  }
}

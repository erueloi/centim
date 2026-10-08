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

  /// Crea les categories per defecte que encara no existeixen al grup.
  ///
  /// Se salten les que ja hi ha amb el mateix nom i tipus (vegeu
  /// [categoriesToSeed]), així que es pot prémer el botó més d'un cop sense
  /// duplicar res. Es desen amb un `order` consecutiu per mantenir l'ordre.
  Future<({int added, int skipped})> seedDefaults(
    String groupId, {
    required List<Category> defaults,
    required List<Category> existing,
  }) async {
    final toAdd = categoriesToSeed(defaults, existing);
    final baseOrder = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < toAdd.length; i++) {
      await _repository.addCategory(
        groupId,
        toAdd[i].copyWith(order: baseOrder + i),
      );
    }
    return (added: toAdd.length, skipped: defaults.length - toAdd.length);
  }
}

/// Les categories de [defaults] que no existeixen encara a [existing] amb el
/// mateix nom (sense distingir majúscules ni accents) i tipus. Les arxivades
/// també compten com a existents: no es tornen a crear.
List<Category> categoriesToSeed(
  List<Category> defaults,
  List<Category> existing,
) {
  final taken = {for (final c in existing) (c.type, _nameKey(c.name))};
  return defaults
      .where((c) => !taken.contains((c.type, _nameKey(c.name))))
      .toList();
}

String _nameKey(String name) {
  const accents = {
    'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'í': 'i', 'ï': 'i', //
    'ò': 'o', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
  };
  final lower = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return lower.split('').map((ch) => accents[ch] ?? ch).join();
}

SubCategory _sub(String name, {bool fixed = false}) => SubCategory(
      id: const Uuid().v4(),
      name: name,
      monthlyBudget: 0,
      isFixed: fixed,
    );

Category _category(
  String name,
  String icon,
  TransactionType type,
  List<SubCategory> subcategories,
) =>
    Category(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      type: type,
      subcategories: subcategories,
    );

/// Ingressos per defecte, genèrics: cada llar hi afegeix les seves
/// subcategories (p. ex. una nòmina per persona).
///
/// "Nòmina" no s'ha de reanomenar: l'informe anual detecta les nòmines pel
/// nom de la categoria.
List<Category> defaultIncomeCategories() {
  const t = TransactionType.income;
  return [
    _category('Nòmina', '💰', t, [_sub('Nòmina', fixed: true)]),
    _category('Rendiments', '📈', t, [_sub('Interessos'), _sub('Dividends')]),
    _category(
        'Regals/Extres', '🎁', t, [_sub('Aniversaris'), _sub('Vendes 2a mà')]),
    _category('Lloguers/Immobles', '🏠', t, []),
    _category(
        'Devolucions', '↩️', t, [_sub('Hisenda'), _sub('Retorns compres')]),
  ];
}

/// Despeses per defecte: categories transversals de qualsevol llar.
List<Category> defaultExpenseCategories() {
  const t = TransactionType.expense;
  return [
    _category('Habitatge', '🏠', t, [
      _sub('Lloguer o hipoteca', fixed: true),
      _sub('Comunitat', fixed: true),
      _sub('Assegurança de la llar', fixed: true),
      _sub('Manteniment'),
    ]),
    _category('Subministraments', '💡', t, [
      _sub('Llum'),
      _sub('Aigua'),
      _sub('Gas'),
      _sub('Internet i mòbil', fixed: true),
    ]),
    _category('Alimentació', '🛒', t, [
      _sub('Supermercat'),
      _sub('Mercat i fleca'),
    ]),
    _category('Transport', '🚗', t, [
      _sub('Combustible'),
      _sub('Transport públic'),
      _sub('Assegurança del vehicle', fixed: true),
      _sub('Manteniment del vehicle'),
      _sub('Aparcament i peatges'),
    ]),
    _category('Salut', '💊', t, [
      _sub('Farmàcia'),
      _sub('Metges i dentista'),
      _sub('Assegurança mèdica', fixed: true),
    ]),
    _category('Oci', '🍺', t, [
      _sub('Restaurants'),
      _sub('Viatges'),
      _sub('Activitats i cultura'),
    ]),
    _category('Roba i cura personal', '👕', t, [
      _sub('Roba i calçat'),
      _sub('Perruqueria i cosmètica'),
    ]),
    _category('Educació', '🎓', t, [
      _sub('Escola i formació'),
      _sub('Llibres i material'),
    ]),
    _category('Subscripcions', '🌐', t, [
      _sub('Plataformes digitals', fixed: true),
      _sub('Gimnàs', fixed: true),
    ]),
    _category('Impostos i comissions', '🏦', t, [
      _sub('Impostos (IBI, etc.)'),
      _sub('Comissions bancàries'),
    ]),
    _category('Altres', '🎁', t, [
      _sub('Regals'),
      _sub('Imprevistos'),
    ]),
  ];
}

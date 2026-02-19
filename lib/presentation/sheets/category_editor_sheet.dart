import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/category.dart';
import '../providers/category_notifier.dart';

class CategoryEditorSheet extends ConsumerStatefulWidget {
  final Category? category;
  final TransactionType initialType;

  const CategoryEditorSheet({
    super.key,
    this.category,
    this.initialType = TransactionType.expense,
  });

  @override
  ConsumerState<CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late TransactionType _selectedType;
  int? _selectedColor;

  final List<String> _commonEmojis = [
    '🏠',
    '🛒',
    '🚗',
    '🏍️',
    '🚇',
    '✈️',
    '🍽️',
    '🍺',
    '💊',
    '🎓',
    '📚',
    '👕',
    '🎁',
    '🐶',
    '🛠',
    '💡',
    '💧',
    '🌐',
    '📱',
    '🏦',
    '💳',
    '🧾',
    '🎉',
    '🏋️',
    '🎬',
    '🎮',
    '👶',
    '💄',
    '🔧',
    '💻',
  ];

  final List<Color> _predefinedColors = [
    AppTheme.copper,
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
    Colors.grey[700]!,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? '🏠';
    _selectedType = widget.category?.type ?? widget.initialType;
    _selectedColor = widget.category?.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tria una icona',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _commonEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _commonEmojis[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = emoji;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedIcon == emoji
                              ? AppTheme.copper.withAlpha(40)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    final newCategory =
        widget.category?.copyWith(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          type: _selectedType,
          color: _selectedColor,
        ) ??
        Category(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          type: _selectedType,
          color: _selectedColor,
        );

    if (widget.category == null) {
      await ref
          .read(categoryNotifierProvider.notifier)
          .addCategory(newCategory);
    } else {
      await ref
          .read(categoryNotifierProvider.notifier)
          .updateCategory(newCategory);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the active color for UI feedback
    final activeColor = _selectedColor != null
        ? Color(_selectedColor!)
        : AppTheme.copper;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Text(
              widget.category == null ? 'Nova Categoria' : 'Editar Categoria',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Hero Icon
            GestureDetector(
              onTap: _showIconPicker,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: activeColor.withAlpha(30),
                child: Text(
                  _selectedIcon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name Input
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.anthracite,
              ),
              decoration: const InputDecoration(
                hintText: 'Nom',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),

            // Divider or spacing
            const Divider(),
            const SizedBox(height: 16),

            // Type Selector (only if new)
            if (widget.category == null) ...[
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Despesa'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Ingrés'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Color Selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _predefinedColors.map((color) {
                  final isSelected = _selectedColor == color.toARGB32();
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          // Toggle: if selected, unselect (set to null), else select
                          if (isSelected) {
                            _selectedColor = null;
                          } else {
                            _selectedColor = color.toARGB32();
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.copper,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Guardar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

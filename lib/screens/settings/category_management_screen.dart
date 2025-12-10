import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/category_model.dart';
import '../../services/auth_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _authService = AuthService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      final categories = await _dbHelper.getCategories(userId);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _addDefaultCategories() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;

    final defaultCategories = Category.getDefaultCategories(userId);
    for (var category in defaultCategories) {
      await _dbHelper.createCategory(category);
    }
    _loadCategories();
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return;

    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    Color selectedColor = category?.color ?? Colors.blue;
    IconData selectedIcon = category?.iconData ?? Icons.category;

    final List<IconData> icons = [
      Icons.work,
      Icons.person,
      Icons.shopping_cart,
      Icons.favorite,
      Icons.school,
      Icons.home,
      Icons.fitness_center,
      Icons.restaurant,
      Icons.flight,
      Icons.local_hospital,
      Icons.music_note,
      Icons.sports_soccer,
      Icons.computer,
      Icons.book,
      Icons.brush,
      Icons.attach_money,
      Icons.pets,
      Icons.directions_car,
      Icons.beach_access,
      Icons.celebration,
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pick a color'),
                        content: SingleChildScrollView(
                          child: BlockPicker(
                            pickerColor: selectedColor,
                            onColorChanged: (color) {
                              setDialogState(() => selectedColor = color);
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: icons.length,
                    itemBuilder: (context, index) {
                      final icon = icons[index];
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedIcon = icon);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? selectedColor.withOpacity(0.3) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? selectedColor : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? selectedColor : Colors.grey[700],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }

                final newCategory = Category(
                  id: category?.id,
                  userId: userId,
                  name: nameController.text.trim(),
                  colorValue: '0x${selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
                  icon: '${selectedIcon.codePoint}',
                  createdAt: category?.createdAt ?? DateTime.now(),
                );

                if (isEdit) {
                  await _dbHelper.updateCategory(newCategory);
                } else {
                  await _dbHelper.createCategory(newCategory);
                }

                Navigator.pop(context);
                _loadCategories();
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteCategory(category.id!);
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          if (_categories.isEmpty)
            TextButton.icon(
              onPressed: _addDefaultCategories,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text('Add Defaults', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No categories yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addDefaultCategories,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Default Categories'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(category.iconData, color: category.color),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showCategoryDialog(category: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(category),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

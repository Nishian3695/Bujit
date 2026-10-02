// Mirrors NavigationItems/Settings/CategoryManagerActivity.java in the original
// Java app: the user's spending categories, in the order the expense dialog
// lists them. Add (names are unique ignoring case; "Other" is built in), drag to
// reorder, and remove -- expenses in a removed category move to "Other".
import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../dialogs/text_prompt_dialog.dart';
import '../../utils/category_manager.dart';

class CategoryManagerActivity extends StatefulWidget {
    final AppState state;
    const CategoryManagerActivity({super.key, required this.state});

    @override
    State<CategoryManagerActivity> createState() => _CategoryManagerActivityState();
}

class _CategoryManagerActivityState extends State<CategoryManagerActivity> {
    List<String> get _categories => widget.state.data.categories;

    Future<void> _save() async {
        setState(() {});
        await widget.state.changed();
    }

    Future<void> _add() async {
        final List<String>? values = await showTextPrompt(
            context,
            title: "New Category",
            fields: const [PromptField("Category name")],
            confirmLabel: "Add",
            validate: (values) {
                final String name = values.first.trim();
                if (name.isEmpty) return "Name is required";
                if (name == newCategory || widget.state.data.hasCategory(name)) return "Category already exists";
                return null;
            },
        );
        if (values == null) return;
        _categories.add(values.first.trim());
        await _save();
    }

    Future<void> _remove(String category) async {
        final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Remove Category"),
                content: Text("Remove \"$category\"? Expenses tagged with this category will show as \"$otherCategory\"."),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Remove")),
                ],
            ),
        );
        if (confirmed != true) return;
        widget.state.data.removeCategory(category);
        await _save();
    }

    // ([newIndex] already allows for the row's removal, as onReorderItem gives it.)
    void _reorder(int oldIndex, int newIndex) {
        _categories.insert(newIndex, _categories.removeAt(oldIndex));
        _save();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text("Categories")),
            body: _categories.isEmpty
                ? const Center(child: Text("No categories. Tap + to add one."))
                : ReorderableListView.builder(
                    itemCount: _categories.length,
                    onReorderItem: _reorder,
                    itemBuilder: (context, index) {
                        final String category = _categories[index];
                        return ListTile(
                            key: ValueKey(category),
                            title: Text(category),
                            trailing: IconButton(
                                onPressed: () => _remove(category),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: "Remove $category",
                            ),
                        );
                    },
                ),
            floatingActionButton: FloatingActionButton(
                onPressed: _add,
                tooltip: "Add category",
                child: const Icon(Icons.add),
            ),
        );
    }
}

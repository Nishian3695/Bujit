import 'package:drift/drift.dart';

// Flat list of user-defined category names (StorageHolder.categories).
// Does NOT include category_manager.dart's `newCategory` sentinel
// ("── New Category ──") -- that string means "show the add-new-category
// UI prompt" and must never be written here. Whether/where to seed
// defaultCategories() on first run is left for you to decide when
// building the DAO (e.g. seed once in StorageManager.create() if empty).
//
// TODO(you): build a CategoriesDao + mapper (rows <-> List<String>).
@DataClassName('Category') // REQUIRED -- drift's default "strip a trailing
// s" heuristic would otherwise turn "Categories" into "Categorie".
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  // unique() enforces one row per category name at the SQL level.
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
}

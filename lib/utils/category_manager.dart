// Holds the app's spending-category constants/defaults

const String otherCategory = "Other";
const String creditCardsCategory = "Credit Cards";
const String newCategory = "── New Category ──";

const List<String> _defaultCategories = [
    "Housing", "Food", "Transport", "Entertainment",
    "Utilities", "Healthcare", "Shopping", "Subscriptions",
];

// Starter category list for new installs
List<String> defaultCategories() => List.of(_defaultCategories);

// Builds the dropdown list shown in the add/edit expense dialog
// [user categories] + "Other" + "New Category" tag
List<String> getCategories(List<String> userCategories) {
    final list = [...userCategories];
    if (!list.contains(otherCategory)) list.add(otherCategory);
    list.add(newCategory);
    return list;
}

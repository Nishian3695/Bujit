package io.github.nishian3695.bujit.StorageManagement;

import java.util.ArrayList;
import java.util.Arrays;

public class CategoryManager {

    public static final String OTHER = "Other";
    public static final String CREDIT_CARDS = "Credit Cards";
    public static final String NEW_CATEGORY_SENTINEL = "── New Category ──";

    private static final String[] DEFAULTS = {
        "Housing", "Food", "Transport", "Entertainment",
        "Utilities", "Healthcare", "Shopping", "Subscriptions"
    };

    public static ArrayList<String> getDefaults() {
        return new ArrayList<>(Arrays.asList(DEFAULTS));
    }

    // Builds the dropdown list shown in the add/edit expense dialog:
    // [user categories] + "Other" + "── New Category ──"
    public static ArrayList<String> buildDropdownList(ArrayList<String> userCategories) {
        ArrayList<String> list = new ArrayList<>(userCategories);
        if (!list.contains(OTHER)) list.add(OTHER);
        list.add(NEW_CATEGORY_SENTINEL);
        return list;
    }
}

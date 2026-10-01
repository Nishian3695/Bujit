// Shared tag for how often a recurring amount repeats. Used by anything with
// a (frequency count, frequency unit) pair -- expenses, income streams, etc.
enum FrequencyUnit {
    daily("Daily"),
    weekly("Weekly"),
    biweekly("Biweekly"),
    monthly("Monthly"),
    yearly("Yearly");

    const FrequencyUnit(this.label);
    final String label; // Display text for dropdowns and other UI.
}

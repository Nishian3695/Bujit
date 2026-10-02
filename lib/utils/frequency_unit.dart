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

// "Every 2 weeks", "Every 1 month", etc.
String describeFrequency(int frequency, FrequencyUnit unit) {
    final String plurality = frequency > 1 ? 's' : '';
    final String base = switch (unit) {
        FrequencyUnit.daily => 'day',
        FrequencyUnit.weekly => 'week',
        FrequencyUnit.biweekly => 'biweek',
        FrequencyUnit.monthly => 'month',
        FrequencyUnit.yearly => 'year',
    };
    return 'Every $frequency $base$plurality';
}

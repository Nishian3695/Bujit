// The Java app's Projection Settings: project future checks with a chosen
// income stream and pay period instead of the real paydays -- a "what if" for
// the home screen, kept for the session only (never saved, as in the Java app).
//
// While set, projected checks (not the current one) are [period] long, one
// after another from the end of the current check, and each gets the chosen
// stream's pay, scaled to the period's length when it's a custom one (the Java
// app's computeProjAmount). The Java app stepped projected checks from the
// current check's START, which left a gap or overlap after the current check
// whenever the period differed; here they continue from its end.
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../../utils/projector.dart';
import '../income_streams/income_stream_model.dart';

class ProjectionSettings {
    final IncomeStreamModel stream;
    final int frequency; // Period length, in [unit]s
    final FrequencyUnit unit;

    ProjectionSettings({required this.stream, required this.frequency, required this.unit})
        : assert(frequency > 0);

    // The stream's own pay period.
    ProjectionSettings.streamPeriod(this.stream)
        : frequency = stream.frequency > 0 ? stream.frequency : 1,
          unit = stream.frequencyUnits;

    bool get isCustomPeriod => frequency != stream.frequency || unit != stream.frequencyUnits;

    // The [k]-th projected check's opening day, counting from [firstStart] (k = 0).
    DateTime checkStart(DateTime firstStart, int k) =>
        Projector(baseDate: firstStart, frequency: frequency, frequencyUnits: unit).occurrenceDate(k);

    // Income for one projected check: the stream's amount, scaled by days for a custom period.
    double amountPerCheck({DateTime? today}) {
        if (!isCustomPeriod) return stream.amount;
        final DateTime day = dateOnly(today ?? todayDate());
        final int customDays = daysBetween(day, checkStart(day, 1));
        final int streamDays = stream.frequency > 0
            ? daysBetween(day, Projector(baseDate: day, frequency: stream.frequency,
                frequencyUnits: stream.frequencyUnits).occurrenceDate(1))
            : 0;
        return streamDays <= 0 ? stream.amount : stream.amount * customDays / streamDays;
    }

    // For the home screen: "Side Job · every 1 month".
    String describe() =>
        "${stream.name} · ${describeFrequency(frequency, unit).replaceFirst("Every", "every")}";
}

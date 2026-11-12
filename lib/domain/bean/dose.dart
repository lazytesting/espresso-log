const double defaultDoseGrams = 18.0;
const double minDoseGrams = 5.0;
const double maxDoseGrams = 30.0;
const double doseStepGrams = 0.1;

/// Clamps [grams] to the allowed range and rounds to one decimal.
double normalizeDose(double grams) {
  final clamped = grams.clamp(minDoseGrams, maxDoseGrams).toDouble();
  return (clamped * 10).round() / 10;
}

/// Parses user input (`,` or `.` as separator); null when not a finite number.
double? parseDose(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) return null;
  return normalizeDose(value);
}

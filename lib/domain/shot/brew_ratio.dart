/// Output weight divided by dose, or null when it cannot be computed.
double? brewRatio({double? outputGrams, double? doseGrams}) {
  if (outputGrams == null || doseGrams == null) return null;
  if (doseGrams <= 0 || outputGrams <= 0) return null;
  return outputGrams / doseGrams;
}

/// Formats a ratio as `1 : 2.1`, or `--` when unknown.
String formatBrewRatio(double? ratio) =>
    ratio == null ? '--' : '1 : ${ratio.toStringAsFixed(1)}';

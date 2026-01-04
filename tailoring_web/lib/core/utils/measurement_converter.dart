/// Utility class for converting measurement inputs to decimal format
/// Supports: 10.5, 10 1/2, 10-1/2, 10 1/4, etc.
class MeasurementConverter {
  /// Convert user input to decimal
  /// Examples:
  ///   "10.5" → 10.5
  ///   "10 1/2" → 10.5
  ///   "10-1/2" → 10.5
  ///   "10 1/4" → 10.25
  ///   "10" → 10.0
  static double? parseInput(String input) {
    if (input.trim().isEmpty) return null;

    try {
      final cleanInput = input.trim();

      // Handle decimal: 10.5
      if (!cleanInput.contains('/')) {
        return double.parse(cleanInput);
      }

      // Handle fraction: 10 1/2 or 10-1/2
      // Replace dash with space for consistency
      final normalized = cleanInput.replaceAll('-', ' ');
      final parts = normalized.split(' ');

      // Get whole number part
      double whole = double.parse(parts[0]);

      // Get fractional part if exists
      if (parts.length > 1 && parts[1].contains('/')) {
        final fractionParts = parts[1].split('/');
        double numerator = double.parse(fractionParts[0]);
        double denominator = double.parse(fractionParts[1]);
        return whole + (numerator / denominator);
      }

      return whole;
    } catch (e) {
      // Return null if parsing fails
      return null;
    }
  }

  /// Format decimal to display string (e.g., 10.5 → "10.5")
  static String formatOutput(double? value) {
    if (value == null) return '';

    // Remove trailing zeros
    String result = value.toStringAsFixed(2);

    // Remove .00 if whole number
    if (result.endsWith('.00')) {
      result = result.substring(0, result.length - 3);
    } else if (result.endsWith('0') && result.contains('.')) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// Validate input format
  static bool isValidInput(String input) {
    if (input.trim().isEmpty) return true; // Empty is valid (optional field)

    try {
      parseInput(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get error message for invalid input
  static String? getErrorMessage(String input) {
    if (input.trim().isEmpty) return null;

    if (!isValidInput(input)) {
      return 'Invalid format. Use: 10.5 or 10 1/2';
    }

    return null;
  }
}

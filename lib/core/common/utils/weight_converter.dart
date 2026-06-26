// lib/core/common/utils/weight_converter.dart
//
// Single source of truth for all weight/volume conversions.
//
// The backend ALWAYS stores weight as a double (grams-equivalent).
// Volume units (mL, L) are stored as their mL value in the same field.
//
// Because the backend has no unit field, the original unit is encoded into
// the item's notes string as a hidden tag: [wu:mL], [wu:L], [wu:mg], [wu:kg].
// Units of 'g' need no tag (it's the default/assumed unit).
//
// Conversion table (all stored as double in grams/mL field):
//   mg  →  ÷ 1000  (e.g. 500 mg → stored as 0.5)
//   g   →  × 1
//   kg  →  × 1000  (e.g. 1.5 kg → stored as 1500)
//   mL  →  × 1     (stored as mL value — same numeric scale as g)
//   L   →  × 1000  (e.g. 2 L → stored as 2000)

class WeightConverter {
  WeightConverter._();

  // ── Unit list exposed to UI dropdowns ────────────────────────────────────
  static const List<String> supportedUnits = ['g', 'mg', 'kg', 'mL', 'L'];

  // ── Hidden tag embedded in notes to preserve original unit ───────────────
  static const String _tagPrefix = '[wu:';
  static const String _tagSuffix = ']';

  // ── Auto-display thresholds ───────────────────────────────────────────────
  static const double _kgThreshold = 1000.0;
  static const double _mgThreshold = 1.0;

  // ── isVolumeUnit ──────────────────────────────────────────────────────────
  static bool isVolumeUnit(String unit) => unit == 'mL' || unit == 'L';

  // ─────────────────────────────────────────────────────────────────────────
  // toGrams  —  call this on SAVE
  // ─────────────────────────────────────────────────────────────────────────
  /// Converts [rawValue] in [unit] to the gram/mL-equivalent for backend storage.
  /// Returns null when [rawValue] is null, empty, or not parseable.
  static double? toGrams(String? rawValue, String unit) {
    if (rawValue == null || rawValue.trim().isEmpty) return null;
    final value = double.tryParse(rawValue.trim());
    if (value == null) return null;

    switch (unit) {
      case 'mg':  return value / 1000.0;
      case 'kg':  return value * 1000.0;
      case 'mL':  return value;
      case 'L':   return value * 1000.0;
      case 'g':
      default:    return value;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // encodeUnitInNotes  —  call this on SAVE alongside toGrams()
  // ─────────────────────────────────────────────────────────────────────────
  /// Appends a hidden unit tag to [existingNotes] so we can recover the unit
  /// after the backend round-trip.  Tags look like: [wu:mL]
  ///
  /// For 'g' (default) we write no tag — saves space and keeps notes clean.
  static String encodeUnitInNotes(String existingNotes, String unit) {
    final stripped = _stripTag(existingNotes);
    if (unit == 'g') return stripped;
    final tag = '$_tagPrefix$unit$_tagSuffix';
    return stripped.isEmpty ? tag : '$stripped $tag';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // decodeUnitFromNotes  —  call this in toFoodItem() / fromGrams display
  // ─────────────────────────────────────────────────────────────────────────
  /// Reads the [wu:XX] tag from notes and returns the original unit.
  /// Returns 'g' when no tag is present (safe default).
  static String decodeUnitFromNotes(String? notes) {
    if (notes == null) return 'g';
    final start = notes.indexOf(_tagPrefix);
    if (start == -1) return 'g';
    final end = notes.indexOf(_tagSuffix, start);
    if (end == -1) return 'g';
    return notes.substring(start + _tagPrefix.length, end);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // stripTagFromNotes  —  call when DISPLAYING notes to the user
  // ─────────────────────────────────────────────────────────────────────────
  /// Returns the notes string with the hidden [wu:XX] tag removed.
  static String? stripTagFromNotes(String? notes) {
    if (notes == null) return null;
    final stripped = _stripTag(notes).trim();
    return stripped.isEmpty ? null : stripped;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // fromGrams  —  call this on LOAD / DISPLAY
  // ─────────────────────────────────────────────────────────────────────────
  /// Converts a stored gram/mL value back to a human-friendly (value, unit).
  ///
  /// [originalUnit] should come from [decodeUnitFromNotes] so volume items
  /// stay in mL/L and mg items are shown correctly.
  static ({String displayValue, String displayUnit})? fromGrams(
      String? gramsValue, {
        String originalUnit = 'g',
      }) {
    if (gramsValue == null || gramsValue.trim().isEmpty) return null;
    final stored = double.tryParse(gramsValue.trim());
    if (stored == null) return null;

    switch (originalUnit) {
      case 'mL':
        if (stored >= 1000.0) {
          return (displayValue: _fmt(stored / 1000.0), displayUnit: 'L');
        }
        return (displayValue: _fmt(stored), displayUnit: 'mL');

      case 'L':
        if (stored >= 1000.0) {
          return (displayValue: _fmt(stored / 1000.0), displayUnit: 'L');
        }
        return (displayValue: _fmt(stored), displayUnit: 'mL');

      case 'mg':
      // stored = original_mg / 1000  →  display = stored * 1000
        return (displayValue: _fmt(stored * 1000.0), displayUnit: 'mg');

      case 'kg':
      // stored = original_kg * 1000  →  display = stored / 1000
        return (displayValue: _fmt(stored / 1000.0), displayUnit: 'kg');

      case 'g':
      default:
        if (stored > 0 && stored < _mgThreshold) {
          return (displayValue: _fmt(stored * 1000.0), displayUnit: 'mg');
        }
        if (stored >= _kgThreshold) {
          return (displayValue: _fmt(stored / 1000.0), displayUnit: 'kg');
        }
        return (displayValue: _fmt(stored), displayUnit: 'g');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // formatWeightDisplay  —  convenience one-liner for display strings
  // ─────────────────────────────────────────────────────────────────────────
  static String formatWeightDisplay(String? gramsValue, {String originalUnit = 'g'}) {
    final r = fromGrams(gramsValue, originalUnit: originalUnit);
    if (r == null) return '';
    return '${r.displayValue} ${r.displayUnit}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // helperText  —  drives the weight field hint in the UI
  // ─────────────────────────────────────────────────────────────────────────
  // static String helperText(String unit) {
  //   switch (unit) {
  //     case 'mg':  return 'Enter milligrams — stored as grams';
  //     case 'kg':  return 'Enter kilograms — stored as grams';
  //     case 'mL':  return 'Enter millilitres';
  //     case 'L':   return 'Enter litres';
  //     case 'g':
  //     default:    return 'Enter grams';
  //   }
  // }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────
  static String _fmt(double v) {
    String s = v.toStringAsFixed(4);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  static String _stripTag(String notes) {
    return notes
        .replaceAll(RegExp(r'\s*\[wu:[^\]]*\]'), '')
        .trim();
  }
}
/// Validates a user-entered name, shared between the first-launch
/// prompt and the Settings screen so both enforce the same rules.
class NameValidator {
  NameValidator._();

  static const int maxLength = 30;

  /// Letters (including accented/non-Latin ones), spaces, hyphens,
  /// and apostrophes — covers names like "Mary-Jane", "O'Brien",
  /// "José", "Nguyễn" without allowing digits or symbols.
  static final RegExp _allowedCharacters = RegExp(r"^[\p{L}\s'-]+$", unicode: true);
  static final RegExp _containsLetter = RegExp(r'\p{L}', unicode: true);

  /// Returns an error message if [input] isn't an acceptable name, or
  /// null if it's fine. An empty/whitespace-only input is treated as
  /// valid (not an error) — that's "no name provided", handled by the
  /// caller as equivalent to skipping, not as invalid input.
  static String? validate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.length > maxLength) {
      return 'Keep it under $maxLength characters';
    }
    if (!_allowedCharacters.hasMatch(trimmed)) {
      return 'Only letters, spaces, hyphens, and apostrophes';
    }
    if (!_containsLetter.hasMatch(trimmed)) {
      return 'Please enter an actual name';
    }
    return null;
  }

  static bool isValid(String input) => validate(input) == null;
}

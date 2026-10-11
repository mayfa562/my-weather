import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../utils/name_validator.dart';
import '../localization/app_strings.dart';

/// The one-time prompt asking for the user's name, so the home screen
/// can greet them by it. Shown from [HomeScreen] only when a name
/// isn't already set and the prompt hasn't been shown before —
/// skipping it is fine and won't cause it to reappear on next launch.
class NamePromptDialog extends StatefulWidget {
  const NamePromptDialog({super.key});

  @override
  State<NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<NamePromptDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Only updates the error message shown below the field — actual
    // invalid characters are already blocked from being typed by the
    // inputFormatters below, so this mainly catches "too long" and
    // "symbols-only, no real letters".
    setState(() => _errorText = NameValidator.validate(value));
  }

  void _skip() {
    context.read<WeatherProvider>().markNamePromptShown();
    Navigator.of(context).pop();
  }

  void _save() {
    final text = _controller.text;
    final error = NameValidator.validate(text);

    if (error != null) {
      setState(() => _errorText = error);
      return; // don't dismiss — let them fix it or tap Skip instead
    }

    final provider = context.read<WeatherProvider>();
    if (text.trim().isNotEmpty) {
      provider.setUserName(text);
    }
    provider.markNamePromptShown();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      backgroundColor: AppColors.cardTint,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      title: Text(
        strings.whatShouldWeCallYou,
        style:
            const TextStyle(color: AppColors.violetDeep, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        // Blocks digits/symbols at the keystroke level — the
        // remaining error cases (too long, or nothing but hyphens/
        // spaces) are caught by NameValidator on save instead, since
        // they depend on the whole string rather than one character.
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(r"[\p{L}\s'-]", unicode: true)),
          LengthLimitingTextInputFormatter(NameValidator.maxLength),
        ],
        decoration: InputDecoration(
          hintText: strings.nameHint,
          errorText: _errorText,
        ),
        onChanged: _onChanged,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: _skip,
          child: Text(strings.skip,
              style: TextStyle(color: AppColors.violetDeep.withValues(alpha: 0.6))),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(strings.save),
        ),
      ],
    );
  }
}

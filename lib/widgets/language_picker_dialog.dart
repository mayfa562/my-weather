import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../localization/app_strings.dart';

class LanguageOption {
  final String code;
  final String label;
  final String nativeLabel;

  const LanguageOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });
}

class LanguagePickerDialog extends StatefulWidget {
  final ValueChanged<String> onLanguageSelected;
  final String selectedCode;
  final VoidCallback? onCancel;

  const LanguagePickerDialog({
    super.key,
    required this.onLanguageSelected,
    this.selectedCode = 'en',
    this.onCancel,
  });

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', label: 'English', nativeLabel: 'English'),
    LanguageOption(code: 'es', label: 'Español', nativeLabel: 'Español'),
    LanguageOption(code: 'fr', label: 'Français', nativeLabel: 'Français'),
  ];

  @override
  State<LanguagePickerDialog> createState() => _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends State<LanguagePickerDialog> {
  late String _pendingCode;

  @override
  void initState() {
    super.initState();
    _pendingCode = widget.selectedCode;
  }

  void _proceed() {
    widget.onLanguageSelected(_pendingCode);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(strings.chooseLanguage),
      content: SizedBox(
        width: double.maxFinite,
        child: RadioGroup<String>(
          groupValue: _pendingCode,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _pendingCode = value);
          },
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: LanguagePickerDialog.supportedLanguages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = LanguagePickerDialog.supportedLanguages[index];
              return RadioListTile<String>(
                value: option.code,
                title: Text(option.label),
                subtitle: Text(option.nativeLabel),
                activeColor: AppColors.violet,
                selected: option.code == _pendingCode,
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _proceed,
          child: Text(strings.proceed),
        ),
      ],
    );
  }
}

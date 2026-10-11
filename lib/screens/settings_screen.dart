import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../utils/name_validator.dart';
import '../widgets/language_picker_dialog.dart';
import '../localization/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  String? _nameError;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: context.read<WeatherProvider>().userName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final error = NameValidator.validate(_nameController.text);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    context.read<WeatherProvider>().setUserName(_nameController.text);
    FocusScope.of(context).unfocus();
  }

  Future<void> _language() async {
    final p = context.read<WeatherProvider>();
    await showDialog(
        context: context,
        builder: (_) => LanguagePickerDialog(
            selectedCode: p.languageCode,
            onLanguageSelected: (code) async => p.setAppLanguage(code)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final provider = context.watch<WeatherProvider>();
    final language = LanguagePickerDialog.supportedLanguages
        .firstWhere(
          (x) => x.code == provider.languageCode,
          orElse: () => LanguagePickerDialog.supportedLanguages.first,
        )
        .label;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.violetDeep),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    strings.settings,
                    style: const TextStyle(
                        color: AppColors.violetDark,
                        fontSize: 23,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Header(
                icon: Icons.tune_rounded,
                title: strings.personalizeWeather,
                subtitle: strings.makeAppYours,
              ),
              const SizedBox(height: 18),
              _Section(
                title: strings.profile,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r"[\p{L}\s'-]", unicode: true)),
                        LengthLimitingTextInputFormatter(
                            NameValidator.maxLength),
                      ],
                      decoration: InputDecoration(
                        labelText: strings.yourName,
                        hintText: strings.greetingHint,
                        errorText: _nameError,
                        suffixIcon: IconButton(
                          onPressed: _saveName,
                          icon: const Icon(Icons.check_rounded),
                        ),
                      ),
                      onChanged: (v) => setState(
                          () => _nameError = NameValidator.validate(v)),
                      onSubmitted: (_) => _saveName,
                    ),
                  ),
                ],
              ),
              _Section(
                title: strings.appPreferences,
                children: [
                  ListTile(
                    leading: const _CircleIcon(icon: Icons.language_rounded),
                    title: Text(strings.language,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(language),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _language,
                  ),
                ],
              ),
              _Section(
                title: strings.weather,
                children: [
                  ListTile(
                    leading: const _CircleIcon(
                        icon: Icons.notifications_active_outlined),
                    title: Text(strings.weatherAlerts,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(strings.significantChanges),
                  ),
                ],
              ),
              _Section(
                title: strings.about,
                children: [
                  ListTile(
                    leading: const _CircleIcon(icon: Icons.cloud_rounded),
                    title: Text(strings.appName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle:
                        Text('${strings.createdBy}\n${strings.builtWith}'),
                    isThreeLine: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;

  const _Header(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.violetDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.violetDark,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;

  const _CircleIcon({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.violet.withValues(alpha: .10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.violetDeep, size: 20),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 7),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.violetDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8),
              ),
            ),
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: AppRadius.xl,
              child: Column(children: children),
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../localization/app_strings.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_logo.dart';
import '../utils/name_validator.dart';
import '../widgets/language_picker_dialog.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _OnboardingStep { language, welcome, name }

class _OnboardingScreenState extends State<OnboardingScreen> {
  _OnboardingStep _step = _OnboardingStep.language;
  late String _pendingLanguageCode;
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _pendingLanguageCode = context.read<WeatherProvider>().languageCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectLanguage(String code) {
    setState(() => _pendingLanguageCode = code);
  }

  Future<void> _proceedFromLanguage() async {
    await context.read<WeatherProvider>().setAppLanguage(_pendingLanguageCode);
    if (!mounted) return;
    setState(() => _step = _OnboardingStep.welcome);
  }

  void _continueToName() => setState(() => _step = _OnboardingStep.name);

  void _backToLanguage() => setState(() {
        _step = _OnboardingStep.language;
        _nameError = null;
      });

  Future<void> _finish({bool skip = false}) async {
    final provider = context.read<WeatherProvider>();
    if (!skip) {
      final error = NameValidator.validate(_nameController.text);
      if (error != null) {
        setState(() => _nameError = error);
        return;
      }
      if (_nameController.text.trim().isNotEmpty) {
        await provider.setUserName(_nameController.text);
      }
    }
    await provider.markNamePromptShown();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_fadeRoute(const HomeScreen()));
  }

  Route<void> _fadeRoute(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: page),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child:
                KeyedSubtree(key: ValueKey(_step), child: _buildStep(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case _OnboardingStep.language:
        return _LanguageStep(
          selectedCode: _pendingLanguageCode,
          onSelected: _selectLanguage,
          onProceed: _proceedFromLanguage,
        );
      case _OnboardingStep.welcome:
        return _WelcomeStep(
          onContinue: _continueToName,
          onBack: _backToLanguage,
        );
      case _OnboardingStep.name:
        return _NameStep(
          controller: _nameController,
          errorText: _nameError,
          onChanged: (value) =>
              setState(() => _nameError = NameValidator.validate(value)),
          onSave: () => _finish(),
          onSkip: () => _finish(skip: true),
          onBack: _backToLanguage,
        );
    }
  }
}

class _LanguageStep extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String> onSelected;
  final VoidCallback onProceed;
  const _LanguageStep(
      {required this.selectedCode,
      required this.onSelected,
      required this.onProceed});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _OnboardingShell(
      progress: .33,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StartupWeatherMark(size: 112),
          const SizedBox(height: 30),
          Text(strings.chooseLanguage, style: _titleStyle),
          const SizedBox(height: 10),
          Text(strings.appName, style: _subtitleStyle),
          const SizedBox(height: 30),
          ...LanguagePickerDialog.supportedLanguages.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LanguageCard(
                  option: option,
                  selected: option.code == selectedCode,
                  onTap: () => onSelected(option.code),
                ),
              )),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onProceed,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(strings.proceed),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  const _WelcomeStep({required this.onContinue, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _OnboardingShell(
      progress: .66,
      center: true,
      leading: IconButton(
        tooltip: strings.chooseLanguage,
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .42),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.violetDeep.withValues(alpha: .16),
                    blurRadius: 30,
                    offset: const Offset(0, 14))
              ],
            ),
            child: const StartupWeatherMark(size: 150),
          ),
          const SizedBox(height: 28),
          Text(strings.welcomeToMyWeather,
              textAlign: TextAlign.center, style: _titleStyle),
          const SizedBox(height: 10),
          Text(strings.weatherMadeSimple,
              textAlign: TextAlign.center, style: _subtitleStyle),
          const SizedBox(height: 10),
          Text(strings.personalizedForecast,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 15, height: 1.5)),
          const SizedBox(height: 34),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: onContinue, child: Text(strings.getStarted))),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  const _NameStep(
      {required this.controller,
      required this.errorText,
      required this.onChanged,
      required this.onSave,
      required this.onSkip,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _OnboardingShell(
      progress: 1,
      leading: IconButton(
        tooltip: strings.chooseLanguage,
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const StartupWeatherMark(size: 96),
          const SizedBox(height: 28),
          Text(strings.tellUsYourName, style: _titleStyle),
          const SizedBox(height: 10),
          Text(strings.namePersonalizationHint, style: _subtitleStyle),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r"[\p{L}\s'-]", unicode: true)),
              LengthLimitingTextInputFormatter(NameValidator.maxLength),
            ],
            decoration: InputDecoration(
                labelText: strings.enterName,
                hintText: strings.nameHint,
                errorText: errorText),
            onChanged: onChanged,
            onSubmitted: (_) => onSave(),
          ),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: onSave, child: Text(strings.saveAndContinue))),
          Center(
              child: TextButton(
                  onPressed: onSkip, child: Text(strings.skipForNow))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OnboardingShell extends StatelessWidget {
  final Widget child;
  final double progress;
  final bool center;
  final Widget? leading;
  const _OnboardingShell(
      {required this.child,
      required this.progress,
      this.center = false,
      this.leading});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Align(
            alignment: center ? Alignment.center : Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: .35),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.violet))),
                Row(
                  children: [
                    SizedBox(width: 48, height: 48, child: leading),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _LanguageCard extends StatelessWidget {
  final LanguageOption option;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageCard(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.violet.withValues(alpha: .12)
          : Colors.white.withValues(alpha: .48),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(option.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.violetDeep,
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(option.nativeLabel,
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13))
                ])),
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.violet : AppColors.textMuted),
          ]),
        ),
      ),
    );
  }
}

const _titleStyle = TextStyle(
    color: AppColors.violetDeep,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -.7);
const _subtitleStyle =
    TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.5);

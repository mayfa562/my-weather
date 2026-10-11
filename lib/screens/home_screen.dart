import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/weather_provider.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/forecast_list.dart';
import '../widgets/hourly_forecast_list.dart';
import '../widgets/greeting_banner.dart';
import '../widgets/name_prompt_dialog.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';
import '../localization/app_strings.dart';
import 'app_drawer.dart';
import 'search_screen.dart';
import 'forecast_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchWeatherForCurrentLocation();
      _maybeShowNamePrompt();
    });
  }

  Future<void> _maybeShowNamePrompt() async {
    final provider = context.read<WeatherProvider>();
    await provider.initialLoad;
    if (!mounted) return;
    if (provider.userName == null && !provider.hasPromptedForName) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const NamePromptDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: strings.menu,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded, size: 20),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(strings.appName,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: strings.searchCity,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_location_alt_outlined, size: 19),
            ),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(child: _WeatherBody()),
      ),
    );
  }
}

class _WeatherBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final strings = AppStrings.of(context);

    Widget content;
    switch (provider.status) {
      case WeatherStatus.initial:
        content = _MessageState(
            icon: Icons.wb_sunny_outlined,
            title: strings.noWeatherYet,
            message: strings.locationPrompt);
      case WeatherStatus.loading:
        content = _WeatherLoadingSkeleton(title: strings.fetchingWeather);
      case WeatherStatus.error:
        content = _MessageState(
          icon: Icons.cloud_off_outlined,
          title: strings.somethingWentWrong,
          message: strings.localizeError(provider.errorMessage),
          isError: true,
          onRetry: () => provider.fetchWeatherForCurrentLocation(),
        );
      case WeatherStatus.loaded:
        content = RefreshIndicator(
          color: AppColors.violet,
          backgroundColor: Colors.white,
          onRefresh: provider.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.huge),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.refreshErrorMessage != null)
                        _RefreshErrorBanner(
                            message: provider.refreshErrorMessage!),
                      const GreetingBanner(),
                      const SizedBox(height: AppSpacing.sm),
                      const CurrentWeatherCard(),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeading(
                          title: strings.hourlyForecast,
                          action: strings.next24Hours),
                      const SizedBox(height: AppSpacing.sm),
                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                        child:
                            HourlyForecastList(hourly: provider.hourlyForecast),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeading(
                          title: strings.fiveDayForecast,
                          action: strings.viewAll,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForecastScreen()))),
                      const SizedBox(height: AppSpacing.sm),
                      ForecastList(forecast: provider.forecast),
                    ]),
              ),
            ),
          ),
        );
    }

    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 450),
      reverse: false,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
          FadeThroughTransition(
        animation: primaryAnimation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Colors.transparent,
        child: child,
      ),
      child: KeyedSubtree(key: ValueKey(provider.status), child: content),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const _SectionHeading(
      {required this.title, required this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.violetDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800))),
        if (action != null)
          TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.violetDeep),
              child: Text(action!,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700))),
      ]);
}

class _WeatherLoadingSkeleton extends StatelessWidget {
  final String title;
  const _WeatherLoadingSkeleton({required this.title});

  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withValues(alpha: .45);
    final highlight = Colors.white.withValues(alpha: .82);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 180,
                    height: 18,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xxxl)),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                    children: List.generate(
                        5,
                        (index) => Expanded(
                                child: Container(
                              height: 120,
                              margin: EdgeInsets.only(
                                  right: index == 4 ? 0 : AppSpacing.sm),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xl)),
                            )))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  final String message;
  const _RefreshErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                size: 18, color: AppColors.violetDeep),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.violetDark, fontSize: 12)),
            ),
            IconButton(
              onPressed: () =>
                  context.read<WeatherProvider>().clearRefreshError(),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      );
}

class _MessageState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? message;
  final bool showSpinner;
  final bool isError;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
    this.onRetry,
  }) : showSpinner = false;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner)
                const CircularProgressIndicator()
              else if (icon != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .6),
                  ),
                  child: Icon(icon,
                      size: 36,
                      color: isError
                          ? Theme.of(context).colorScheme.error
                          : AppColors.violet),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.violetDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 17),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted)),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppStrings.of(context).tryAgain)),
              ],
            ],
          ),
        ),
      );
}

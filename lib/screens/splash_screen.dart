import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_logo.dart';
import '../providers/weather_provider.dart';
import '../localization/app_strings.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween(begin: const Offset(0, .08), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.wait([
      context.read<WeatherProvider>().initialLoad,
      Future.delayed(const Duration(milliseconds: 1900)),
    ]);
    if (!mounted) return;
    final provider = context.read<WeatherProvider>();
    final Widget next = provider.hasPromptedForName ? const HomeScreen() : const OnboardingScreen();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: next),
    ));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _slide,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const StartupWeatherMark(size: 172),
                  const SizedBox(height: 24),
                  Text(AppStrings.of(context).appName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.7)),
                  const SizedBox(height: 8),
                  Text(AppStrings.of(context).weatherMadeSimple, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 14)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

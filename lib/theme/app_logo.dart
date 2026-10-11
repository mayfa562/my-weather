import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'app_theme.dart';

/// The app's logo, built entirely from shapes and gradients rather
/// than an image asset — a warm gold sun glowing behind a soft white
/// cloud, on the violet brand palette.
///
/// Being widget-based (not a PNG/SVG file) means it scales perfectly
/// crisp at any size — the splash screen uses it large and animated,
/// but it could just as easily be dropped in small as an app-bar mark.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sun: a soft radial glow sitting behind and above center,
          // peeking out from the cloud like in the reference art.
          Positioned(
            top: size * 0.06,
            right: size * 0.08,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.sun,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.55),
                    blurRadius: size * 0.18,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          ),
          // Cloud: layered circles + a rounded rectangle base, all in
          // one gradient, which is the standard trick for drawing a
          // convincing "puffy cloud" silhouette without a custom path.
          Positioned(
            bottom: size * 0.14,
            child: SizedBox(
              width: size * 0.92,
              height: size * 0.52,
              child: Stack(
                children: [
                  _cloudPuff(left: 0, bottom: 0, diameter: size * 0.34),
                  _cloudPuff(left: size * 0.22, bottom: size * 0.10, diameter: size * 0.46),
                  _cloudPuff(left: size * 0.52, bottom: 0, diameter: size * 0.36),
                  Positioned(
                    left: size * 0.06,
                    right: size * 0.06,
                    bottom: 0,
                    child: Container(
                      height: size * 0.22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size * 0.16),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0xFFEDEBFB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violetDeep.withValues(alpha: 0.18),
                            blurRadius: size * 0.08,
                            offset: Offset(0, size * 0.03),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloudPuff({required double left, required double bottom, required double diameter}) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFEDEBFB)],
          ),
        ),
      ),
    );
  }
}


/// A dedicated startup visual using the same illustrated Lottie family as the
/// weather UI. It is intentionally calm and non-pulsating so it reads as a
/// brand mark rather than a loading indicator.
class StartupWeatherMark extends StatelessWidget {
  final double size;

  const StartupWeatherMark({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .18),
        border: Border.all(color: Colors.white.withValues(alpha: .34), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetDark.withValues(alpha: .22),
            blurRadius: size * .22,
            offset: Offset(0, size * .10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .18),
            blurRadius: size * .10,
            spreadRadius: size * .01,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .06),
      child: Lottie.asset(
        'assets/weather_icons/clear_day.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

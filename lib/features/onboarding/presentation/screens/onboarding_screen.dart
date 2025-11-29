import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:bridgecore_flutter_starter/core/storage/prefs_storage_service.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to BridgeCore",
          body: "Your complete business management solution powered by Odoo ERP",
          image: Center(
            child: Lottie.asset(
              'assets/lottie/welcome.json',
              width: 300,
              height: 300,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.business, size: 200, color: Colors.blue);
              },
            ),
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Offline First",
          body: "Work seamlessly even without internet connection. Your data syncs automatically when online.",
          image: Center(
            child: Lottie.asset(
              'assets/lottie/offline.json',
              width: 300,
              height: 300,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.cloud_off, size: 200, color: Colors.blue);
              },
            ),
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Real-time Updates",
          body: "Stay connected with real-time notifications and live data updates.",
          image: Center(
            child: Lottie.asset(
              'assets/lottie/realtime.json',
              width: 300,
              height: 300,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.sync, size: 200, color: Colors.blue);
              },
            ),
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Multi-Company Support",
          body: "Manage multiple companies with ease. Switch between companies seamlessly.",
          image: Center(
            child: Lottie.asset(
              'assets/lottie/company.json',
              width: 300,
              height: 300,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.business_center, size: 200, color: Colors.blue);
              },
            ),
          ),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Secure & Biometric",
          body: "Your data is secure with encryption and biometric authentication support.",
          image: Center(
            child: Lottie.asset(
              'assets/lottie/security.json',
              width: 300,
              height: 300,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.security, size: 200, color: Colors.blue);
              },
            ),
          ),
          decoration: _getPageDecoration(),
        ),
      ],
      onDone: () => _onDone(context),
      onSkip: () => _onDone(context),
      showSkipButton: true,
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: _getDotsDecorator(),
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  void _onDone(BuildContext context) async {
    await PrefsStorageService.instance.write(key: 'onboarding_completed', value: true);
    if (context.mounted) {
      context.go('/login');
    }
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: TextStyle(fontSize: 16.0),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.transparent,
      imagePadding: EdgeInsets.zero,
    );
  }

  DotsDecorator _getDotsDecorator() {
    return const DotsDecorator(
      size: Size(10.0, 10.0),
      color: Color(0xFFBDBDBD),
      activeSize: Size(22.0, 10.0),
      activeColor: Color(0xFF2196F3),
      activeShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
    );
  }
}

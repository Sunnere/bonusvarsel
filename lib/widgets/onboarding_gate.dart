import 'package:flutter/material.dart';

import '../pages/onboarding_page.dart';
import '../services/onboarding_service.dart';

class OnboardingGate extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPremiumSelected;
  final String? trumfUrl;
  final String? sasUrl;

  const OnboardingGate({
    super.key,
    required this.child,
    this.onPremiumSelected,
    this.trumfUrl,
    this.sasUrl,
  });

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _loading = true;
  bool _showOnboarding = false;

  static const Color _bgTop = Color(0xFF0B1F3A);
  static const Color _bgBottom = Color(0xFF08111E);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final completed = await OnboardingService.isCompleted();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !completed;
      _loading = false;
    });
  }

  Future<void> _handleDone() async {
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  Widget _brandedLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _gold.withValues(alpha: 0.28)),
                ),
                child: const Icon(Icons.workspace_premium, color: _gold, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bonusvarsel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(_gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _brandedLoadingScreen();
    }

    if (_showOnboarding) {
      return OnboardingPage(
        onDone: _handleDone,
        onPremiumSelected: widget.onPremiumSelected,
        trumfUrl: widget.trumfUrl,
        sasUrl: widget.sasUrl,
      );
    }

    return widget.child;
  }
}

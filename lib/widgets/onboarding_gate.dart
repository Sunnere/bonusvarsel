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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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

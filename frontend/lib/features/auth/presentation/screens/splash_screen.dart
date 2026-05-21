import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/screens/login_screen.dart';

import 'package:forja_trabajo/features/services/presentation/screens/layout/client_main_layout.dart';
import 'package:forja_trabajo/features/services/presentation/screens/layout/worker_main_layout.dart';
// admin_main_layout.dart fue eliminado — los admins solo usan el panel web

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _navigated = false;
  bool _minTimePassed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_animationController);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeIn)),
    );

    _animationController.forward();

    // Minimum time so the animation plays nicely
    Future.delayed(const Duration(milliseconds: 2200), () {
      _minTimePassed = true;
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Try to navigate only when BOTH conditions are met:
  /// 1. The minimum animation time has passed
  /// 2. The auth status is no longer 'initial' (token check finished)
  void _tryNavigate() {
    if (_navigated || !mounted) return;

    final authState = ref.read(authProvider);

    // If auth hasn't resolved yet, wait
    if (authState.status == 'initial') return;
    // If min time hasn't passed yet, wait
    if (!_minTimePassed) return;

    _navigated = true;

    if (authState.status == 'authenticated' && authState.user != null) {
      final user = authState.user!;
      Widget nextScreen;

      if (user.isWorker) {
        nextScreen = const WorkerMainLayout();
      } else if (user.isClient) {
        nextScreen = const ClientMainLayout();
      } else {
        nextScreen = const LoginScreen();
      }


      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👇 REACTIVELY watch authProvider — this rebuilds whenever the status changes
    final authState = ref.watch(authProvider);

    // Every time the auth state changes, attempt to navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.status != 'initial') {
        _tryNavigate();
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background subtle gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor
                        .withValues(alpha: isDark ? 0.15 : 0.08),
                    theme.scaffoldBackgroundColor,
                    AppTheme.primaryColor
                        .withValues(alpha: isDark ? 0.05 : 0.02),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Transform.rotate(
                    angle: 0.05,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.hammer,
                          color: Colors.white, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color ??
                            (isDark ? Colors.white : Colors.black),
                        letterSpacing: -0.5,
                      ),
                      children: const [
                        TextSpan(text: 'Forja'),
                        TextSpan(
                          text: 'Trabajo',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Loading spinner
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

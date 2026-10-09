import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../state/app_state.dart';
import '../customer/main_navigation_wrapper.dart';
import '../merchant/merchant_navigation_wrapper.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOutQuart)),
    );

    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    
    final appState = context.read<AppState>();
    
    Widget nextScreen;
    if (appState.isLoggedIn) {
      if (appState.currentUser?.type == 'merchant') {
        nextScreen = const MerchantNavigationWrapper();
      } else {
        nextScreen = const MainNavigationWrapper();
      }
    } else {
      nextScreen = const AuthScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect system brightness dynamically
    final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Apply correct status bar style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isSystemDark ? Brightness.light : Brightness.dark,
    ));

    final bgColor = isSystemDark ? AppColors.matteBlack : Colors.white;
    final subtitleColor = isSystemDark 
        ? AppColors.primaryGold.withOpacity(0.6) 
        : AppColors.primaryGold.withOpacity(0.8);
    final versionColor = isSystemDark ? Colors.white24 : Colors.black26;
    final designerColor = isSystemDark ? Colors.white38 : Colors.black45;
    final dividerColor = isSystemDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Subtle Glow in background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withOpacity(isSystemDark ? 0.05 : 0.08),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGold, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(isSystemDark ? 0.1 : 0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: ClipOval(
                          child: Image.asset(
                            AppConstants.logoPlaceholder,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              AppConstants.appNameAr,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "مجوهرات فاخرة لأذواق رفيعة",
                              style: GoogleFonts.cairo(
                                color: subtitleColor,
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Version & Designer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'الإصدار 1.0.0',
                    style: GoogleFonts.cairo(
                      color: versionColor,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 0.5, width: 20, color: dividerColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'تصميم متجوهراتي',
                          style: GoogleFonts.cairo(
                            color: designerColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Container(height: 0.5, width: 20, color: dividerColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

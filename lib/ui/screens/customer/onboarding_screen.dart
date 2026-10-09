import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingItems = [
    OnboardingData(
      title: "أهلاً بك في عالم الفخامة",
      subtitle: "اكتشف أرقى تصاميم المجوهرات والذهب التي تليق بمناسباتك الخاصة",
      icon: Icons.auto_awesome_rounded,
    ),
    OnboardingData(
      title: "تجربة القياس الافتراضي",
      subtitle: "جرب الخواتم والمجوهرات مباشرة من هاتفك باستخدام تقنية الواقع المعزز",
      icon: Icons.camera_front_rounded,
    ),
    OnboardingData(
      title: "حاسبة الزكاة الذكية",
      subtitle: "احسب زكاة ذهبك بكل سهولة ودقة وفقاً للأسعار العالمية المحدثة",
      icon: Icons.calculate_rounded,
    ),
    OnboardingData(
      title: "الدفع عند الاستلام",
      subtitle: "تسوق بكل ثقة وراحة بال، وادفع فقط عند استلام قطعتك الثمينة",
      icon: Icons.payments_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.premiumBlack, AppColors.royalBlack],
              ),
            ),
          ),
          
          // Animated Mesh Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withOpacity(0.05),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(1, 1), 
              end: const Offset(1.2, 1.2), 
              duration: 5.seconds, 
              curve: Curves.easeInOut
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (v) => setState(() => _currentPage = v),
            itemCount: _onboardingItems.length,
            itemBuilder: (context, index) {
              return _buildPage(_onboardingItems[index]);
            },
          ),

          // Navigation Overlay
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_onboardingItems.length, (index) {
                    return AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primaryGold : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                
                // Button
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: InkWell(
                      onTap: () {
                        if (_currentPage < _onboardingItems.length - 1) {
                          _pageController.nextPage(duration: 500.ms, curve: Curves.easeOutQuart);
                        } else {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                        }
                      },
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGold.withOpacity(0.3),
                              AppColors.primaryGold.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _currentPage == _onboardingItems.length - 1 ? "ابدأ الآن" : "التالي",
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryGold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().shimmer(delay: 2.seconds, duration: 2.seconds),
                
                if (_currentPage < _onboardingItems.length - 1)
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                    },
                    child: Text(
                      "تخطي",
                      style: GoogleFonts.cairo(color: Colors.white38),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData item) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glassy Icon Container
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGold.withOpacity(0.05),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.1)),
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 100,
                color: AppColors.primaryGold,
              ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0, end: 0.05, duration: 2.seconds),
          
          const SizedBox(height: 60),
          
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms).fadeIn(),
          
          const SizedBox(height: 20),
          
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.white70,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;

  OnboardingData({required this.title, required this.subtitle, required this.icon});
}

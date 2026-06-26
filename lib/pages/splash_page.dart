import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../app/router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          // ← ADD Stack
          children: [
            // ── decorative BG SVG ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.40,
                child: SizedBox(
                  height: screenHeight * 0.35,
                  width: double.infinity,
                  child: SvgPicture.asset(
                    'assets/svg/splashbg.svg',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.03),

                  // ── Logo ──────────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/letterlogo.svg',
                          width: screenWidth * 0.18,
                          height: screenWidth * 0.18,
                          fit: BoxFit.contain,
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.7, 0.7)),
                        SizedBox(height: screenHeight * 0.012),
                        Text(
                          AppStrings.tagline,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // ── Carousel — driven by AppStrings.splashSlides ─────────────
                  Expanded(
                    flex: 5,
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: AppStrings.splashSlides.length,
                      itemBuilder: (context, i) =>
                          _SlideCard(data: AppStrings.splashSlides[i]),
                    ),
                  ),

                  // ── Page indicator ────────────────────────────────────────────
                  SmoothPageIndicator(
                    controller: _controller,
                    count: AppStrings.splashSlides.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.mediumBlue,
                      dotColor: AppColors.lightBlue,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // ── CTA buttons ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: 'Get Started',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => context.go(AppRoutes.register),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                        SizedBox(height: screenHeight * 0.012),
                        SecondaryButton(
                          label: 'Log In',
                          onPressed: () => context.go(AppRoutes.login),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide Card ───────────────────────────────────────────────────────────────

class _SlideCard extends StatelessWidget {
  /// Expects a map with keys: 'title', 'subtitle', 'vector'
  /// matching the shape defined in AppStrings.splashSlides.
  final Map<String, String> data;
  const _SlideCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final vectorPath = data['vector'] ?? '';
    final size = MediaQuery.of(context).size;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG illustration
          SizedBox(
            width: screenHeight * 0.28,
            height: screenHeight * 0.28,
            child: vectorPath.isNotEmpty
                ? vectorPath.endsWith('.png')
                    ? Image.asset(vectorPath, fit: BoxFit.contain)
                    : SvgPicture.asset(
                        vectorPath,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => const Icon(
                          Icons.image_not_supported_outlined,
                          size: 80,
                          color: AppColors.lightBlue,
                        ),
                      )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 28),

          Text(
            data['title'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.065,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBlue,
            ),
          ),

          SizedBox(height: screenHeight * 0.012),

          Text(
            data['subtitle'] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

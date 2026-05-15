import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../data/models/auth_models.dart';
import '../data/services/auth_service.dart';
import '../widgets/shared_widgets.dart';
import '../../app/router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  // login_page.dart - only _login() changes, everything else stays identical

  String? _errorMessage;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      await authService.login(
        LoginRequest(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        ),
      );
      if (!mounted) return;
      context.go(AppRoutes.home);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // darkens background
      barrierDismissible: true, // disappears when outside is clicked
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFECF3FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E7BB6).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: Color(0xFF4E7BB6),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Are you sure?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4E7BB6),
                ),
              ),
              const SizedBox(height: 10),
              // Description
              Text(
                'By clicking confirm, we will send you a verification email to change your password.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF4E7BB6).withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4E7BB6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4E7BB6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // TODO: call your forgot password API here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password reset email sent!',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            backgroundColor: const Color(0xFF4E7BB6),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4E7BB6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        child: Stack(
          children: [
            // ── decorative BG SVG ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.50,
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: SvgPicture.asset(
                    'assets/svg/splashbg.svg',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Back
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.splash),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusS),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: AppColors.darkBlue),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text('Welcome back',
                              style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkBlue))
                          .animate()
                          .fadeIn()
                          .slideX(begin: -0.2),
                      const SizedBox(height: 6),
                      Text('Log in to your ShelfLife account',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: AppColors.textSecondary))
                          .animate()
                          .fadeIn(delay: 100.ms),
                      const SizedBox(height: 36),
                      // Email field
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email or Username',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      // Password field
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 8),
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text('Forgot password?',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.mediumBlue)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.expired.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusS),
                            border: Border.all(color: AppColors.expired.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.expired, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.expired,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      PrimaryButton(
                        label: 'Log In',
                        onPressed: _login,
                        isLoading: _loading,
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 24),
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.register),
                            child: Text('Sign up',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mediumBlue)),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



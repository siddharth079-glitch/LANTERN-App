import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/glossy_button.dart';
import '../../../shared/widgets/lantern_brand.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController(text: '9876543210');
  final _passwordController = TextEditingController(text: '••••••••');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LanternColors.cosmic,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Center Logo
              const Center(
                child: LanternWordmark(fontSize: 26, emblemSize: 32),
              ),
              const SizedBox(height: 36),

              // Title & Subtitle
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to continue',
                style: TextStyle(
                  color: LanternColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              // Phone Number Label & Input
              Text(
                'Phone Number',
                style: TextStyle(
                  color: LanternColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: LanternColors.glassDefault,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LanternColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: LanternColors.glassBorder)),
                      ),
                      child: const Row(
                        children: [
                          Text('🇮🇳', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text(
                            '+91',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter number',
                          hintStyle: TextStyle(color: LanternColors.textMuted, fontSize: 13.5),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Password Label & Input
              Text(
                'Password',
                style: TextStyle(
                  color: LanternColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: LanternColors.glassDefault,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LanternColors.glassBorder),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: TextStyle(color: LanternColors.textMuted, fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: LanternColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button (Glossy Red)
              GlossyButton(
                label: 'Login',
                variant: GlossyButtonVariant.emergency,
                fullWidth: true,
                height: 50,
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 22),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or', style: TextStyle(color: LanternColors.textMuted, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                ],
              ),
              const SizedBox(height: 20),

              // Google Auth Button
              _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                iconSize: 26,
                label: 'Continue with Google',
                onTap: widget.onLoginSuccess,
              ),
              const SizedBox(height: 12),

              // OTP Auth Button
              _buildSocialButton(
                icon: Icons.sms_outlined,
                iconSize: 18,
                label: 'Continue with Mobile OTP',
                onTap: widget.onLoginSuccess,
              ),
              const SizedBox(height: 32),

              // Sign Up Footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: LanternColors.textSecondary, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: widget.onLoginSuccess,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: LanternColors.primaryBlueHover,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required double iconSize,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: LanternColors.glassDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LanternColors.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

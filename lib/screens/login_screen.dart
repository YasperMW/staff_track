import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_provider.dart';
import '../services/otp_service.dart';
import '../services/google_auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'google_signup_screen.dart';
import '../widgets/app_snackbar.dart';
import '../controllers/register_controller.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleAuthService = GoogleAuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Check if the error is related to email verification
        if (result.code == 'email_not_verified') {
          // Send OTP before redirecting
          await OTPService.sendOTP(
            email: _emailController.text,
            purpose: 'registration',
          );
          
          if (!mounted) return;
          // Redirect to OTP verification screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                email: _emailController.text,
                purpose: 'registration',
              ),
            ),
          );
        } else {
          AppSnackBar.showError(
            context,
            result.message ?? 'Invalid credentials.',
          );
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      // Sign in with Google
      final account = await _googleAuthService.signInWithGoogle();
      if (account == null) {
        if (mounted) {
          AppSnackBar.showError(context, 'Google sign-in was cancelled');
        }
        return;
      }

      // Get ID token
      final idToken = await _googleAuthService.getIdToken();
      if (idToken == null) {
        if (mounted) {
          AppSnackBar.showError(context, 'Failed to get Google authentication');
        }
        return;
      }

      // Check if user exists in backend
      final response = await _googleAuthService.checkGoogleUser(idToken);

      if (!mounted) return;

      if (response.success) {
        if (response.exists) {
          // User exists - log them in
          if (response.token != null) {
            final authProvider = context.read<AuthProvider>();
            await authProvider.saveToken(response.token!, response.user ?? {});

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // New user - navigate to Google signup screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GoogleSignupScreen(
                googleData: response.googleData ?? {},
                idToken: idToken,
              ),
            ),
          );
        }
      } else {
        AppSnackBar.showError(context, response.message ?? 'Google sign-in failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'An error occurred during Google sign-in');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Widget _buildGoogleSignInButton(ThemeData theme, bool isShort) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4285F4), // Google Blue
            Color(0xFFDB4437), // Google Red
            Color(0xFFF4B400), // Google Yellow
            Color(0xFF0F9D58), // Google Green
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Google "G" Logo with brand colors
                const _GoogleLogoWidget(size: 24),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _isGoogleLoading ? 'Signing in…' : 'Sign in with Google',
                    key: ValueKey<bool>(_isGoogleLoading),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _isGoogleLoading
                      ? const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4285F4)),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withValues(alpha: 0.8),
                  ]
                : [
                    AppTheme.skyBlue,
                    AppTheme.darkSkyBlue,
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double height = constraints.maxHeight;
              // Increased threshold to be more aggressive with shrinking
              final bool isShort = height < 820;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: height,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isShort ? 12 : 32),
                          // Logo/Icon section
                          TweenAnimationBuilder<double>(
                            duration: const Duration(seconds: 1),
                            tween: Tween(begin: 0, end: 1),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isShort ? 12 : 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.local_hospital_rounded,
                                    size: isShort ? 40 : 70,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: isShort ? 8 : 24),
                                Text(
                                  'Staff Track',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isShort ? 28 : 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                if (!isShort) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Smart Staff Management',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: isShort ? 16 : 40),
                          // Login Form Card
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0, end: 1),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 50 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(isShort ? 20 : 32),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: (isShort
                                              ? theme.textTheme.titleLarge
                                              : theme.textTheme.headlineSmall)
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Enter your credentials to continue',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    SizedBox(height: isShort ? 12 : 32),
                                    TextFormField(
                                      controller: _emailController,
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon:
                                            const Icon(Icons.email_outlined),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.grey.withValues(alpha: 0.05),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: TextStyle(
                                          color: theme.colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(
                                            Icons.lock_outline_rounded),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.grey.withValues(alpha: 0.05),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: isShort ? 4 : 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const ForgotPasswordScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isShort ? 8 : 24),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                        shadowColor: theme.colorScheme.primary
                                            .withValues(alpha: 0.4),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'SIGN IN',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                    SizedBox(height: isShort ? 12 : 20),
                                    // Google Sign In Button
                                    _buildGoogleSignInButton(theme, isShort),
                                    SizedBox(height: isShort ? 8 : 16),
                                    // Divider with "or"
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'or',
                                            style: TextStyle(
                                              color: theme.colorScheme.outline,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isShort ? 4 : 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                  create: (_) =>
                                                      RegisterController(),
                                                  child:
                                                      const RegisterScreen(),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Register',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Only use Spacer if there's significant room to spare
                          if (!isShort) const SizedBox(height: 24),
                          // Footer info
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: 16, top: isShort ? 12 : 16),
                            child: Text(
                              'v1.0.0 • St Johns Hospital',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Google logo widget with brand colors
class _GoogleLogoWidget extends StatelessWidget {
  final double size;

  const _GoogleLogoWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Custom painter for Google "G" logo with brand colors
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final strokeWidth = 2.5;

    // Google brand colors
    const googleBlue = Color(0xFF4285F4);
    const googleRed = Color(0xFFDB4437);
    const googleYellow = Color(0xFFF4B400);
    const googleGreen = Color(0xFF0F9D58);

    // Draw the "G" logo with Google brand colors
    // Blue arc (top-right to right)
    final bluePaint = Paint()
      ..color = googleBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
      -0.7,
      1.3,
      false,
      bluePaint,
    );

    // Red arc (top-left)
    final redPaint = Paint()
      ..color = googleRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
      2.4,
      0.8,
      false,
      redPaint,
    );

    // Yellow arc (left)
    final yellowPaint = Paint()
      ..color = googleYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
      3.2,
      1.0,
      false,
      yellowPaint,
    );

    // Green arc (bottom)
    final greenPaint = Paint()
      ..color = googleGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
      4.2,
      1.3,
      false,
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

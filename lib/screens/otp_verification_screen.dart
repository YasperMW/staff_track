import 'dart:async';
import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'registration' or 'password_reset'
  
  const OTPVerificationScreen({
    super.key,
    required this.email,
    this.purpose = 'registration',
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6, 
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6, 
    (index) => FocusNode(),
  );
  
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  StreamSubscription<int>? _cooldownSubscription;
  
  @override
  void initState() {
    super.initState();
    // Auto-focus first OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }
  
  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _cooldownSubscription?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join('');
  }
  
  void _onOTPChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-submit when all fields are filled
    if (_getOTPCode().length == 6) {
      _verifyOTP();
    }
  }
  
  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await OTPService.verifyOTP(
        email: widget.email,
        otpCode: _getOTPCode(),
        purpose: widget.purpose,
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (response['success']) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(response['message'] ?? 'OTP verification failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Network error. Please try again.');
      }
    }
  }
  
  Future<void> _resendOTP() async {
    if (_resendCooldown > 0) return;
    
    setState(() => _isResending = true);
    
    try {
      final response = await OTPService.sendOTP(
        email: widget.email,
        purpose: widget.purpose,
      );
      
      if (mounted) {
        setState(() => _isResending = false);
        
        if (response['success']) {
          _showResendSuccessDialog();
          _startResendCooldown();
        } else {
          _showErrorDialog(response['message'] ?? 'Failed to resend OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        _showErrorDialog('Network error. Please try again.');
      }
    }
  }
  
  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    
    _cooldownSubscription = Stream.periodic(const Duration(seconds: 1), (count) {
      if (_resendCooldown > 0 && mounted) {
        setState(() => _resendCooldown--);
      } else {
        _cooldownSubscription?.cancel();
      }
      return count;
    }).listen((_) {});
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          widget.purpose == 'registration' ? 'Email Verified!' : 'OTP Verified!',
        ),
        content: Text(
          widget.purpose == 'registration' 
              ? 'Your email has been verified successfully. You can now login.'
              : 'Your OTP has been verified successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }
  
  void _showResendSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OTP Resent'),
        content: Text('A new OTP has been sent to ${widget.email}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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
                    AppTheme.primaryBlue,
                    AppTheme.secondaryBlue,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(theme),
                const SizedBox(height: 40),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildTitle(theme),
                            const SizedBox(height: 24),
                            _buildOTPFields(theme),
                            const SizedBox(height: 24),
                            _buildVerifyButton(theme),
                            const SizedBox(height: 16),
                            _buildResendSection(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VERIFY EMAIL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter the 6-digit code sent to your email',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTitle(ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 48,
          color: AppTheme.primaryBlue,
        ),
        const SizedBox(height: 12),
        Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to ${widget.email}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildOTPFields(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 35,
          height: 45,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              // Only allow digits
              if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
                _otpControllers[index].clear();
                return;
              }
              _onOTPChanged(value, index);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '';
              }
              return null;
            },
          ),
        );
      }),
    );
  }
  
  Widget _buildVerifyButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Verifying...'),
                ],
              )
            : const Text(
                'Verify Email',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
  
  Widget _buildResendSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Didn\'t receive the code?',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (_resendCooldown > 0)
          Text(
            'Resend available in $_resendCooldown seconds',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          TextButton(
            onPressed: _isResending ? null : _resendOTP,
            child: _isResending
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Resending...'),
                    ],
                  )
                : Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
      ],
    );
  }
}

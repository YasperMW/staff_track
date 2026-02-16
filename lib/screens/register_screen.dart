import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/register_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final RegisterService _registerService = RegisterService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers for form fields
  final _employeeNumberController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _suffixController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _surNameController = TextEditingController();
  final _otherNamesController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeOfOriginController = TextEditingController();
  final _traditionalAuthorityController = TextEditingController();
  final _districtController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _spouseNameController = TextEditingController();
  final _spouseContactController = TextEditingController();
  final _dateOfEmploymentController = TextEditingController();
  final _yearsInServiceController = TextEditingController();
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;
  String? _selectedDepartment;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  bool _isHeadOfDepartment = false;

  @override
  void dispose() {
    _pageController.dispose();
    _employeeNumberController.dispose();
    _nationalIdController.dispose();
    _suffixController.dispose();
    _firstNameController.dispose();
    _surNameController.dispose();
    _otherNamesController.dispose();
    _dateOfBirthController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _homeOfOriginController.dispose();
    _traditionalAuthorityController.dispose();
    _districtController.dispose();
    _currentAddressController.dispose();
    _spouseNameController.dispose();
    _spouseContactController.dispose();
    _dateOfEmploymentController.dispose();
    _yearsInServiceController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitRegistration();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final response = await _registerService.register(
      employeeNumber: _employeeNumberController.text,
      nationalId: _nationalIdController.text,
      suffix: _suffixController.text,
      firstName: _firstNameController.text,
      surName: _surNameController.text,
      otherNames: _otherNamesController.text,
      dateOfBirth: _dateOfBirthController.text,
      gender: _selectedGender!,
      email: _emailController.text,
      phone: _phoneController.text,
      homeOfOrigin: _homeOfOriginController.text,
      traditionalAuthority: _traditionalAuthorityController.text,
      district: _districtController.text,
      currentAddress: _currentAddressController.text,
      maritalStatus: _selectedMaritalStatus!,
      spouseName: _spouseNameController.text,
      spouseContact: _spouseContactController.text,
      dateOfEmployment: _dateOfEmploymentController.text,
      yearsInService: _yearsInServiceController.text,
      designation: _designationController.text,
      role: _selectedRole!,
      department: _selectedDepartment!,
      isHeadOfDepartment: _isHeadOfDepartment,
      password: _passwordController.text,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (response.success) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: Text(
              response.message ?? 'Your account has been created and is pending HR approval. You will be notified once activated.',
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
      } else {
        // Show error dialog with specific error message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(
              response.message ?? 'Registration failed. Please try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
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
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
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
                    child: Column(
                      children: [
                        _buildStepIndicator(),
                        const SizedBox(height: 32),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (int page) {
                              setState(() => _currentStep = page);
                            },
                            children: [
                              _buildPersonalDetailsStep(theme),
                              _buildLocationStep(theme),
                              _buildFamilyDetailsStep(theme),
                              _buildWorkDetailsStep(theme),
                              _buildSecurityStep(theme),
                              _buildProfileStep(theme),
                            ],
                          ),
                        ),
                        _buildNavigationButtons(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Join ST JOHN\'S HOSPITAL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(5, (index) {
        bool isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWorkDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Work Information', 'Enter your hospital employment details'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _employeeNumberController,
            label: 'Employee Number',
            icon: Icons.badge_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nationalIdController,
            label: 'National ID / Passport',
            icon: Icons.credit_card_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _designationController,
            label: 'Designation',
            icon: Icons.work_outline,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dateOfEmploymentController,
            label: 'Date of Employment',
            icon: Icons.calendar_today_outlined,
            theme: theme,
            keyboardType: TextInputType.datetime,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365)),
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _dateOfEmploymentController.text = date.toIso8601String().split('T')[0];
                // Auto-calculate years in service
                final years = DateTime.now().difference(date).inDays / 365;
                _yearsInServiceController.text = years.floor().toString();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _yearsInServiceController,
            label: 'Years in Service',
            icon: Icons.timeline_outlined,
            theme: theme,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Department',
            icon: Icons.apartment_outlined,
            items: _registerService.getDepartments(),
            value: _selectedDepartment,
            onChanged: (val) => setState(() => _selectedDepartment = val),
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Role',
            icon: Icons.work_outline,
            items: _registerService.getRoles(),
            value: _selectedRole,
            onChanged: (val) => setState(() => _selectedRole = val),
            theme: theme,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('I am the Head of Department'),
            subtitle: const Text('Check if you are the HOD for this department'),
            value: _isHeadOfDepartment,
            onChanged: (val) => setState(() => _isHeadOfDepartment = val ?? false),
            activeColor: AppTheme.primaryBlue,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Personal Details',
            'Tell us more about yourself',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _suffixController,
                  label: 'Suffix',
                  icon: Icons.person_outline,
                  theme: theme,
                  isRequired: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _surNameController,
            label: 'Surname',
            icon: Icons.person_outline,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _otherNamesController,
            label: 'Other Names',
            icon: Icons.person_outline,
            theme: theme,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dateOfBirthController,
            label: 'Date of Birth',
            icon: Icons.cake_outlined,
            theme: theme,
            keyboardType: TextInputType.datetime,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 70)),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              );
              if (date != null) {
                _dateOfBirthController.text = date.toIso8601String().split('T')[0];
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Gender',
            icon: Icons.person_outline,
            items: const ['male', 'female', 'other'],
            value: _selectedGender,
            onChanged: (val) => setState(() => _selectedGender = val),
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Contact Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Security', 'Create a strong password for your account'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_reset_outlined,
            isPassword: true,
            theme: theme,
            customValidator: (value) {
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Location Information',
            'Tell us where you are based',
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _homeOfOriginController,
            label: 'Home of Origin',
            icon: Icons.home_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _traditionalAuthorityController,
            label: 'Traditional Authority',
            icon: Icons.account_balance_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _districtController,
            label: 'District',
            icon: Icons.location_city_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _currentAddressController,
            label: 'Current Address',
            icon: Icons.place_outlined,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Family Information',
            'Capture your family and spouse details',
          ),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Marital Status',
            icon: Icons.family_restroom_outlined,
            items: const ['single', 'married', 'divorced', 'widowed'],
            value: _selectedMaritalStatus,
            onChanged: (val) => setState(() => _selectedMaritalStatus = val),
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _spouseNameController,
            label: 'Spouse Name (optional)',
            icon: Icons.person_outline,
            theme: theme,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _spouseContactController,
            label: 'Spouse Contact (optional)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            theme: theme,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepTitle('Profile Picture', 'Upload or take a selfie for identification'),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () {
              // In a real app, this would open image picker/camera
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera/Gallery would open here')),
              );
            },
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 50,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Please ensure your face is clearly visible\nin the photo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
    TextInputType? keyboardType,
    bool isRequired = true,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        filled: true,
        fillColor: theme.brightness == Brightness.dark
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
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
      ),
      validator: (value) {
        final custom = customValidator?.call(value);
        if (custom != null) return custom;
        if (!isRequired && (value == null || value.isEmpty)) return null;
        if (value == null || value.isEmpty) return 'This field is required';
        if (isPassword && value.length < 6) return 'Password too short';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required ThemeData theme,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (val) => val == null ? 'Please select $label' : null,
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: AppTheme.primaryBlue),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_currentStep == 4 ? 'Complete Registration' : 'Next Step'),
            ),
          ),
        ],
      ),
    );
  }
}

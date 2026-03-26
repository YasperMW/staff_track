
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../controllers/register_controller.dart';
import '../services/image_service.dart';
import '../services/lookup_service.dart';
import '../widgets/single_date_picker.dart';
import '../../theme/app_theme.dart';
import '../config/app_config.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showScrollHint = false;

  // API data
  List<String> _roles = [];
  List<Department> _departments = [];
  List<Grade> _grades = [];

  List<String> _designationNames = [];
  bool _isLoadingLookupData = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadLookupData();
  }

  Future<void> _loadLookupData() async {
    try {
      final roles = await LookupService.getRoles();
      final departments = await LookupService.getDepartments();
      final grades = await LookupService.getGrades();
      
      setState(() {
        _roles = roles.map((role) => role.name).toList();
        _departments = departments;
        _grades = grades;
        _selectedRole = _roles.isNotEmpty ? _roles.first : null;
        _selectedDepartment = _departments.isNotEmpty ? _departments.first.name : null;
        _selectedDepartmentId = _departments.isNotEmpty ? _departments.first.departmentId : null;
        if (kDebugMode) {
          print('Loaded ${departments.length} departments');
          for (var dept in departments) {
            print('Department: ${dept.name} -> ID: ${dept.departmentId}');
          }
          print('Selected department ID: $_selectedDepartmentId');
        }
        _selectedGrade = _grades.isNotEmpty ? _grades.first.id : null;
        _isLoadingLookupData = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading lookup data: $e');
      }
      setState(() {
        _isLoadingLookupData = false;
      });
    }
  }

  void _updateDesignations(String? departmentName) {
    if (departmentName != null) {
      // Find department and get its designations from already loaded data
      final selectedDept = _departments.firstWhere(
        (dept) => dept.name == departmentName,
        orElse: () => Department(
          departmentId: '',
          name: departmentName,
          designations: [],
          createdAt: '',
        ),
      );
      
      setState(() {
        _designationNames = selectedDept.designations;
        // Set designation to first available if current value is not in the list or is empty
        if (_designationController.text.isEmpty || 
            !_designationNames.contains(_designationController.text)) {
          _designationController.text = _designationNames.isNotEmpty ? _designationNames.first : '';
        }
      });
    }
  }

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
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;
  String? _selectedDepartment;
  String? _selectedDepartmentId;
  String? _selectedGrade;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  final bool _isHeadOfDepartment = false;
  String? _profilePhotoPath;
  String? _profilePhotoUrl;

  void _scrollListener() {
    if (_scrollController.hasClients) {
      // If we are near the bottom, hide the hint
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 20) {
        if (_showScrollHint) setState(() => _showScrollHint = false);
      } else {
        if (!_showScrollHint) setState(() => _showScrollHint = true);
      }
    }
  }

  void _checkScrollNeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final bool needsScroll = _scrollController.position.maxScrollExtent > 0;
        setState(() => _showScrollHint = needsScroll);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
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
    _designationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _checkScrollNeed();
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
      _checkScrollNeed();
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final controller = context.read<RegisterController>();

    controller
      ..updateEmployeeNumber(_employeeNumberController.text)
      ..updateNationalId(_nationalIdController.text)
      ..updateSuffix(_suffixController.text)
      ..updateFirstName(_firstNameController.text)
      ..updateSurName(_surNameController.text)
      ..updateOtherNames(_otherNamesController.text)
      ..updateDateOfBirth(_dateOfBirthController.text)
      ..updateGender(_selectedGender ?? '')
      ..updateEmail(_emailController.text)
      ..updatePhone(_phoneController.text)
      ..updateHomeOfOrigin(_homeOfOriginController.text)
      ..updateTraditionalAuthority(_traditionalAuthorityController.text)
      ..updateDistrict(_districtController.text)
      ..updateCurrentAddress(_currentAddressController.text)
      ..updateMaritalStatus(_selectedMaritalStatus ?? '')
      ..updateSpouseName(_spouseNameController.text)
      ..updateSpouseContact(_spouseContactController.text)
      ..updateDateOfEmployment(_dateOfEmploymentController.text)
      ..updateDesignationId(_designationController.text)
      ..updateRole(_selectedRole ?? '')
      ..updateDepartment(_selectedDepartment ?? '')
      ..updateDepartmentId(_selectedDepartmentId ?? '')
      ..updateIsHeadOfDepartment(_isHeadOfDepartment)
      ..updatePassword(_passwordController.text)
      ..updateConfirmPassword(_confirmPasswordController.text)
      ..updateGradeId(_selectedGrade)
      ..updateProfilePhotoUrl(null); // Will be uploaded after OTP verification

    final response = await controller.register();
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (response.success) {
        // Store the image path for later upload after OTP verification
        String? pendingImagePath = _profilePhotoPath;
        
        // Show message about profile photo
        if (pendingImagePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Profile photo will be uploaded after verification.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Redirect to OTP verification screen with pending image path
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              email: _emailController.text,
              purpose: 'registration',
              pendingImagePath: pendingImagePath,
            ),
          ),
          (route) => false,
        );
      } else {
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
                    AppTheme.skyBlue,
                    AppTheme.darkSkyBlue,
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
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (int page) {
                                  setState(() => _currentStep = page);
                                  _checkScrollNeed();
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
                              if (_showScrollHint)
                                _buildScrollHint(theme),
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

  Widget _buildScrollHint(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_double_arrow_down_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Scroll for more',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
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
                'Join ST JOHN\'S HOSPITAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Create account',
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
      children: List.generate(6, (index) {
        bool isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.skyBlue
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPersonalDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      controller: _currentStep == 0 ? _scrollController : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Personal Details', 'Basic identification information'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _suffixController,
            label: 'Suffix',
            icon: Icons.title_outlined,
            theme: theme,
            isRequired: false,
            hint: 'Dr/Mr/Ms',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person_outline,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _surNameController,
            label: 'Surname',
            icon: Icons.person_pin_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _otherNamesController,
            label: 'Other Names',
            icon: Icons.people_outline,
            theme: theme,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dateOfBirthController,
            label: 'Date of Birth',
            icon: Icons.cake_outlined,
            theme: theme,
            readOnly: true,
            onTap: () async {
              final date = await showSingleDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 70)),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                title: 'Select Date of Birth',
              );
              if (date != null) {
                _dateOfBirthController.text = date.toIso8601String().split('T')[0];
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Gender',
            icon: Icons.wc_outlined,
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
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            theme: theme,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLocationStep(ThemeData theme) {
    return SingleChildScrollView(
      controller: _currentStep == 1 ? _scrollController : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Location Information', 'Residential and origin details'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _homeOfOriginController,
            label: 'Home of Origin',
            icon: Icons.home_work_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _traditionalAuthorityController,
            label: 'Traditional Authority',
            icon: Icons.gavel_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _districtController,
            label: 'District',
            icon: Icons.map_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _currentAddressController,
            label: 'Current Address',
            icon: Icons.location_on_outlined,
            theme: theme,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFamilyDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      controller: _currentStep == 2 ? _scrollController : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Family Information', 'Marital and emergency contact'),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Marital Status',
            icon: Icons.favorite_border_outlined,
            items: const ['single', 'married', 'divorced', 'widowed'],
            value: _selectedMaritalStatus,
            onChanged: (val) {
              setState(() => _selectedMaritalStatus = val);
              _checkScrollNeed();
            },
            theme: theme,
          ),
          if (_selectedMaritalStatus == 'married') ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _spouseNameController,
              label: 'Spouse Full Name',
              icon: Icons.person_pin_outlined,
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _spouseContactController,
              label: 'Spouse Contact',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              theme: theme,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWorkDetailsStep(ThemeData theme) {
    return SingleChildScrollView(
      controller: _currentStep == 3 ? _scrollController : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Work Information', 'Hospital employment details'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _employeeNumberController,
            label: 'Employee ID',
            icon: Icons.badge_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nationalIdController,
            label: 'National ID',
            icon: Icons.credit_card_outlined,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dateOfEmploymentController,
            label: 'Employment Date',
            icon: Icons.calendar_month_outlined,
            theme: theme,
            readOnly: true,
            onTap: () async {
              final date = await showSingleDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365)),
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
                lastDate: DateTime.now(),
                title: 'Select Employment Date',
              );
              if (date != null) {
                _dateOfEmploymentController.text = date.toIso8601String().split('T')[0];
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Department',
            icon: Icons.corporate_fare_outlined,
            items: _isLoadingLookupData ? ['Loading...'] : _departments.map((d) => d.name).toList(),
            value: _isLoadingLookupData ? null : _selectedDepartment,
            onChanged: (String? value) {
              setState(() {
                _selectedDepartment = value;
                if (value != null) {
                  // Find department and get its ID and designations
                  final selectedDept = _departments.firstWhere(
                    (dept) => dept.name == value,
                    orElse: () => Department(
                      departmentId: '',
                      name: value,
                      designations: [],
                      createdAt: '',
                    ),
                  );
                  _selectedDepartmentId = selectedDept.departmentId;
                  if (kDebugMode) {
                    print('Selected department: $value');
                    print('Department ID: $_selectedDepartmentId');
                    print('Department object: ${selectedDept.departmentId}');
                  }
                  // Update designations based on selected department
                  _updateDesignations(value);
                }
              });
            },
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Designation / Job Title',
            icon: Icons.work_history_outlined,
            items: _designationNames.isNotEmpty ? _designationNames : ['Select department first'],
            value: _designationNames.isNotEmpty && _designationNames.contains(_designationController.text) 
                ? _designationController.text 
                : (_designationNames.isNotEmpty ? _designationNames.first : null),
            onChanged: (val) {
              _designationController.text = val ?? '';
            },
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Role',
            icon: Icons.account_tree_outlined,
            items: _isLoadingLookupData ? ['Loading...'] : _roles,
            value: _isLoadingLookupData ? null : _selectedRole,
            onChanged: (val) => setState(() => _selectedRole = val),
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildGradeDropdown(theme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGradeDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGrade,
      items: _grades.map((Grade g) {
        return DropdownMenuItem<String>(
          value: g.id,
          child: Text('${g.name} (${g.annualLeaveDays} days)', style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedGrade = val),
      decoration: InputDecoration(
        labelText: 'Grade (Annual Leave Entitlement)',
        prefixIcon: const Icon(Icons.grade_outlined, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (val) => val == null ? 'Required' : null,
    );
  }

  Widget _buildSecurityStep(ThemeData theme) {
    return SingleChildScrollView(
      controller: _currentStep == 4 ? _scrollController : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Security', 'Protect your account'),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileStep(ThemeData theme) {
    final ImageService imageService = ImageService();
    
    return Column(
      children: [
        _buildStepTitle('Profile Picture', 'Upload a professional photo'),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            // Show image source selection dialog
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Take Photo'),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final imagePath = await imageService.takePhoto();
                          if (imagePath != null) {
                            setState(() {
                              _profilePhotoPath = imagePath;
                              _profilePhotoUrl = null; // Clear any previous uploaded URL
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Photo captured! Will upload after form submission.')),
                              );
                            });
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Choose from Gallery'),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final imagePath = await imageService.pickImage();
                          if (imagePath != null) {
                            setState(() {
                              _profilePhotoPath = imagePath;
                              _profilePhotoUrl = null; // Clear any previous uploaded URL
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Image selected! Will upload after form submission.')),
                              );
                            });
                          }
                        },
                      ),
                      if (_profilePhotoPath != null || _profilePhotoUrl != null)
                        ListTile(
                          leading: const Icon(Icons.delete, color: AppTheme.paleRed),
                          title: const Text('Remove Photo', style: TextStyle(color: AppTheme.paleRed)),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _profilePhotoPath = null;
                              _profilePhotoUrl = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile photo removed')),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
          child: Stack(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.skyBlue,
                    width: 2,
                  ),
                ),
                child: _profilePhotoPath != null
                    ? ClipOval(
                        child: Image.file(
                          File(_profilePhotoPath!),
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person_outline,
                              size: 80,
                              color: AppTheme.skyBlue,
                            );
                          },
                        ),
                      )
                    : _profilePhotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _profilePhotoUrl!.startsWith('http') 
                                  ? _profilePhotoUrl! 
                                  : '${AppConfig.apiBaseUrl}/${_profilePhotoUrl!}',
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(color: AppTheme.skyBlue),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person_outline,
                                  size: 80,
                                  color: AppTheme.skyBlue,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person_outline,
                            size: 80,
                            color: AppTheme.skyBlue,
                          ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.skyBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _profilePhotoPath != null || _profilePhotoUrl != null
              ? 'Profile photo added!'
              : 'Tap to add a professional photo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _profilePhotoPath != null || _profilePhotoUrl != null ? Colors.green : Colors.grey,
            fontWeight: _profilePhotoPath != null || _profilePhotoUrl != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A clear photo helps HR identify you quickly.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
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
    int maxLines = 1,
    String? hint,
    VoidCallback? onTap,
    String? Function(String?)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: isPassword ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.skyBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (customValidator != null) return customValidator(value);
        if (isRequired && (value == null || value.isEmpty)) return 'Required';
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
          child: Text(item, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (val) => val == null ? 'Required' : null,
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
                backgroundColor: AppTheme.skyBlue,
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
                  : Text(_currentStep == 5 ? 'Complete Registration' : 'Next Step'),
            ),
          ),
        ],
      ),
    );
  }
}

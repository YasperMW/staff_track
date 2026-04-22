import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../controllers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../services/lookup_service.dart';
import '../widgets/single_date_picker.dart';
import '../widgets/validated_text_field.dart';
import '../widgets/app_snackbar.dart';
import '../utils/validators.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';

class GoogleSignupScreen extends StatefulWidget {
  final Map<String, dynamic> googleData;
  final String idToken;

  const GoogleSignupScreen({
    super.key,
    required this.googleData,
    required this.idToken,
  });

  @override
  State<GoogleSignupScreen> createState() => _GoogleSignupScreenState();
}

class _GoogleSignupScreenState extends State<GoogleSignupScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final _googleAuthService = GoogleAuthService();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showScrollHint = false;

  // API data
  List<Department> _departments = [];
  List<Grade> _grades = [];
  List<String> _designationNames = [];
  bool _isLoadingLookupData = true;

  // Controllers - pre-filled from Google
  late final TextEditingController _firstNameController;
  late final TextEditingController _surNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _otherNamesController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _phoneController;
  late final TextEditingController _homeOfOriginController;
  late final TextEditingController _traditionalAuthorityController;
  late final TextEditingController _districtController;
  late final TextEditingController _currentAddressController;
  late final TextEditingController _spouseNameController;
  late final TextEditingController _spouseContactController;
  late final TextEditingController _dateOfEmploymentController;
  late final TextEditingController _designationController;
  late final TextEditingController _employeeNumberController;
  late final TextEditingController _nationalIdController;

  String? _selectedDepartment;
  String? _selectedDepartmentId;
  String? _selectedGrade;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Pre-fill from Google data
    _firstNameController = TextEditingController(text: widget.googleData['first_name'] ?? '');
    _surNameController = TextEditingController(text: widget.googleData['surname'] ?? '');
    _emailController = TextEditingController(text: widget.googleData['email'] ?? '');
    _otherNamesController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _phoneController = TextEditingController();
    _homeOfOriginController = TextEditingController();
    _traditionalAuthorityController = TextEditingController();
    _districtController = TextEditingController();
    _currentAddressController = TextEditingController();
    _spouseNameController = TextEditingController();
    _spouseContactController = TextEditingController();
    _dateOfEmploymentController = TextEditingController();
    _designationController = TextEditingController();
    _employeeNumberController = TextEditingController();
    _nationalIdController = TextEditingController();

    // Set profile photo from Google if available
    _profilePhotoUrl = widget.googleData['profile_photo_url'];

    _loadLookupData();
  }

  Future<void> _loadLookupData() async {
    try {
      final departments = await LookupService.getDepartments();
      final grades = await LookupService.getGrades();

      setState(() {
        _departments = departments;
        _grades = grades;
        _selectedDepartment = _departments.isNotEmpty ? _departments.first.name : null;
        _selectedDepartmentId = _departments.isNotEmpty ? _departments.first.departmentId : null;
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

  Future<void> _refreshLookupData() async {
    // Store current form data to preserve it during refresh
    final String currentDepartment = _selectedDepartment ?? '';
    final String? currentDepartmentId = _selectedDepartmentId;
    final String? currentGrade = _selectedGrade;
    final String currentDesignation = _designationController.text;
    
    try {
      final departments = await LookupService.getDepartments();
      final grades = await LookupService.getGrades();

      setState(() {
        _departments = departments;
        _grades = grades;
        
        // Try to preserve the current department selection
        if (currentDepartment.isNotEmpty) {
          final matchingDept = departments.firstWhere(
            (dept) => dept.name == currentDepartment,
            orElse: () => departments.isNotEmpty ? departments.first : Department(
              departmentId: '',
              name: '',
              designations: [],
              createdAt: '',
            ),
          );
          _selectedDepartment = matchingDept.name;
          _selectedDepartmentId = matchingDept.departmentId;
          
          // Update designations for the preserved department
          _updateDesignations(matchingDept.name);
          
          // Try to preserve the current designation if it still exists
          if (_designationNames.contains(currentDesignation)) {
            _designationController.text = currentDesignation;
          }
        } else {
          _selectedDepartment = _departments.isNotEmpty ? _departments.first.name : null;
          _selectedDepartmentId = _departments.isNotEmpty ? _departments.first.departmentId : null;
          _updateDesignations(_selectedDepartment);
        }
        
        // Try to preserve the current grade selection
        if (currentGrade != null && grades.any((g) => g.id == currentGrade)) {
          _selectedGrade = currentGrade;
        } else {
          _selectedGrade = _grades.isNotEmpty ? _grades.first.id : null;
        }
        
        if (kDebugMode) {
          print('Refreshed ${departments.length} departments');
          print('Preserved department: $_selectedDepartment');
          print('Preserved grade: $_selectedGrade');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing lookup data: $e');
      }
      
      // Show error message to user
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to refresh data. Please try again.');
      }
    }
  }

  void _updateDesignations(String? departmentName) {
    if (departmentName != null) {
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
        if (_designationController.text.isEmpty ||
            !_designationNames.contains(_designationController.text)) {
          _designationController.text = _designationNames.isNotEmpty ? _designationNames.first : '';
        }
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
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
    _firstNameController.dispose();
    _surNameController.dispose();
    _emailController.dispose();
    _otherNamesController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _homeOfOriginController.dispose();
    _traditionalAuthorityController.dispose();
    _districtController.dispose();
    _currentAddressController.dispose();
    _spouseNameController.dispose();
    _spouseContactController.dispose();
    _dateOfEmploymentController.dispose();
    _designationController.dispose();
    _employeeNumberController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 4) {
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

    final userData = {
      'google_id': widget.googleData['google_id'],
      'email': _emailController.text,
      'first_name': _firstNameController.text,
      'surname': _surNameController.text,
      'profile_photo_url': _profilePhotoUrl,
      'employee_number': _employeeNumberController.text,
      'national_id': _nationalIdController.text,
      'phone': _phoneController.text,
      'department': _selectedDepartment ?? '',
      'department_id': _selectedDepartmentId ?? '',
      'designation_id': _designationController.text,
      'grade_id': _selectedGrade,
      'date_of_employment': _dateOfEmploymentController.text,
      'date_of_birth': _dateOfBirthController.text,
      'gender': _selectedGender ?? '',
      'home_of_origin': _homeOfOriginController.text,
      'traditional_authority': _traditionalAuthorityController.text,
      'district': _districtController.text,
      'current_address': _currentAddressController.text,
      'other_names': _otherNamesController.text,
      'marital_status': _selectedMaritalStatus ?? '',
      'spouse_name': _spouseNameController.text,
      'spouse_contact': _spouseContactController.text,
    };

    final response = await _googleAuthService.registerGoogleUser(
      idToken: widget.idToken,
      userData: userData,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        // Save token and navigate to home
        if (response.token != null) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.saveToken(response.token!, response.user ?? {});
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );

        AppSnackBar.showSuccess(context, 'Account created successfully!');
      } else {
        AppSnackBar.showError(context, response.message ?? 'Registration failed');
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
                child: RefreshIndicator(
                  onRefresh: _refreshLookupData,
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
                                    _buildProfileStep(theme),
                                  ],
                                ),
                                if (_showScrollHint) _buildScrollHint(theme),
                              ],
                            ),
                          ),
                          _buildNavigationButtons(theme),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Google Sign-Up',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
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
          // Email - Pre-filled from Google, read-only
          ValidatedTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            validationType: ValidationType.email,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person_outline,
            validationType: ValidationType.name,
            fieldName: 'First Name',
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _surNameController,
            label: 'Surname',
            icon: Icons.person_pin_outlined,
            validationType: ValidationType.name,
            fieldName: 'Surname',
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _otherNamesController,
            label: 'Other Names',
            icon: Icons.people_outline,
            validationType: ValidationType.optional,
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _dateOfBirthController,
            label: 'Date of Birth',
            icon: Icons.cake_outlined,
            validationType: ValidationType.required,
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
          ValidatedDropdown(
            label: 'Gender',
            icon: Icons.wc_outlined,
            items: const ['male', 'female', 'other'],
            value: _selectedGender,
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _phoneController,
            label: 'Contact Number',
            icon: Icons.phone_android_outlined,
            validationType: ValidationType.phone,
            keyboardType: TextInputType.phone,
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
          ValidatedTextField(
            controller: _homeOfOriginController,
            label: 'Home of Origin',
            icon: Icons.home_work_outlined,
            validationType: ValidationType.required,
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _traditionalAuthorityController,
            label: 'Traditional Authority',
            icon: Icons.gavel_outlined,
            validationType: ValidationType.required,
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _districtController,
            label: 'District',
            icon: Icons.map_outlined,
            validationType: ValidationType.required,
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _currentAddressController,
            label: 'Current Address',
            icon: Icons.location_on_outlined,
            validationType: ValidationType.required,
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
          ValidatedDropdown(
            label: 'Marital Status',
            icon: Icons.favorite_border_outlined,
            items: const ['single', 'married', 'divorced', 'widowed'],
            value: _selectedMaritalStatus,
            onChanged: (val) {
              setState(() => _selectedMaritalStatus = val);
              _checkScrollNeed();
            },
          ),
          if (_selectedMaritalStatus == 'married') ...[
            const SizedBox(height: 16),
            ValidatedTextField(
              controller: _spouseNameController,
              label: 'Spouse Full Name',
              icon: Icons.person_pin_outlined,
              validationType: ValidationType.name,
              fieldName: 'Spouse Full Name',
            ),
            const SizedBox(height: 16),
            ValidatedTextField(
              controller: _spouseContactController,
              label: 'Spouse Contact',
              icon: Icons.phone_outlined,
              validationType: ValidationType.phone,
              keyboardType: TextInputType.phone,
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
          ValidatedTextField(
            controller: _employeeNumberController,
            label: 'Employee ID',
            icon: Icons.badge_outlined,
            validationType: ValidationType.employeeId,
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _nationalIdController,
            label: 'National ID',
            icon: Icons.credit_card_outlined,
            validationType: ValidationType.nationalId,
          ),
          const SizedBox(height: 16),
          ValidatedTextField(
            controller: _dateOfEmploymentController,
            label: 'Employment Date',
            icon: Icons.calendar_month_outlined,
            validationType: ValidationType.required,
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
          ValidatedDropdown(
            label: 'Department',
            icon: Icons.corporate_fare_outlined,
            items: _isLoadingLookupData ? ['Loading...'] : _departments.map((d) => d.name).toList(),
            value: _isLoadingLookupData ? null : _selectedDepartment,
            onChanged: (String? value) {
              setState(() {
                _selectedDepartment = value;
                if (value != null) {
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
                  _updateDesignations(value);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          ValidatedDropdown(
            label: 'Designation / Job Title',
            icon: Icons.work_history_outlined,
            items: _designationNames.isNotEmpty ? _designationNames : ['Select department first'],
            value: _designationNames.isNotEmpty && _designationNames.contains(_designationController.text)
                ? _designationController.text
                : (_designationNames.isNotEmpty ? _designationNames.first : null),
            onChanged: (val) {
              _designationController.text = val ?? '';
            },
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

  Widget _buildProfileStep(ThemeData theme) {
    return Column(
      children: [
        _buildStepTitle('Profile Picture', 'Your photo from Google'),
        const Spacer(),
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
          child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _profilePhotoUrl!,
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
        const SizedBox(height: 24),
        Text(
          _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
              ? 'Profile photo from Google'
              : 'No profile photo available',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _profilePhotoUrl != null ? Colors.green : Colors.grey,
            fontWeight: _profilePhotoUrl != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your Google profile photo will be used.',
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
                  : Text(_currentStep == 4 ? 'Complete Registration' : 'Next Step'),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_provider.dart';
import '../../widgets/simple_header.dart';
import '../../services/user_profile_service.dart';
import '../../services/complete_user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isLoadingProfile = true;
  
  // Text controllers
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _otherNamesController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  final _spouseNameController = TextEditingController();
  final _spouseContactController = TextEditingController();
  final _homeOfOriginController = TextEditingController();
  final _traditionalAuthorityController = TextEditingController();
  final _districtController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedSuffix;
  
  CompleteUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _otherNamesController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactNumberController.dispose();
    _currentAddressController.dispose();
    _maritalStatusController.dispose();
    _spouseNameController.dispose();
    _spouseContactController.dispose();
    _homeOfOriginController.dispose();
    _traditionalAuthorityController.dispose();
    _districtController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await CompleteUserProfileService.getCompleteUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _profile = profile;
          _populateFields();
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _populateFields() {
    if (_profile == null) return;
    
    _firstNameController.text = _profile!.firstName;
    _surnameController.text = _profile!.surname;
    _otherNamesController.text = _profile!.otherNames ?? '';
    _emailController.text = _profile!.email;
    _phoneController.text = _profile!.phone ?? '';
    _contactNumberController.text = _profile!.contactNumber ?? '';
    _currentAddressController.text = _profile!.currentAddress ?? '';
    _maritalStatusController.text = _profile!.maritalStatus ?? '';
    _spouseNameController.text = _profile!.spouseName ?? '';
    _spouseContactController.text = _profile!.spouseContact ?? '';
    _homeOfOriginController.text = _profile!.homeOfOrigin ?? '';
    _traditionalAuthorityController.text = _profile!.traditionalAuthority ?? '';
    _districtController.text = _profile!.district ?? '';
    _dateOfBirthController.text = _profile!.dateOfBirth ?? '';
    
    _selectedGender = _profile!.gender;
    _selectedSuffix = _profile!.suffix;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Prepare update data
      final updateData = {
        'first_name': _firstNameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'other_names': _otherNamesController.text.trim().isEmpty ? null : _otherNamesController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'contact_number': _contactNumberController.text.trim().isEmpty ? null : _contactNumberController.text.trim(),
        'current_address': _currentAddressController.text.trim().isEmpty ? null : _currentAddressController.text.trim(),
        'marital_status': _maritalStatusController.text.trim().isEmpty ? null : _maritalStatusController.text.trim(),
        'spouse_name': _spouseNameController.text.trim().isEmpty ? null : _spouseNameController.text.trim(),
        'spouse_contact': _spouseContactController.text.trim().isEmpty ? null : _spouseContactController.text.trim(),
        'home_of_origin': _homeOfOriginController.text.trim().isEmpty ? null : _homeOfOriginController.text.trim(),
        'traditional_authority': _traditionalAuthorityController.text.trim().isEmpty ? null : _traditionalAuthorityController.text.trim(),
        'district': _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim().isEmpty ? null : _dateOfBirthController.text.trim(),
        'gender': _selectedGender,
        'suffix': _selectedSuffix,
      };

      // Remove null values
      updateData.removeWhere((key, value) => value == null);

      final success = await UserProfileService.updateProfile(token, updateData);
      
      if (success) {
        // Update local user data in AuthProvider
        await authProvider.updateUserData({
          'name': '${_firstNameController.text.trim()} ${_surnameController.text.trim()}',
          'email': _emailController.text.trim(),
        });
        
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(
        title: 'Edit Profile',
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveProfile,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.skyBlue,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.skyBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 32),
                    _buildContactInfoSection(),
                    const SizedBox(height: 32),
                    _buildLocationInfoSection(),
                    const SizedBox(height: 32),
                    _buildFamilyInfoSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'First name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _surnameController,
          label: 'Surname',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Surname is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _otherNamesController,
          label: 'Other Names',
          hintText: 'Optional',
        ),
        const SizedBox(height: 16),
        _buildDropdownField<String>(
          value: _selectedSuffix,
          label: 'Suffix',
          items: const ['Mr', 'Mrs', 'Miss', 'Dr', 'Prof', 'Eng'],
          onChanged: (value) => setState(() => _selectedSuffix = value),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _dateOfBirthController,
          label: 'Date of Birth',
          hintText: 'YYYY-MM-DD',
          keyboardType: TextInputType.datetime,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              _dateOfBirthController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            }
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField<String>(
          value: _selectedGender,
          label: 'Gender',
          items: const ['Male', 'Female', 'Other'],
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSectionCard(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          keyboardType: TextInputType.phone,
          hintText: 'Optional',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _contactNumberController,
          label: 'Contact Number',
          keyboardType: TextInputType.phone,
          hintText: 'Optional',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _currentAddressController,
          label: 'Current Address',
          hintText: 'Optional',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildLocationInfoSection() {
    return _buildSectionCard(
      title: 'Location Information',
      icon: Icons.location_on_outlined,
      children: [
        _buildTextField(
          controller: _homeOfOriginController,
          label: 'Home of Origin',
          hintText: 'Optional',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _traditionalAuthorityController,
          label: 'Traditional Authority',
          hintText: 'Optional',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _districtController,
          label: 'District',
          hintText: 'Optional',
        ),
      ],
    );
  }

  Widget _buildFamilyInfoSection() {
    return _buildSectionCard(
      title: 'Family Information',
      icon: Icons.family_restroom,
      children: [
        _buildTextField(
          controller: _maritalStatusController,
          label: 'Marital Status',
          hintText: 'Optional',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _spouseNameController,
          label: 'Spouse Name',
          hintText: 'Optional',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _spouseContactController,
          label: 'Spouse Contact',
          keyboardType: TextInputType.phone,
          hintText: 'Optional',
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.skyBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.skyBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.skyBlue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onTap: onTap,
      readOnly: onTap != null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.skyBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.paleRed),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.skyBlue),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

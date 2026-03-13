import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_provider.dart';
import '../../widgets/simple_header.dart';
import '../home_screen.dart';
import '../../services/complete_user_profile_service.dart';
import '../../services/image_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/leave_service.dart';
import '../../services/employee_files_service.dart';
import '../../config/app_config.dart';
import 'edit_profile_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  CompleteUserProfile? completeProfile;
  bool isLoading = false;
  List<LeaveBalanceItem> _leaveBalances = [];
  List<EmployeeFileItem> _myFiles = [];
  bool isLoadingLeaveBalances = false;
  bool isLoadingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) return;
    
    setState(() {
      isLoading = true;
      isLoadingLeaveBalances = true;
      isLoadingFiles = true;
    });

    try {
      final profile = await CompleteUserProfileService.getCompleteUserProfile();
      final balances = await LeaveService.getBalances();
      final files = await EmployeeFilesService.listMyFiles();
      
      if (mounted) {
        setState(() {
          completeProfile = profile;
          _leaveBalances = balances;
          _myFiles = files;
          isLoading = false;
          isLoadingLeaveBalances = false;
          isLoadingFiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingLeaveBalances = false;
          isLoadingFiles = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile details')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: SimpleHeader(
        title: 'Complete Profile',
        actions: [
          IconButton(
            onPressed: () => _navigateToEditProfile(context),
            icon: const Icon(Icons.edit_outlined, color: AppTheme.skyBlue),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (completeProfile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileHeader(context, user),
                    const SizedBox(height: 32),
                    _buildPersonalInfoSection(context, user),
                    const SizedBox(height: 24),
                    _buildWorkInfoSection(context),
                    const SizedBox(height: 24),
                    _buildContactInfoSection(context),
                    const SizedBox(height: 24),
                    _buildFamilyInfoSection(context),
                    const SizedBox(height: 24),
                    _buildLocationInfoSection(context),
                    const SizedBox(height: 24),
                    _buildLeaveBalancesSection(context),
                    const SizedBox(height: 24),
                    _buildFilesSection(context),
                    const SizedBox(height: 24),
                    _buildSystemInfoSection(context),
                    const SizedBox(height: 40),
                  ],
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('Failed to load profile data'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    final authProvider = context.read<AuthProvider>();
    final ImageService imageService = ImageService();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.skyBlue, Color(0xFF5D8BF4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: user.profileImage.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.profileImage.startsWith('http') && !user.profileImage.contains('127.0.0.1') && !user.profileImage.contains('localhost')
                              ? user.profileImage 
                              : '${AppConfig.apiBaseUrl}/uploads/${user.profileImage}',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 60,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 60,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
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
                                    _uploadAndUpdatePhoto(imagePath);
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
                                    _uploadAndUpdatePhoto(imagePath);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppTheme.skyBlue,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                completeProfile?.email ?? 'Loading...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAndUpdatePhoto(String imagePath) async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    final ImageService imageService = ImageService();

    if (!mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.skyBlue),
              const SizedBox(height: 20),
              Text(
                'Updating profile photo...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This may take a moment',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. Upload the image to get a URL
      final uploadedUrl = await imageService.uploadImage(imagePath);
      if (uploadedUrl != null) {
        // 2. Update the user profile in the backend
        final success = await UserProfileService.updateProfilePhoto(token, uploadedUrl);
        if (success) {
          // 3. Update the local state in AuthProvider
          await authProvider.updateProfilePhotoLocally(uploadedUrl);
          
          // 4. Reload the complete profile to ensure this screen's data is fresh
          await _loadUserProfile();
          
          if (mounted) {
            Navigator.of(context).pop(true); // Close progress dialog and signal update
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated successfully!')),
            );
          }
        } else {
          throw Exception('Failed to update profile photo in backend');
        }
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToEditProfile(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  Widget _buildPersonalInfoSection(BuildContext context, user) {
    return _buildSectionCard(
      context,
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildDetailRow('Employee Number', completeProfile?.employeeNumber ?? 'N/A'),
        _buildDetailRow('National ID', completeProfile?.nationalId ?? 'Not specified'),
        _buildDetailRow('Full Name', completeProfile?.fullName ?? user?.name ?? 'N/A'),
        _buildDetailRow('First Name', completeProfile?.firstName ?? 'N/A'),
        _buildDetailRow('Surname', completeProfile?.surname ?? 'N/A'),
        _buildDetailRow('Other Names', completeProfile?.otherNames ?? 'Not specified'),
        _buildDetailRow('Suffix', completeProfile?.suffix ?? 'Not specified'),
        _buildDetailRow('Date of Birth', completeProfile?.dateOfBirth ?? 'Not specified'),
        _buildDetailRow('Gender', completeProfile?.gender ?? 'Not specified'),
        _buildDetailRow('Email', completeProfile?.email ?? 'N/A'),
        _buildDetailRow('Phone', completeProfile?.phone ?? 'Not specified'),
        _buildDetailRow('Contact Number', completeProfile?.contactNumber ?? 'Not specified'),
      ],
    );
  }

  Widget _buildWorkInfoSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'Work Information',
      icon: Icons.work_outline,
      children: [
        _buildDetailRow('Department', completeProfile?.departmentName ?? 'Not assigned'),
        _buildDetailRow('Designation', completeProfile?.designationName ?? 'Not specified'),
        _buildDetailRow('Role', completeProfile?.roleName ?? 'N/A'),
        _buildDetailRow('Employee Status', completeProfile?.status ?? 'Unknown'),
        _buildDetailRow('Date of Employment', completeProfile?.dateOfEmployment ?? 'Not specified'),
        _buildDetailRow('Head of Department', completeProfile?.isHeadOfDepartment == true ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildContactInfoSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _buildDetailRow('Email Address', completeProfile?.email ?? 'N/A'),
        _buildDetailRow('Phone Number', completeProfile?.phone ?? 'Not specified'),
        _buildDetailRow('Contact Number', completeProfile?.contactNumber ?? 'Not specified'),
        _buildDetailRow('Current Address', completeProfile?.currentAddress ?? 'Not specified'),
      ],
    );
  }

  Widget _buildFamilyInfoSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'Family Information',
      icon: Icons.family_restroom,
      children: [
        _buildDetailRow('Marital Status', completeProfile?.maritalStatus ?? 'Not specified'),
        _buildDetailRow('Spouse Name', completeProfile?.spouseName ?? 'Not specified'),
        _buildDetailRow('Spouse Contact', completeProfile?.spouseContact ?? 'Not specified'),
      ],
    );
  }

  Widget _buildLocationInfoSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'Location Information',
      icon: Icons.location_on_outlined,
      children: [
        _buildDetailRow('Home of Origin', completeProfile?.homeOfOrigin ?? 'Not specified'),
        _buildDetailRow('Traditional Authority', completeProfile?.traditionalAuthority ?? 'Not specified'),
        _buildDetailRow('District', completeProfile?.district ?? 'Not specified'),
        _buildDetailRow('Current Address', completeProfile?.currentAddress ?? 'Not specified'),
      ],
    );
  }

  Widget _buildSystemInfoSection(BuildContext context) {
    return _buildSectionCard(
      context,
      title: 'System Information',
      icon: Icons.info_outline,
      children: [
        _buildDetailRow('User ID', completeProfile?.userId ?? 'N/A'),
        _buildDetailRow('Registration Date', completeProfile?.registrationTimestamp ?? 'Unknown'),
        _buildDetailRow('Created Date', completeProfile?.createdAt ?? 'Unknown'),
        _buildDetailRow('Last Updated', completeProfile?.updatedAt ?? 'Unknown'),
        _buildDetailRow('Last Login', completeProfile?.lastLoginAt ?? 'Never'),
        _buildDetailRow('Profile Status', completeProfile?.status ?? 'Unknown'),
        _buildDetailRow('Selfie Verified', completeProfile?.selfieVerified == true ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildLeaveBalancesSection(BuildContext context) {
    if (isLoadingLeaveBalances) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_leaveBalances.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'Leave Balances',
        icon: Icons.beach_access_outlined,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No leave balances available',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ],
      );
    }

    return _buildSectionCard(
      context,
      title: 'Leave Balances',
      icon: Icons.beach_access_outlined,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _leaveBalances.map((b) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.leaveType,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${b.remainingDays}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.skyBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ ${b.allocatedDays + b.bonusDays}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilesSection(BuildContext context) {
    if (isLoadingFiles) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return _buildSectionCard(
      context,
      title: 'My Files',
      icon: Icons.folder_outlined,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Documents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                String selectedType = 'payslip';
                await showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (ctx) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Document Type', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Payslip'),
                                selected: selectedType == 'payslip',
                                onSelected: (v) { if (!v) return; selectedType = 'payslip'; },
                              ),
                              ChoiceChip(
                                label: const Text('Offer Letter'),
                                selected: selectedType == 'offer_letter',
                                onSelected: (v) { if (!v) return; selectedType = 'offer_letter'; },
                              ),
                              ChoiceChip(
                                label: const Text('Job Description'),
                                selected: selectedType == 'job_description',
                                onSelected: (v) { if (!v) return; selectedType = 'job_description'; },
                              ),
                              ChoiceChip(
                                label: const Text('Other'),
                                selected: selectedType == 'other',
                                onSelected: (v) { if (!v) return; selectedType = 'other'; },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.skyBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
                final url = await EmployeeFilesService.uploadFile(fileType: selectedType);
                if (url != null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File uploaded')),
                  );
                  await _loadUserProfile();
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload failed')),
                  );
                }
              },
              icon: const Icon(Icons.upload_file, color: AppTheme.skyBlue, size: 16),
              label: const Text('Upload', style: TextStyle(color: AppTheme.skyBlue, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_myFiles.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No files available',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          )
        else
          Column(
            children: _myFiles.map((f) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: AppTheme.textLightBlue),
                title: Text(
                  f.fileType,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  f.uploadDate ?? '',
                  style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, color: AppTheme.skyBlue),
                  onPressed: () {
                    // For now, rely on system to open URL if supported
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBottomNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final isAdmin = user.role.toLowerCase().contains('admin') ||
        user.role.toLowerCase().contains('hr') ||
        user.role.toLowerCase().contains('manager');

    const currentIndex = 0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
        selectedItemColor: AppTheme.skyBlue,
        unselectedItemColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.4),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              0,
              isAdmin ? Icons.dashboard : Icons.home,
              isAdmin ? Icons.dashboard_outlined : Icons.home_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Dashboard' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              1,
              Icons.access_time,
              Icons.access_time_outlined,
              currentIndex,
            ),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              2,
              isAdmin ? Icons.assignment_turned_in : Icons.bar_chart,
              isAdmin
                  ? Icons.assignment_turned_in_outlined
                  : Icons.bar_chart_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Requests' : 'Reports',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              context,
              3,
              isAdmin ? Icons.analytics : Icons.description,
              isAdmin ? Icons.analytics_outlined : Icons.description_outlined,
              currentIndex,
            ),
            label: isAdmin ? 'Analytics' : 'Requests',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    int currentIndex,
  ) {
    final isActive = currentIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.skyBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(height: 4),
        Icon(isActive ? activeIcon : inactiveIcon),
      ],
    );
  }
}

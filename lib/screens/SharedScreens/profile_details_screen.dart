import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/auth_provider.dart';
import '../../widgets/simple_header.dart';
import '../../widgets/avatar_widget.dart';
import '../../services/complete_user_profile_service.dart';
import '../../services/leave_service.dart';
import '../../services/employee_files_service.dart';
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
  bool _isUploadingFile = false;
  String? _uploadingFileName;

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
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: ClipOval(
              child: AvatarWidget(
                imageUrl: user.profileImage,
                userName: user.name,
                size: 120,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                borderColor: Colors.white.withValues(alpha: 0.3),
                placeholderIcon: Icons.person_outline,
                iconSize: 60,
                onUploadComplete: () {
                  _loadUserProfile();
                },
              ),
            ),
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

  void _showUploadDialog(BuildContext context) {
    String selectedType = 'payslip';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload Document',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the type of document you want to upload',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFileTypeChip(
                        ctx: context,
                        setModalState: setModalState,
                        label: 'Payslip',
                        value: 'payslip',
                        icon: Icons.receipt_long,
                        selectedType: selectedType,
                        onSelect: (v) {
                          if (!v) return;
                          setModalState(() => selectedType = 'payslip');
                        },
                      ),
                      _buildFileTypeChip(
                        ctx: context,
                        setModalState: setModalState,
                        label: 'Offer Letter',
                        value: 'offer_letter',
                        icon: Icons.description,
                        selectedType: selectedType,
                        onSelect: (v) {
                          if (!v) return;
                          setModalState(() => selectedType = 'offer_letter');
                        },
                      ),
                      _buildFileTypeChip(
                        ctx: context,
                        setModalState: setModalState,
                        label: 'Job Description',
                        value: 'job_description',
                        icon: Icons.work_outline,
                        selectedType: selectedType,
                        onSelect: (v) {
                          if (!v) return;
                          setModalState(() => selectedType = 'job_description');
                        },
                      ),
                      _buildFileTypeChip(
                        ctx: context,
                        setModalState: setModalState,
                        label: 'Other',
                        value: 'other',
                        icon: Icons.folder_outlined,
                        selectedType: selectedType,
                        onSelect: (v) {
                          if (!v) return;
                          setModalState(() => selectedType = 'other');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _performUpload(selectedType);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.skyBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Select File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFileTypeChip({
    required BuildContext ctx,
    required StateSetter setModalState,
    required String label,
    required String value,
    required IconData icon,
    required String selectedType,
    required void Function(bool) onSelect,
  }) {
    final isSelected = selectedType == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.skyBlue,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelect,
      selectedColor: AppTheme.skyBlue,
      backgroundColor: AppTheme.skyBlue.withAlpha(26),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.skyBlue,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Future<void> _performUpload(String fileType) async {
    setState(() {
      _isUploadingFile = true;
      _uploadingFileName = null;
    });

    try {
      final url = await EmployeeFilesService.uploadFile(
        fileType: fileType,
        onFileName: (name) {
          setState(() {
            _uploadingFileName = name;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isUploadingFile = false;
        _uploadingFileName = null;
      });

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload cancelled or failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingFile = false;
        _uploadingFileName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
              onPressed: _isUploadingFile ? null : () => _showUploadDialog(context),
              icon: Icon(
                Icons.upload_file,
                color: _isUploadingFile ? Colors.grey : AppTheme.skyBlue,
                size: 16,
              ),
              label: Text(
                'Upload',
                style: TextStyle(
                  color: _isUploadingFile ? Colors.grey : AppTheme.skyBlue,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        if (_isUploadingFile) ...[
          const SizedBox(height: 16),
          _buildUploadProgress(),
        ],
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
                  onPressed: () async {
                    final ok = await EmployeeFilesService.openEmployeeFile(f.fileUrl);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to open file')),
                      );
                    }
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

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.skyBlue.withAlpha(51)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.skyBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading ${_uploadingFileName ?? "file"}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please wait, this may take a moment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

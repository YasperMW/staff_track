import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../controllers/auth_provider.dart';
import '../../widgets/simple_header.dart';
import '../login_screen.dart';
import '../home_screen.dart';
import '../../services/user_profile_service.dart';
import '../../services/image_service.dart';
import '../../services/leave_service.dart';
import '../../services/employee_files_service.dart';
import 'profile_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? userProfile;
  bool isLoadingProfile = false;
  bool isLoadingMetrics = false;
  int workingDays = 0;
  double onTimeRate = 0.0;
  int leaveUsed = 0;
  List<LeaveBalanceItem> _leaveBalances = [];
  List<EmployeeFileItem> _myFiles = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    
    if (token == null) return;
    
    setState(() {
      isLoadingProfile = true;
    });

    try {
      final profile = await UserProfileService.getUserProfile(token);
      setState(() {
        isLoadingMetrics = true;
      });
      final metrics = await UserProfileService.getUserMetrics(token);
      final balances = await LeaveService.getBalances();
      final files = await EmployeeFilesService.listMyFiles();
      if (mounted) {
        print('Profile data received: ${profile?.toJson()}');
        setState(() {
          userProfile = profile;
          isLoadingProfile = false;
          if (metrics != null) {
            workingDays = metrics.workingDays;
            onTimeRate = metrics.onTimeRate;
            leaveUsed = metrics.leaveUsed;
          }
          _leaveBalances = balances;
          _myFiles = files;
          isLoadingMetrics = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
          isLoadingMetrics = false;
        });
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
      appBar: const SimpleHeader(
        title: 'Profile',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildProfileCard(context, user),
                  const SizedBox(height: 24),
                    _buildStatsRow(context),
                    const SizedBox(height: 24),
                    _buildLeaveBalances(context),
                    const SizedBox(height: 24),
                    _buildFilesSection(context),
                    const SizedBox(height: 24),
                    _buildOptionsList(context),
                    const SizedBox(height: 32),
                    _buildSignOutButton(context),
                    const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, user) {
    final authProvider = context.read<AuthProvider>();
    final ImageService imageService = ImageService();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.skyBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.skyBlue,
                    width: 2,
                  ),
                ),
                child: user.profileImage.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.profileImage,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.skyBlue,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person_outline,
                              color: AppTheme.skyBlue,
                              size: 60,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: AppTheme.skyBlue,
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
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.role,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textLightBlue,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: AppTheme.textLightBlue),
                  const SizedBox(width: 8),
                  Text(
                    userProfile?.email ?? 'Loading...',
                    style: const TextStyle(color: AppTheme.textLightBlue),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: AppTheme.textLightBlue),
                  const SizedBox(width: 8),
                  Text(
                    userProfile?.phone?.isNotEmpty == true ? userProfile!.phone! : 'No phone number',
                    style: const TextStyle(color: AppTheme.textLightBlue),
                  ),
                ],
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
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
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
          
          // 4. Reload the profile data to ensure everything is in sync
          await _loadUserProfile();
          
          if (mounted) {
            Navigator.of(context).pop(); // Close progress dialog
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

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, '$workingDays', 'Working Days')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, '${onTimeRate.toStringAsFixed(1)}%', 'On Time Rate')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, '$leaveUsed', 'Leave Used')),
      ],
    );
  }

  Widget _buildLeaveBalances(BuildContext context) {
    if (_leaveBalances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
        ),
        child: Text(
          'No leave balances available',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave Balances',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _leaveBalances.map((b) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha:0.2)),
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
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
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
      ),
    );
  }

  Widget _buildFilesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Files',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                icon: const Icon(Icons.upload_file, color: AppTheme.skyBlue, size: 18),
                label: const Text('Upload', style: TextStyle(color: AppTheme.skyBlue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_myFiles.isEmpty)
            Text(
              'No files available',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
            )
          else
            Column(
              children: _myFiles.map((f) {
                return ListTile(
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
      ),
    );
  }
  Widget _buildStatCard(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.skyBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildOptionTile(
                context: context,
                icon: themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: 'Dark Mode',
                trailingWidget: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  activeThumbColor: AppTheme.skyBlue,
                ),
                showChevron: false,
              );
            },
          ),
          const Divider(height: 1, indent: 60),
          _buildOptionTile(
            context: context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            trailing: 'On',
          ),
          const Divider(height: 1, indent: 60),
          _buildOptionTile(
            context: context,
            icon: Icons.shield_outlined,
            title: 'Privacy',
          ),
          const Divider(height: 1, indent: 60),
          _buildInfoTile(
            context: context,
            icon: Icons.business_outlined,
            title: 'Department',
            subtitle: userProfile?.departmentName ?? 'Loading...',
          ),
          const Divider(height: 1, indent: 60),
          _buildInfoTile(
            context: context,
            icon: Icons.work_outline,
            title: 'Designation',
            subtitle: userProfile?.designation ?? 'Not specified',
          ),
          const Divider(height: 1, indent: 60),
          _buildActionTile(
            context: context,
            icon: Icons.person_outline,
            title: 'View Complete Profile',
            onTap: () => _navigateToProfileDetails(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailing,
    Widget? trailingWidget,
    bool showChevron = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textLightBlue),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailingWidget,
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                color: AppTheme.textLightBlue,
                fontSize: 14,
              ),
            ),
          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ],
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.skyBlue),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.skyBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: AppTheme.skyBlue,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textLightBlue),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textLightBlue,
          fontSize: 14,
        ),
      ),
      trailing: const SizedBox.shrink(),
      onTap: null,
    );
  }

  void _navigateToProfileDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileDetailsScreen(),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout, color: AppTheme.paleRed),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.paleRed,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
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

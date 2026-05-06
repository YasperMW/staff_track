import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../controllers/auth_provider.dart';
import '../../widgets/simple_header.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/connectivity_handler.dart';
import '../../services/user_profile_service.dart';
import '../login_screen.dart';
import 'profile_details_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'security_privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? userProfile;
  bool isLoadingProfile = false;
  bool isLoadingMetrics = false;
  bool isRefreshing = false;
  String? errorMessage;
  int workingDays = 0;
  double onTimeRate = 0.0;
  int leaveUsed = 0;

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
      errorMessage = null;
    });

    try {
      final profile = await UserProfileService.getUserProfile(token);
      setState(() {
        isLoadingMetrics = true;
      });
      final metrics = await UserProfileService.getUserMetrics(token);
      if (mounted) {
        if (kDebugMode) {
          print('Profile data received: ${profile?.toJson()}');
        }
        setState(() {
          userProfile = profile;
          isLoadingProfile = false;
          isRefreshing = false;
          if (metrics != null) {
            workingDays = metrics.workingDays;
            onTimeRate = metrics.onTimeRate;
            leaveUsed = metrics.leaveUsed;
          }
          isLoadingMetrics = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading profile: $e');
      }
      if (mounted) {
        final errorMsg = ConnectivityHandler.getErrorMessage(e);
        setState(() {
          isLoadingProfile = false;
          isLoadingMetrics = false;
          isRefreshing = false;
          errorMessage = errorMsg;
        });

        // Show error snackbar if not the initial load
        if (userProfile != null) {
          ConnectivityHandler.showErrorSnackBar(
            context,
            message: errorMsg,
            onRetry: _loadUserProfile,
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => isRefreshing = true);
    await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    // Show loading state on initial load
    if (isLoadingProfile && userProfile == null) {
      return Scaffold(
        appBar: const SimpleHeader(title: 'Profile'),
        body: const LoadingWidget(message: 'Loading profile...'),
      );
    }

    // Show error state if no data and error occurred
    if (errorMessage != null && userProfile == null) {
      return Scaffold(
        appBar: const SimpleHeader(title: 'Profile'),
        body: ConnectivityErrorWidget(
          message: errorMessage!,
          onRetry: _loadUserProfile,
        ),
      );
    }

    return Scaffold(
      appBar: const SimpleHeader(
        title: 'Profile',
      ),
      body: RefreshIndicator(
        color: AppTheme.skyBlue,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show compact error banner if there's an error but we have data
              if (errorMessage != null && userProfile != null)
                ConnectivityErrorWidget(
                  message: errorMessage!,
                  onRetry: _loadUserProfile,
                  isCompact: true,
                ),
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
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, user) {
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
          AvatarWidget(
            imageUrl: user.profileImage,
            userName: user.name,
            size: 120,
            onUploadComplete: () {
              // Reload profile data after successful upload
              _loadUserProfile();
            },
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
            trailing: 'Manage',
            onTap: () => _navigateToNotificationSettings(context),
          ),
          const Divider(height: 1, indent: 60),
          _buildOptionTile(
            context: context,
            icon: Icons.shield_outlined,
            title: 'Security and Privacy',
            onTap: () => _navigateToSecurityPrivacy(context),
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
          const Divider(height: 1, indent: 60),
          _buildActionTile(
            context: context,
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () => _navigateToEditProfile(context),
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
    VoidCallback? onTap,
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
      onTap: onTap ?? () {},
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

  void _navigateToProfileDetails(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileDetailsScreen(),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  void _navigateToNotificationSettings(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );

    if (result == true) {
      _loadUserProfile();
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

  void _navigateToSecurityPrivacy(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SecurityPrivacyScreen(),
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

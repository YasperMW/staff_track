import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../controllers/auth_provider.dart';
import '../screens/SharedScreens/profile_screen.dart';
import '../screens/SharedScreens/notifications_screen.dart';
import '../config/app_config.dart';

class AppHeader extends StatelessWidget {
  final String subtitle;
  final bool showNotifications;
  final bool enableProfileNavigation;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.subtitle,
    this.showNotifications = true,
    this.enableProfileNavigation = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: onBack,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.all(8),
            ),
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/logo/logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "ST JOHN'S HOSPITAL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: const EdgeInsets.all(8),
              );
            },
          ),
          if (showNotifications)
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.all(8),
            ),
          const SizedBox(width: 4),
          _buildProfileAvatar(context, user),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, dynamic user) {
    final String initials;
    if (user == null || (user.name as String?) == null) {
      initials = '?';
    } else {
      final name = (user.name as String).trim();
      if (name.isEmpty) {
        initials = '?';
      } else {
        final parts = name.split(' ');
        if (parts.length == 1) {
          initials = parts.first[0].toUpperCase();
        } else {
          initials =
              (parts.first[0] + parts.last[0]).toUpperCase();
        }
      }
    }

    return GestureDetector(
      onTap: enableProfileNavigation
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            }
          : null,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.1),
        backgroundImage: user != null && user.profileImage.isNotEmpty
            ? NetworkImage(
                user.profileImage.startsWith('http') && !user.profileImage.contains('127.0.0.1') && !user.profileImage.contains('localhost')
                    ? user.profileImage 
                    : '${AppConfig.apiBaseUrl}/uploads/${user.profileImage}'
              )
            : null,
        child: user == null || user.profileImage.isEmpty
            ? Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.skyBlue,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}


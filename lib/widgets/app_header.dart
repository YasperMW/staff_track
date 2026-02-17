import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../controllers/auth_provider.dart';
import '../screens/SharedScreens/profile_screen.dart';

class AppHeader extends StatelessWidget {
  final String subtitle;
  final bool showNotifications;
  final bool enableProfileNavigation;

  const AppHeader({
    super.key,
    this.subtitle = 'HR Portal',
    this.showNotifications = true,
    this.enableProfileNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ST JOHN'S HOSPITAL",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
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
              );
            },
          ),
          if (showNotifications)
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {},
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
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        child: Text(
          initials,
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_header.dart';
import '../../services/login_service.dart';
import '../../controllers/auth_provider.dart';
import '../../config/app_config.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleHeader(
        title: 'Security and Privacy',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Data Security',
              icon: Icons.security,
              content: 'We implement industry-standard security measures to protect your personal information. All data is encrypted both in transit and at rest using advanced encryption protocols.',
              color: AppTheme.skyBlue,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip,
              content: 'Your privacy is important to us. We collect only the information necessary to provide our services and never share your personal data with third parties without your explicit consent.',
              color: AppTheme.skyBlue,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Data Usage',
              icon: Icons.data_usage,
              content: 'Your data is used solely for attendance tracking, profile management, and improving our services. We analyze usage patterns anonymously to enhance user experience.',
              color: AppTheme.skyBlue,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Your Rights',
              icon: Icons.gavel,
              content: 'You have the right to access, modify, or delete your personal data at any time. Contact our support team for any data-related requests.',
              color: AppTheme.skyBlue,
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Contact Security Team',
              icon: Icons.contact_support,
              content: 'If you have security concerns or questions about your privacy, please contact our security team at security@stafftrack.com',
              color: AppTheme.skyBlue,
            ),
            const SizedBox(height: 24),
            _buildPasswordSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Password Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Regularly updating your password helps keep your account secure. Use a strong password with a mix of letters, numbers, and symbols.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showChangePasswordDialog(),
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showPrivacyPolicyDialog(),
            icon: const Icon(Icons.description),
            label: const Text('View Full Privacy Policy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.skyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _downloadUserData(),
            icon: const Icon(Icons.download),
            label: const Text('Download My Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.skyBlue,
              side: const BorderSide(color: AppTheme.skyBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPolicySection('1. Information We Collect',
                      'We collect personal information you provide directly, such as your name, email address, employee ID, department, and profile photo. We also automatically collect attendance records, location data during check-in/check-out, and device information for security purposes.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('2. How We Use Your Information',
                      'Your data is used exclusively for: attendance tracking and reporting, profile management, leave request processing, shift scheduling, internal communications, and improving our services. We analyze usage patterns anonymously to enhance user experience.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('3. Data Sharing and Disclosure',
                      'We do not sell or share your personal information with third parties. Your data may only be accessed by authorized personnel within your organization (HR, department heads, administrators) for legitimate business purposes. We may disclose data if required by law.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('4. Data Security',
                      'We implement industry-standard security measures to protect your personal information. All data is encrypted both in transit (using TLS/SSL) and at rest (using AES-256 encryption). Access to data is controlled through role-based permissions and authentication tokens.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('5. Data Retention',
                      'We retain your personal data for as long as your account is active or as needed to provide services. Upon account termination, data may be retained for legal compliance, dispute resolution, and agreement enforcement purposes.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('6. Your Rights',
                      'You have the right to: access your personal data, request correction of inaccurate data, request deletion of your data, export your data in a portable format, object to processing of your data, and withdraw consent at any time. Contact our support team for any data-related requests.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('7. Location Data',
                      'Location data is collected only during attendance check-in and check-out to verify your presence at authorized locations. This data is used solely for attendance verification and is not tracked continuously.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('8. Changes to This Policy',
                      'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date. You are advised to review this policy periodically.'),
                  const SizedBox(height: 16),
                  _buildPolicySection('9. Contact Us',
                      'If you have any questions about this privacy policy or our data practices, please contact our security team at security@stafftrack.com or reach out to your HR department.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadUserData() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to download your data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing your data export...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/export-data'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/staff_track_data_export.json');
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(data),
        );

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Staff Track Data Export',
            text: 'Your personal data export from Staff Track',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to export data: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Password must be at least 8 characters long',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (currentPasswordController.text.isEmpty ||
                        newPasswordController.text.isEmpty ||
                        confirmPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    if (newPasswordController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password must be at least 8 characters long')),
                      );
                      return;
                    }

                    if (newPasswordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }

                    setState(() => isLoading = true);

                    try {
                      final authProvider = context.read<AuthProvider>();
                      final token = authProvider.token;
                      
                      if (token == null) {
                        throw Exception('Not authenticated');
                      }
                      
                      final result = await LoginService().changePassword(
                        token: token,
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                      );
                      
                      if (context.mounted) {
                        if (result.success) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message ?? 'Password changed successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message ?? 'Failed to change password'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error changing password: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() => isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.skyBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

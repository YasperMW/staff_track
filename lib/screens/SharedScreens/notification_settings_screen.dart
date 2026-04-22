import 'package:flutter/material.dart';
import '../../services/fcm_service.dart';
import '../../services/local_notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _settings;
  bool _localNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await FCMService.getNotificationSettings();
      final localEnabled = await LocalNotificationService().isLocalNotificationsEnabled();
      
      setState(() {
        _settings = settings;
        _localNotificationsEnabled = localEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
      }
    }
  }

  Future<void> _testNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await FCMService.testNotificationSetup();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
      
      if (mounted) {
        final message = results['overall'] == 'success' 
          ? 'Notification test successful!'
          : 'Notification test failed: ${results['overall']}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: results['overall'] == 'success' 
              ? AppTheme.lightGoldAccent 
              : AppTheme.paleRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleLocalNotifications(bool enabled) async {
    setState(() => _isLoading = true);
    
    try {
      await LocalNotificationService().setLocalNotificationsEnabled(enabled);
      setState(() {
        _localNotificationsEnabled = enabled;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled 
              ? 'Offline reminders enabled!' 
              : 'Offline reminders disabled'),
            backgroundColor: enabled ? AppTheme.lightGoldAccent : AppTheme.paleRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settings: $e'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final granted = await FCMService.checkAndRequestPermissions(context: context);
      
      if (granted) {
        // Retry FCM initialization
        await FCMService.retryInitialization();
        await _loadNotificationSettings();
      }
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted ? 'Permissions granted!' : 'Permissions denied'),
            backgroundColor: granted ? AppTheme.lightGoldAccent : AppTheme.paleRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: AppTheme.paleRed,
          ),
        );
      }
    }
  }

  Widget _buildPermissionStatusCard() {
    if (_settings == null) return const SizedBox();
    
    final permissionStatus = _settings!['permissionStatus']?.toString() ?? 'Unknown';
    final isGranted = permissionStatus.contains('granted');
    final tokenRegistered = _settings!['tokenRegistered'] ?? false;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGranted ? Icons.check_circle : Icons.error,
                  color: isGranted ? AppTheme.lightGoldAccent : AppTheme.paleRed,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notification Permissions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Status: $permissionStatus'),
            Text('FCM Token Registered: ${tokenRegistered ? "Yes" : "No"}'),
            if (_settings!['platform'] != null)
              Text('Platform: ${_settings!['platform']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalNotificationsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_off_outlined, color: AppTheme.textLightBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Reminders',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get reminders even without internet connection',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _localNotificationsEnabled,
                  onChanged: _toggleLocalNotifications,
                  activeThumbColor: AppTheme.skyBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.skyBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Works alongside regular notifications to ensure you never miss important reminders',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.skyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsCard() {
    if (_testResults == null) return const SizedBox();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._testResults!.entries.map((entry) {
              final value = entry.value.toString();
              final isSuccess = value.contains('success') || value.contains('true');
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: isSuccess ? AppTheme.lightGoldAccent : AppTheme.paleRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: $value',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppTheme.skyBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildPermissionStatusCard(),
                  _buildLocalNotificationsCard(),
                  _buildTestResultsCard(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _requestPermissions,
                            icon: const Icon(Icons.notifications),
                            label: const Text('Request Permissions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.skyBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testNotifications,
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Test Notifications'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightGold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loadNotificationSettings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Status'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Troubleshooting',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text('• Ensure app has notification permissions'),
                            Text('• Check battery optimization settings'),
                            Text('• Verify Do Not Disturb is off'),
                            Text('• Make sure app can run in background'),
                            Text('• Test with Firebase Console for server-side issues'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(
                subtitle: 'HR Admin Portal',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Staff Requests',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Manage leave and WFH requests',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPendingRequestsList(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequestsList(BuildContext context) {
    final requests = [
      {'name': 'Michael Chen', 'type': 'Annual Leave', 'duration': '5 days', 'date': 'Mar 01 - Mar 05', 'isOwn': 'false'},
      {'name': 'Robert Brown', 'type': 'WFH', 'duration': '1 day', 'date': 'Feb 20', 'isOwn': 'false'},
      {'name': 'Dr. Sarah Wilson', 'type': 'Conference Leave', 'duration': '3 days', 'date': 'Mar 10 - Mar 12', 'isOwn': 'true'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Team Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${requests.length} Total',
              style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: requests.map((req) => _buildRequestItem(context, req)).toList(),
        ),
      ],
    );
  }

  Widget _buildRequestItem(BuildContext context, Map<String, String> req) {
    final bool isOwnRequest = req['isOwn'] == 'true';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isOwnRequest 
          ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3), width: 1)
          : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isOwnRequest 
                  ? Colors.orange.withValues(alpha: 0.1)
                  : AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  req['name']![0], 
                  style: TextStyle(
                    color: isOwnRequest ? Colors.orange : AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(req['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (isOwnRequest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MY REQUEST',
                              style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(req['type']!, style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(req['duration']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppTheme.textLightBlue),
              const SizedBox(width: 8),
              Text(req['date']!, style: const TextStyle(fontSize: 12, color: AppTheme.textLightBlue)),
            ],
          ),
          const SizedBox(height: 20),
          if (isOwnRequest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Pending Superior Approval',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

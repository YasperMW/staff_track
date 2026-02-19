import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<Map<String, dynamic>> requestsHistory = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Replace with actual requests API call
      // For now, showing empty state until API is ready
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        requestsHistory = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(
                  subtitle: 'HR Portal',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requests',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Leave & WFH requests',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                                ),
                              ),
                            ],
                          ),
                          _buildAddButton(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSummaryGrid(context),
                      const SizedBox(height: 24),
                      _buildRequestsList(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha:0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(context, '12', '/ 21 Annual')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard(context, '8', '/ 10 Sick')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard(context, '3', '/ 5 Personal')),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String count, String label) {
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
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
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

  Widget _buildRequestsList(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (requestsHistory.isEmpty) {
      return _buildEmptyState(context, 'No requests found');
    }
    return Column(
      children: requestsHistory.map((request) => _buildRequestCard(context, request)).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.2),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    Color statusColor;
    Color bgColor;
    IconData? icon;

    switch (request['status']) {
      case 'Approved':
        statusColor = const Color(0xFF4CAF50);
        bgColor = const Color(0xFFE8F5E9);
        icon = Icons.check;
        break;
      case 'Rejected':
        statusColor = const Color(0xFFEF5350);
        bgColor = const Color(0xFFFFEBEE);
        icon = Icons.close;
        break;
      case 'Pending':
        statusColor = const Color(0xFFFFA726);
        bgColor = const Color(0xFFFFF3E0);
        icon = Icons.refresh;
        break;
      default:
        statusColor = Colors.grey;
        bgColor = Colors.grey.shade100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['type'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      request['status'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppTheme.textLightBlue),
              const SizedBox(width: 8),
              Text(
                request['dateRange'],
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 16, color: AppTheme.textLightBlue),
              const SizedBox(width: 4),
              Text(
                request['duration'],
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request['description'],
            style: const TextStyle(color: AppTheme.textLightBlue),
          ),
        ],
      ),
    );
  }
}

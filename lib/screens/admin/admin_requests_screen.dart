import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../services/requests_service.dart';
import '../../services/auth_storage.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  bool _isLoading = false;
  List<AdminTeamRequest> _requests = [];
  List<AdminTeamRequest> _myRequests = [];
  List<AdminTeamRequest> _teamRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible (e.g., navigating back)
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load my requests and team requests separately
      final myRequestsFuture = RequestsService.getMyAdminRequests();
      final teamRequestsFuture = RequestsService.getAdminPendingRequests();
      
      final results = await Future.wait([myRequestsFuture, teamRequestsFuture]);
      
      if (!mounted) return;
      
      setState(() {
        _myRequests = results[0];
        _teamRequests = results[1];
        _requests = [...results[0], ...results[1]];
        _isLoading = false;
      });
      print('Loaded ${results[0].length} my requests and ${results[1].length} team requests');
    } catch (e) {
      if (!mounted) return;
      print('Error loading admin requests: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load requests: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadRequests();
  }

  Future<void> _debugRequests() async {
    try {
      print('=== DEBUG: Authentication & Requests ===');
      
      // Check authentication status first
      final isAuth = await AuthStorage.isAuthenticated();
      final token = await AuthStorage.getToken();
      var userId = await AuthStorage.getUserId();
      
      // If user_id is missing but token exists, try to refresh user data
      if (token != null && userId == null) {
        print('User ID missing but token exists, attempting to refresh user data...');
        final refreshed = await AuthStorage.refreshUserData();
        if (refreshed) {
          userId = await AuthStorage.getUserId();
          print('User data refreshed, new user ID: $userId');
        } else {
          print('Failed to refresh user data');
        }
      }
      
      final finalIsAuth = token != null && userId != null;
      
      if (!finalIsAuth) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Authentication Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Not properly authenticated:'),
                  Text('• Token: ${token == null ? 'Missing' : 'Present'}'),
                  Text('• User ID: ${userId == null ? 'Missing' : 'Present'}'),
                  const SizedBox(height: 16),
                  const Text('Please try logging out and logging back in.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Test normal endpoint
      final normalData = await RequestsService.getAdminPendingRequests();
      print('Normal endpoint returned: ${normalData.length} requests');
      
      // Test debug endpoint
      final debugData = await RequestsService.getAllPendingRequestsDebug();
      print('Debug endpoint returned: ${debugData.length} requests');
      
      // Show comparison
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Authenticated: $finalIsAuth'),
                  Text('User ID: $userId'),
                  const SizedBox(height: 16),
                  Text('Normal endpoint: ${normalData.length} requests'),
                  Text('Debug endpoint: ${debugData.length} requests'),
                  const SizedBox(height: 16),
                  if (debugData.isNotEmpty) ...[
                    const Text('Debug endpoint details:'),
                    ...debugData.map((req) => Text(
                      '- ${req['type']} by ${req['user_name']} (approver: ${req['current_approver_id'] ?? 'NULL'})'
                    )).take(5),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Debug error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug error: $e')),
        );
      }
    }
  }

  Future<void> _handleApprove(AdminTeamRequest req) async {
    try {
      await RequestsService.approveRequest(req.id);
      await _loadRequests();
    } catch (e) {
      //error
    }
  }

  Future<void> _handleDeny(AdminTeamRequest req) async {
    try {
      await RequestsService.denyRequest(req.id);
      await _loadRequests();
    } catch (e) {
      //handle error
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(subtitle: 'HR Admin Portal'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.bug_report, color: AppTheme.primaryBlue),
                                  onPressed: _debugRequests,
                                  tooltip: 'Debug Requests',
                                ),
                                const SizedBox(width: 8),
                                _buildAddButton(),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _buildMyRequestsSection(context),
                      const SizedBox(height: 32),
                      _buildTeamRequestsSection(context),
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
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: _openCreateRequestSheet,
      ),
    );
  }

  Future<void> _openCreateRequestSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String selectedType = 'Leave';
        DateTimeRange? selectedRange;
        bool isSubmitting = false;

        String formatDate(DateTime d) {
          return d.toIso8601String().split('T').first;
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              Future<void> pickDateRange() async {
                final now = DateTime.now();
                final range = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                  initialDateRange:
                      selectedRange ?? DateTimeRange(start: now, end: now),
                );
                if (range != null) {
                  setSheetState(() {
                    selectedRange = range;
                  });
                }
              }

              Future<void> handleSubmit() async {
                if (selectedRange == null || isSubmitting) return;
                setSheetState(() {
                  isSubmitting = true;
                });
                try {
                  final start = formatDate(selectedRange!.start);
                  final end = formatDate(selectedRange!.end);
                  await RequestsService.createRequest(
                    type: selectedType,
                    startDate: start,
                    endDate: end,
                  );
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  await _loadRequests();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request submitted for approval'),
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  setSheetState(() {
                    isSubmitting = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to submit request')),
                  );
                }
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Request type',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Leave'),
                          selected: selectedType == 'Leave',
                          onSelected: (v) {
                            if (!v) return;
                            setSheetState(() {
                              selectedType = 'Leave';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Work From Home'),
                          selected: selectedType == 'Work From Home',
                          onSelected: (v) {
                            if (!v) return;
                            setSheetState(() {
                              selectedType = 'Work From Home';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Date range',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: pickDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppTheme.textLightBlue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedRange == null
                                  ? 'Select dates'
                                  : selectedRange!.start == selectedRange!.end
                                  ? formatDate(selectedRange!.start)
                                  : '${formatDate(selectedRange!.start)} - ${formatDate(selectedRange!.end)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedRange == null || isSubmitting
                            ? null
                            : handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            isSubmitting
                                ? 'Submitting...'
                                : 'Submit for approval',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleWithdraw(AdminTeamRequest req) async {
    try {
      await RequestsService.withdrawRequest(req.id);
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request withdrawn successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to withdraw request: $e')),
        );
      }
    }
  }

  Widget _buildMyRequestsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${_myRequests?.length ?? 0} Total',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if ((_myRequests?.length ?? 0) == 0)
          Center(
            child: Column(
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No requests found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: (_myRequests ?? [])
                .map((req) => _buildMyRequestItem(context, req))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildMyRequestItem(BuildContext context, AdminTeamRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
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
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  req.userName.isNotEmpty ? req.userName[0] : '?',
                  style: const TextStyle(color: AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          req.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MY REQUEST',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      req.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                req.duration,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textLightBlue,
              ),
              const SizedBox(width: 8),
              Text(
                req.dateRange,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleWithdraw(req),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Withdraw Request'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRequestsSection(BuildContext context) {
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
              '${_teamRequests?.length ?? 0} Total',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if ((_teamRequests?.length ?? 0) == 0)
          Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No team requests found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: (_teamRequests ?? [])
                .map((req) => _buildTeamRequestItem(context, req))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTeamRequestItem(BuildContext context, AdminTeamRequest req) {
    final bool isOwnRequest = req.isOwn;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isOwnRequest
            ? Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              )
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
                  req.userName.isNotEmpty ? req.userName[0] : '?',
                  style: TextStyle(
                    color: isOwnRequest ? Colors.orange : AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          req.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isOwnRequest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MY REQUEST',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      req.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                req.duration,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textLightBlue,
              ),
              const SizedBox(width: 8),
              Text(
                req.dateRange,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLightBlue,
                ),
              ),
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
                  const SizedBox(width: 8),
                  Text(
                    'Pending Self-Approval',
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
                    onPressed: () => _handleDeny(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApprove(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildPendingRequestsList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.primaryBlue,
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No pending team requests',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

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
              '${_requests.length} Total',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: _requests
              .map((req) => _buildRequestItem(context, req))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRequestItem(BuildContext context, AdminTeamRequest req) {
    final bool isOwnRequest = req.isOwn;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: isOwnRequest
            ? Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                width: 1,
              )
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
                  req.userName.isNotEmpty ? req.userName[0] : '?',
                  style: TextStyle(
                    color: isOwnRequest ? Colors.orange : AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          req.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isOwnRequest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MY REQUEST',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      req.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                req.duration,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textLightBlue,
              ),
              const SizedBox(width: 8),
              Text(
                req.dateRange,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLightBlue,
                ),
              ),
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
                    onPressed: () => _handleDeny(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApprove(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/tile_date_picker.dart';
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
  String _filterStatus = 'pending';
  String _filterType = 'all';
  String _searchQuery = '';

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

  Widget _buildCostRow(String label, double? value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('MK ${value?.toStringAsFixed(2) ?? "0.00"}', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            flexibleSpace: const SafeArea(
              child: AppHeader(
                subtitle: 'Requests',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.skyBlue,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Manage leave and WFH requests',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.bug_report, color: AppTheme.skyBlue),
                            onPressed: _debugRequests,
                            tooltip: 'Debug Requests',
                          ),
                          const SizedBox(width: 8),
                          _buildAddButton(),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.skyBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withValues(alpha: 0.3),
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
        String selectedType = 'Annual Leave';
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
                final range = await showTileDateRangePicker(
                  context: ctx,
                  initialStartDate: selectedRange?.start,
                  initialEndDate: selectedRange?.end,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                  title: 'Select Request Dates',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Annual Leave'),
                          selected: selectedType == 'Annual Leave',
                          onSelected: (v) {
                            if (!v) return;
                            setSheetState(() {
                              selectedType = 'Annual Leave';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Sick Leave'),
                          selected: selectedType == 'Sick Leave',
                          onSelected: (v) {
                            if (!v) return;
                            setSheetState(() {
                              selectedType = 'Sick Leave';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Personal Leave'),
                          selected: selectedType == 'Personal Leave',
                          onSelected: (v) {
                            if (!v) return;
                            setSheetState(() {
                              selectedType = 'Personal Leave';
                            });
                          },
                        ),
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
                          backgroundColor: AppTheme.skyBlue,
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
              '${_myRequests.length} Total',
              style: const TextStyle(
                color: AppTheme.skyBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if ((_myRequests.length) == 0)
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
            children: (_myRequests)
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
          color: AppTheme.skyBlue.withValues(alpha: 0.3),
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
                backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.1),
                child: Text(
                  req.userName.isNotEmpty ? req.userName[0] : '?',
                  style: const TextStyle(color: AppTheme.skyBlue),
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
                            color: AppTheme.skyBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '',
                            style: TextStyle(
                              color: AppTheme.skyBlue,
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
                        color: AppTheme.skyBlue,
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
                foregroundColor: AppTheme.lightGold,
                side: const BorderSide(color: AppTheme.lightGold),
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
              '${_teamRequests.length} Total',
              style: const TextStyle(
                color: AppTheme.skyBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if ((_teamRequests.length) == 0)
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
            children: (_teamRequests)
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
                color: AppTheme.skyBlue.withValues(alpha: 0.3),
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
                    ? AppTheme.lightGold.withValues(alpha: 0.1)
                    : AppTheme.skyBlue.withValues(alpha: 0.1),
                child: Text(
                  req.userName.isNotEmpty ? req.userName[0] : '?',
                  style: TextStyle(
                    color: isOwnRequest ? AppTheme.lightGold : AppTheme.skyBlue,
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
                              color: AppTheme.lightGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MY REQUEST',
                              style: TextStyle(
                                color: AppTheme.lightGold,
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
                        color: AppTheme.skyBlue,
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
                  Icon(Icons.hourglass_empty, size: 16, color: AppTheme.lightGold),
                  SizedBox(width: 8),
                  Text(
                    'Pending Self-Approval',
                    style: TextStyle(
                      color: AppTheme.lightGold,
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
                      foregroundColor: AppTheme.paleRed,
                      side: const BorderSide(color: AppTheme.paleRed),
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
                    onPressed: () => _showApprovalDetail(context, req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Review'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<AdminTeamRequest> _applyFilters(List<AdminTeamRequest> list) {
    return list.where((r) {
      final statusMatch = _filterStatus == 'all' ? true : r.status.toLowerCase() == _filterStatus;
      final typeMatch = _filterType == 'all' ? true : r.type.toLowerCase().contains(_filterType);
      final searchMatch = _searchQuery.isEmpty
          ? true
          : r.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.type.toLowerCase().contains(_searchQuery.toLowerCase());
      return statusMatch && typeMatch && searchMatch;
    }).toList();
  }

  Future<void> _showApprovalDetail(BuildContext context, AdminTeamRequest req) async {
    String comment = '';
    String? userRole;
    
    // Get current user role
    try {
      userRole = await AuthStorage.getUserRole();
    } catch (e) {
      print('Error getting user role: $e');
    }
    
    // HOD Fields
    DateTime? hodFrom;
    DateTime? hodTo;
    final hodReasonController = TextEditingController();
    
    // HR Fields
    final hrEntitlementController = TextEditingController();
    DateTime? hrEntTakenFrom;
    DateTime? hrEntTakenTo;
    DateTime? hrLastLeaveFrom;
    DateTime? hrLastLeaveTo;
    final hrLastLeaveDaysController = TextEditingController();
    final hrBalanceController = TextEditingController();
    String hrLeaveGrantStatus = 'not_required';
    
    // Admin Fields
    DateTime? adminFrom;
    DateTime? adminTo;
    final adminTotalDaysController = TextEditingController();
    
    // Trip Approval Fields
    bool accountantFundsAvailable = true;
    final hodTripRecommendationController = TextEditingController();
    final adminTripDetailsController = TextEditingController();

    List<Map<String, dynamic>> approvals = [];
    bool loading = true;

    String formatDate(DateTime? d) {
      if (d == null) return 'Select date';
      return d.toIso8601String().split('T').first;
    }

    // Helper function to determine if user can see this section
    bool canSeeSection(String sectionType, int level) {
      if (userRole == null) return true; // Fallback: show all if role unknown
      
      final role = userRole!.toLowerCase();
      
      if (req.type.toLowerCase() == 'leave duty station') {
        // Trip approval workflow: Accountant -> HOD -> Admin
        if (level == 1) {
          return role.contains('accountant') || role.contains('finance');
        } else if (level == 2) {
          return role.contains('hod') || role.contains('head') || role.contains('department') || role.contains('unit');
        } else if (level == 3) {
          return role.contains('administrator') || role.contains('admin') || role.contains('principal');
        }
      } else {
        // Leave approval workflow: HOD -> HR -> Admin
        if (level == 1) {
          return role.contains('hod') || role.contains('head') || role.contains('department') || role.contains('unit');
        } else if (level == 2) {
          return role.contains('hr') || role.contains('human') || role.contains('resource');
        } else if (level == 3) {
          return role.contains('administrator') || role.contains('admin') || role.contains('principal');
        }
      }
      
      return false;
    }

    // Helper function to get user's approval level based on role
    int? getUserApprovalLevel() {
      if (userRole == null) return null;
      
      final role = userRole!.toLowerCase();
      
      if (req.type.toLowerCase() == 'leave duty station') {
        // Trip approval workflow: Accountant -> HOD -> Admin
        if (role.contains('accountant') || role.contains('finance')) return 1;
        if (role.contains('hod') || role.contains('head') || role.contains('department') || role.contains('unit')) return 2;
        if (role.contains('administrator') || role.contains('admin') || role.contains('principal')) return 3;
      } else {
        // Leave approval workflow: HOD -> HR -> Admin
        if (role.contains('hod') || role.contains('head') || role.contains('department') || role.contains('unit')) return 1;
        if (role.contains('hr') || role.contains('human') || role.contains('resource')) return 2;
        if (role.contains('administrator') || role.contains('admin') || role.contains('principal')) return 3;
      }
      
      return null;
    }

    // Helper function to get user's existing approval for this request
    Map<String, dynamic>? getUserExistingApproval() {
      final userLevel = getUserApprovalLevel();
      if (userLevel == null) return null;
      
      return approvals.firstWhere(
        (approval) => approval['level'] == userLevel,
        orElse: () => <String, dynamic>{},
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Declare variables at the beginning of StatefulBuilder
            final userApprovalLevel = getUserApprovalLevel();
            final userExistingApproval = getUserExistingApproval();
            final canApprove = userApprovalLevel != null && (userExistingApproval == null || userExistingApproval.isEmpty);
            
            Future<void> loadApprovals() async {
              try {
                final data = await RequestsService.getRequestApprovals(req.id);
                setModalState(() {
                  approvals = data;
                  loading = false;
                });
              } catch (_) {
                setModalState(() {
                  approvals = [];
                  loading = false;
                });
              }
            }

            if (loading) {
              loadApprovals();
            }

            Widget buildSectionHeader(String title) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.skyBlue),
                ),
              );
            }

            Widget buildDateField(String label, DateTime? value, VoidCallback onTap) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatDate(value)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Request Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                    const Divider(),
                    
                    // Section A Info
                    buildSectionHeader('Section A: Applicant Info'),
                    Text('Name: ${req.userName}'),
                    Text('Type: ${req.type}'),
                    if (req.type.toLowerCase() == 'leave duty station') ...[
                      Text('Reason: ${req.reasonForLeaving ?? "N/A"}'),
                      Text('Date: ${req.travelDate ?? "N/A"}'),
                      Text('Destination: ${req.travelPlace ?? "N/A"}'),
                      const SizedBox(height: 8),
                      buildSectionHeader('Section B: Cost of the trip'),
                      _buildCostRow('Accommodation', req.costAccommodation),
                      _buildCostRow('Breakfast', req.costBreakfast),
                      _buildCostRow('Lunch', req.costLunch),
                      _buildCostRow('Supper', req.costSupper),
                      _buildCostRow('Public Transport', req.costPublicTransport),
                      _buildCostRow('Fuel & Lubricants', req.costFuelLubricants),
                      const Divider(),
                      _buildCostRow('TOTAL', req.costTotal, isBold: true),
                    ] else ...[
                      Text('Dates: ${req.dateRange} (${req.duration})'),
                      Text('Leave Grant Required: ${req.leaveGrantRequired ? 'Yes' : 'No'}'),
                      if (req.contactAddress != null && req.contactAddress!.isNotEmpty)
                        Text('Contact Address: ${req.contactAddress}'),
                    ],
                    const SizedBox(height: 16),

                    if (loading)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else if (approvals.isNotEmpty) ...[
                      buildSectionHeader('Previous Approval History'),
                      ...approvals.map((a) {
                        final action = a['action']?.toString() ?? '';
                        final c = a['comment']?.toString() ?? '';
                        final ts = a['timestamp']?.toString() ?? '';
                        final name = a['approver_name']?.toString() ?? 'Approver';
                        final level = (a['level'] as num?)?.toInt() ?? 0;
                        
                        List<Widget> detailWidgets = [];
                        
                        // Extract stage-specific data from the approval record
                        if (req.type.toLowerCase() == 'leave duty station') {
                          if (level == 1 && a['accountant_funds_available'] != null) {
                            detailWidgets.add(Text('Funds Available: ${a['accountant_funds_available'] == true ? "Yes" : "No"}'));
                          } else if (level == 2 && a['hod_trip_recommendation'] != null) {
                            detailWidgets.add(Text('Recommendation: ${a['hod_trip_recommendation']}'));
                          } else if (level == 3 && a['admin_trip_approval_details'] != null) {
                            detailWidgets.add(Text('Approval Details: ${a['admin_trip_approval_details']}'));
                          }
                        } else {
                          if (level == 1) {
                            if (a['hod_recommended_from'] != null) {
                              detailWidgets.add(Text('Recommended: ${a['hod_recommended_from']} to ${a['hod_recommended_to']}'));
                            }
                            if (a['hod_not_recommended_reason'] != null && a['hod_not_recommended_reason'].toString().isNotEmpty) {
                              detailWidgets.add(Text('Reason: ${a['hod_not_recommended_reason']}'));
                            }
                          } else if (level == 2) {
                            if (a['hr_annual_entitlement'] != null) {
                              detailWidgets.add(Text('Entitlement: ${a['hr_annual_entitlement']} days'));
                            }
                            if (a['hr_balance_if_approved'] != null) {
                              detailWidgets.add(Text('Balance: ${a['hr_balance_if_approved']} days'));
                            }
                            if (a['hr_leave_grant_status'] != null) {
                              detailWidgets.add(Text('Leave Grant: ${a['hr_leave_grant_status']}'));
                            }
                          } else if (level == 3) {
                            if (a['admin_granted_from'] != null) {
                              detailWidgets.add(Text('Granted: ${a['admin_granted_from']} to ${a['admin_granted_to']}'));
                            }
                            if (a['admin_total_days_approved'] != null) {
                              detailWidgets.add(Text('Total Days: ${a['admin_total_days_approved']}'));
                            }
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(action == 'approved' ? Icons.check_circle : Icons.cancel,
                                      size: 16, color: action == 'approved' ? Colors.green : AppTheme.paleRed),
                                  const SizedBox(width: 8),
                                  Text('$name - ${action.toUpperCase()}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Spacer(),
                                  Text(ts.split('T')[0], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              if (c.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Comment: $c', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                              ],
                              if (detailWidgets.isNotEmpty) ...[
                                const Divider(height: 12),
                                ...detailWidgets.map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: DefaultTextStyle(
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textLightBlue),
                                    child: w,
                                  ),
                                )),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Stage-specific Form - Show each user their own approval stage
                    if (req.type.toLowerCase() == 'leave duty station') ...[
                      // Accountant Section (Level 1)
                      if (userApprovalLevel == 1) ...[
                        buildSectionHeader('Section C: Certificate of Availability of Funds (Accountant)'),
                        if (userExistingApproval != null && userExistingApproval.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Approval - Completed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Funds Available: ${userExistingApproval['accountant_funds_available'] == true ? "YES" : "NO"}',
                                  style: TextStyle(fontSize: 13, color: Colors.green[600]),
                                ),
                                if (userExistingApproval['timestamp'] != null)
                                  Text(
                                    'Approved: ${userExistingApproval['timestamp'].toString().split('T')[0]}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                if (userExistingApproval['comment'] != null && userExistingApproval['comment'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Comment: ${userExistingApproval['comment']}',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                          CheckboxListTile(
                            title: const Text('I certify that funds are available to meet the total cost of the proposed trip'),
                            value: accountantFundsAvailable,
                            onChanged: (v) => setModalState(() => accountantFundsAvailable = v!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                      // HOD Section (Level 2)
                      if (userApprovalLevel == 2) ...[
                        buildSectionHeader('Section D: Recommendation from H.O.D'),
                        if (userExistingApproval != null && userExistingApproval.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Recommendation - Completed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (userExistingApproval['hod_trip_recommendation'] != null)
                                  Text(
                                    'Recommendation: ${userExistingApproval['hod_trip_recommendation']}',
                                    style: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                if (userExistingApproval['timestamp'] != null)
                                  Text(
                                    'Recommended: ${userExistingApproval['timestamp'].toString().split('T')[0]}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                if (userExistingApproval['comment'] != null && userExistingApproval['comment'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Comment: ${userExistingApproval['comment']}',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: hodTripRecommendationController,
                            decoration: const InputDecoration(labelText: 'Trip Recommendation', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                        ],
                      ],
                      // Admin Section (Level 3)
                      if (userApprovalLevel == 3) ...[
                        buildSectionHeader('Section E: Approval (Principal Administrator)'),
                        if (userExistingApproval != null && userExistingApproval.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Approval - Completed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (userExistingApproval['admin_trip_approval_details'] != null)
                                  Text(
                                    'Approval Details: ${userExistingApproval['admin_trip_approval_details']}',
                                    style: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                if (userExistingApproval['timestamp'] != null)
                                  Text(
                                    'Approved: ${userExistingApproval['timestamp'].toString().split('T')[0]}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                if (userExistingApproval['comment'] != null && userExistingApproval['comment'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Comment: ${userExistingApproval['comment']}',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: adminTripDetailsController,
                            decoration: const InputDecoration(labelText: 'Approval Details', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ] else ...[
                      // Leave Request Sections
                      // HOD Section (Level 1)
                      if (userApprovalLevel == 1) ...[
                        buildSectionHeader('Section B: H.O.D / Unit Incharge'),
                        if (userExistingApproval != null && userExistingApproval.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Recommendation - Completed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (userExistingApproval['hod_recommended_from'] != null && userExistingApproval['hod_recommended_to'] != null)
                                  Text(
                                    'Recommended: ${userExistingApproval['hod_recommended_from']} to ${userExistingApproval['hod_recommended_to']}',
                                    style: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                if (userExistingApproval['hod_not_recommended_reason'] != null && userExistingApproval['hod_not_recommended_reason'].toString().isNotEmpty)
                                  Text(
                                    'Reason: ${userExistingApproval['hod_not_recommended_reason']}',
                                    style: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                if (userExistingApproval['timestamp'] != null)
                                  Text(
                                    'Recommended: ${userExistingApproval['timestamp'].toString().split('T')[0]}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                if (userExistingApproval['comment'] != null && userExistingApproval['comment'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Comment: ${userExistingApproval['comment']}',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: buildDateField('Recommended From', hodFrom, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => hodFrom = d);
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildDateField('Recommended To', hodTo, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => hodTo = d);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: hodReasonController,
                            decoration: const InputDecoration(labelText: 'Reason if not recommended', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                        ],
                      ],
                      // HR Section (Level 2)
                      if (userApprovalLevel == 2) ...[
                        buildSectionHeader('Section C: Human Resources'),
                        if (userExistingApproval != null && userExistingApproval.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Review - Completed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (userExistingApproval['hr_annual_entitlement'] != null)
                                  Text('Annual Entitlement: ${userExistingApproval['hr_annual_entitlement']} days', style: TextStyle(fontSize: 13, color: Colors.green[600])),
                                if (userExistingApproval['hr_balance_if_approved'] != null)
                                  Text('Balance if Approved: ${userExistingApproval['hr_balance_if_approved']} days', style: TextStyle(fontSize: 13, color: Colors.green[600])),
                                if (userExistingApproval['hr_leave_grant_status'] != null)
                                  Text('Leave Grant Status: ${userExistingApproval['hr_leave_grant_status']}', style: TextStyle(fontSize: 13, color: Colors.green[600])),
                                if (userExistingApproval['timestamp'] != null)
                                  Text('Reviewed: ${userExistingApproval['timestamp'].toString().split('T')[0]}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                if (userExistingApproval['comment'] != null && userExistingApproval['comment'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Comment: ${userExistingApproval['comment']}',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: hrEntitlementController,
                            decoration: const InputDecoration(labelText: 'Annual Entitlement (days)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: buildDateField('Entitlement Taken From', hrEntTakenFrom, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => hrEntTakenFrom = d);
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildDateField('Entitlement Taken To', hrEntTakenTo, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => hrEntTakenTo = d);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: buildDateField('Last Leave From', hrLastLeaveFrom, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => hrLastLeaveFrom = d);
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildDateField('Last Leave To', hrLastLeaveTo, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => hrLastLeaveTo = d);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: hrLastLeaveDaysController,
                                  decoration: const InputDecoration(labelText: 'Last Leave Days', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: hrBalanceController,
                                  decoration: const InputDecoration(labelText: 'Balance if approved', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: hrLeaveGrantStatus,
                            decoration: const InputDecoration(labelText: 'Leave Grant Status', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'given', child: Text('Given')),
                              DropdownMenuItem(value: 'already_taken', child: Text('Already Taken')),
                              DropdownMenuItem(value: 'not_required', child: Text('Not Required')),
                            ],
                            onChanged: (v) => setModalState(() => hrLeaveGrantStatus = v!),
                          ),
                        ],
                      ],
                      // Admin Section (Level 3)
                      if (userApprovalLevel == 3) ...[
                        buildSectionHeader('Section D: Hospital Administrator'),
                        if (userExistingApproval != null && userExistingApproval.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Approval - Completed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (userExistingApproval['admin_granted_from'] != null && userExistingApproval['admin_granted_to'] != null)
                                  Text(
                                    'Granted: ${userExistingApproval['admin_granted_from']} to ${userExistingApproval['admin_granted_to']}',
                                    style: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                if (userExistingApproval['admin_total_days_approved'] != null)
                                  Text(
                                    'Total Days Approved: ${userExistingApproval['admin_total_days_approved']}',
                                    style: TextStyle(fontSize: 13, color: Colors.green[600]),
                                  ),
                                if (userExistingApproval['timestamp'] != null)
                                  Text(
                                    'Approved: ${userExistingApproval['timestamp'].toString().split('T')[0]}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                if (userExistingApproval['comment'] != null && userExistingApproval['comment'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Comment: ${userExistingApproval['comment']}',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: buildDateField('Granted From', adminFrom, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => adminFrom = d);
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildDateField('Granted To', adminTo, () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                  if (d != null) setModalState(() => adminTo = d);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: adminTotalDaysController,
                            decoration: const InputDecoration(labelText: 'Total Days Approved', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ],

                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'General Comment (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => comment = v,
                    ),
                    const SizedBox(height: 24),
                    // Only show action buttons if user hasn't already approved at their level
                    if (canApprove) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await RequestsService.denyRequest(req.id);
                                  if (mounted) Navigator.of(ctx).pop();
                                  await _loadRequests();
                                } catch (_) {}
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.paleRed,
                                side: const BorderSide(color: AppTheme.paleRed),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                            try {
                              Map<String, dynamic> extraFields = {'comment': comment};
                              
                              // Only include fields that are relevant to the current user's role
                              if (req.type.toLowerCase() == 'leave duty station') {
                                if (userApprovalLevel == 1) {
                                  extraFields.addAll({'accountant_funds_available': accountantFundsAvailable});
                                } else if (userApprovalLevel == 2) {
                                  extraFields.addAll({'hod_trip_recommendation': hodTripRecommendationController.text});
                                } else if (userApprovalLevel == 3) {
                                  extraFields.addAll({'admin_trip_approval_details': adminTripDetailsController.text});
                                }
                              } else {
                                if (userApprovalLevel == 1) {
                                  extraFields.addAll({
                                    'hod_recommended_from': hodFrom?.toIso8601String().split('T').first,
                                    'hod_recommended_to': hodTo?.toIso8601String().split('T').first,
                                    'hod_not_recommended_reason': hodReasonController.text,
                                  });
                                } else if (userApprovalLevel == 2) {
                                  extraFields.addAll({
                                    'hr_annual_entitlement': double.tryParse(hrEntitlementController.text),
                                    'hr_entitlement_taken_from': hrEntTakenFrom?.toIso8601String().split('T').first,
                                    'hr_entitlement_taken_to': hrEntTakenTo?.toIso8601String().split('T').first,
                                    'hr_last_leave_from': hrLastLeaveFrom?.toIso8601String().split('T').first,
                                    'hr_last_leave_to': hrLastLeaveTo?.toIso8601String().split('T').first,
                                    'hr_last_leave_days': double.tryParse(hrLastLeaveDaysController.text),
                                    'hr_balance_if_approved': double.tryParse(hrBalanceController.text),
                                    'hr_leave_grant_status': hrLeaveGrantStatus,
                                  });
                                } else if (userApprovalLevel == 3) {
                                  extraFields.addAll({
                                    'admin_granted_from': adminFrom?.toIso8601String().split('T').first,
                                    'admin_granted_to': adminTo?.toIso8601String().split('T').first,
                                    'admin_total_days_approved': double.tryParse(adminTotalDaysController.text),
                                  });
                                }
                              }

                              await RequestsService.approveRequest(req.id, extraFields: extraFields);
                                if (mounted) Navigator.of(ctx).pop();
                                await _loadRequests();
                              } catch (_) {}
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Submit Approval'),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.skyBlue,
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
                color: AppTheme.skyBlue,
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
                color: AppTheme.skyBlue.withValues(alpha: 0.3),
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
                    ? AppTheme.lightGold.withValues(alpha: 0.1)
                    : AppTheme.skyBlue.withValues(alpha: 0.1),
                child: Text(
                  req.userName.isNotEmpty ? req.userName[0] : '?',
                  style: TextStyle(
                    color: isOwnRequest ? AppTheme.lightGold : AppTheme.skyBlue,
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
                              color: AppTheme.lightGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MY REQUEST',
                              style: TextStyle(
                                color: AppTheme.lightGold,
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
                        color: AppTheme.skyBlue,
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
                  Icon(Icons.hourglass_empty, size: 16, color: AppTheme.lightGold),
                  SizedBox(width: 8),
                  Text(
                    'Pending Superior Approval',
                    style: TextStyle(
                      color: AppTheme.lightGold,
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
                      foregroundColor: AppTheme.paleRed,
                      side: const BorderSide(color: AppTheme.paleRed),
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
                    onPressed: () => _showApprovalDetail(context, req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Review'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

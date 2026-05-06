import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/leave_form_widget.dart';
import '../../services/requests_service.dart';
import '../../services/auth_storage.dart';
import '../../services/complete_user_profile_service.dart';
import '../../services/lookup_service.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  List<AdminTeamRequest> _myRequests = [];
  List<AdminTeamRequest> _teamRequests = [];
  List<LeaveBalance> _leaveBalances = [];
  CompleteUserProfile? _userProfile;
  List<Grade> _grades = [];
  int _userAnnualLeaveDays = 21; // Default fallback
  String? _userRole;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserRole(),
      _loadRequests(),
      _loadLeaveBalances(),
      _loadUserProfile(),
      _loadGrades(),
    ]);
    _calculateUserAnnualLeaveDays();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      return;
    }
    _loadRequests();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await AuthStorage.getUserRole();
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await CompleteUserProfileService.getCompleteUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading user profile: $e');
      }
    }
  }

  Future<void> _loadGrades() async {
    try {
      final gradesList = await LookupService.getGrades();
      if (mounted) {
        setState(() {
          _grades = gradesList;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading grades: $e');
      }
    }
  }

  void _calculateUserAnnualLeaveDays() {
    if (_userProfile?.gradeId != null && _grades.isNotEmpty) {
      // Find user's grade based on their grade_id
      final userGrade = _grades.firstWhere(
        (grade) => grade.id == _userProfile!.gradeId,
        orElse: () => _grades.firstWhere(
          (grade) => grade.name == 'Grade D', // Default fallback
          orElse: () => _grades.first, // Last resort fallback
        ),
      );
      
      setState(() {
        _userAnnualLeaveDays = userGrade.annualLeaveDays;
      });
    }
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

  
  int? _getUserApprovalLevelForRequest(AdminTeamRequest req) {
    if (_userRole == null) return null;
    final r = _userRole!.toLowerCase().trim();
    final isSystemAdmin = r.contains('system admin') || r.contains('system administrator') || r.contains('sysadmin') || r.contains('it admin');
    if (isSystemAdmin) return null;
    final isHod = r.contains('hod') || r.contains('head of department') || r.contains('unit incharge') || r.contains('unit in charge') || r.contains('unit head') || r.contains('department head') || r.contains('department');
    final isHr = r.contains('hr') || r.contains('human resources') || r.contains('human resource');
    final isHospitalAdmin = r.contains('hospital administrator') || r.contains('principal administrator');
    final isAccountant = r.contains('accountant') || r.contains('finance');
    if (req.type.toLowerCase() == 'leave duty station') {
      if (isAccountant) return 1;
      if (isHod) return 2;
      if (isHospitalAdmin) return 3;
    } else {
      if (isHod) return 1;
      if (isHr) return 2;
      if (isHospitalAdmin) return 3;
    }
    return null;
  }

  Future<void> _loadLeaveBalances() async {
    try {
      final data = await RequestsService.getLeaveBalances();
      if (!mounted) return;
      setState(() {
        _leaveBalances = data;
      });
    } catch (e) {
      if (!mounted) return;
      // Silently fail for now, will use fallback values
    }
  }

  Future<void> _loadRequests() async {
    try {
      // Load my requests and team requests separately
      final myRequestsFuture = RequestsService.getMyAdminRequests();
      final teamRequestsFuture = RequestsService.getAdminPendingRequests();

      final results = await Future.wait([
        myRequestsFuture,
        teamRequestsFuture,
      ]);

      // Load leave balances separately to avoid void result issue
      await _loadLeaveBalances();

      if (!mounted) return;

      setState(() {
        _myRequests = results[0];
        _teamRequests = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        print('Error loading admin requests: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load requests: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadUserRole(),
      _loadRequests(),
      _loadLeaveBalances(),
      _loadUserProfile(),
      _loadGrades(),
    ]);
    _calculateUserAnnualLeaveDays();
  }

  Future<void> _withdrawRequest(String requestId) async {
    try {
      await RequestsService.withdrawRequest(requestId);
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request withdrawn successfully')),
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
                          _buildAddButton(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildLeaveBalanceSummary(context),
                      const SizedBox(height: 24),
                      _buildRequestStatusSummary(context),
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
    // Find annual leave balance for the form
    final annualBalance = _leaveBalances.firstWhere(
      (balance) => balance.leaveType.toLowerCase().contains('annual'),
      orElse: () => LeaveBalance(
        leaveType: 'annual_leave',
        allocatedDays: _userAnnualLeaveDays,
        usedDays: 0,
        bonusDays: 0,
        remainingDays: _userAnnualLeaveDays,
        updatedAt: '',
      ),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Leave form widget
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LeaveFormWidget(
                    userRole: _userRole,
                    isAdmin: true,
                    leaveBalance: annualBalance,
                    userAnnualLeaveDays: _userAnnualLeaveDays,
                    onSubmitted: () {
                      Navigator.of(ctx).pop();
                      _loadRequests();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceSummary(BuildContext context) {
    // Find annual leave balance from API
    final annualBalance = _leaveBalances.firstWhere(
      (balance) => balance.leaveType.toLowerCase().contains('annual'),
      orElse: () => LeaveBalance(
        leaveType: 'annual_leave',
        allocatedDays: _userAnnualLeaveDays, // Use user's grade-based allocation
        usedDays: 0,
        bonusDays: 0,
        remainingDays: _userAnnualLeaveDays, // Use user's grade-based allocation
        updatedAt: '',
      ),
    );
    
    // Calculate percentage
    final double annualPercentage = annualBalance.allocatedDays > 0 
        ? (annualBalance.usedDays / annualBalance.allocatedDays * 100) 
        : 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.beach_access_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'My Leave Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'This Year',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _enhancedLeaveCard(
            usedDays: annualBalance.usedDays,
            totalDays: annualBalance.allocatedDays,
            remainingDays: annualBalance.remainingDays,
            percentage: annualPercentage,
            label: 'Annual Leave (${_userProfile?.gradeName ?? 'Grade Based'})',
            icon: Icons.event_available,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStatusSummary(BuildContext context) {
    // Count requests by status for both my and team requests
    int myApprovedCount = 0;
    int myPendingCount = 0;
    int teamPendingCount = 0;

    // Count my requests
    for (var request in _myRequests) {
      final status = request.status.toLowerCase();
      if (status == 'approved') {
        myApprovedCount++;
      } else if (status == 'pending') {
        myPendingCount++;
      }
    }

    // Count team pending requests
    for (var request in _teamRequests) {
      if (request.status.toLowerCase() == 'pending') {
        teamPendingCount++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: AppTheme.skyBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Request Status Overview',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _requestStatusCard(
                  count: myApprovedCount,
                  label: 'My Approved',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _requestStatusCard(
                  count: myPendingCount,
                  label: 'My Pending',
                  icon: Icons.pending,
                  color: AppTheme.lightGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _requestStatusCard(
                  count: teamPendingCount,
                  label: 'Team Pending',
                  icon: Icons.people,
                  color: AppTheme.skyBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _enhancedLeaveCard({
    required int usedDays,
    required int totalDays,
    required int remainingDays,
    required double percentage,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color.withValues(alpha: 0.9),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '$usedDays',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'used',
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$remainingDays left',
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _requestStatusCard({
    required int count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color.withValues(alpha: 0.9),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
        if (_myRequests.isEmpty)
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

  Future<void> _handleWithdrawAction(BuildContext context, AdminTeamRequest request) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Request'),
        content: Text(
          'Are you sure you want to withdraw your ${request.type} request?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.paleRed,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _withdrawRequest(request.id);
    }
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
          if (req.status.toLowerCase() == 'pending')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleWithdrawAction(context, req),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.paleRed,
                  side: const BorderSide(color: AppTheme.paleRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Withdraw Request',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
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
        if (_teamRequests.isEmpty)
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
          Builder(
            builder: (context) {
              final level = _getUserApprovalLevelForRequest(req);
              if (level == null) {
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showApprovalDetail(context, req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ],
                );
              }
              return Row(
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
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showApprovalDetail(BuildContext context, AdminTeamRequest req) async {
    String comment = '';
    String? userRole;
    
    // Get current user role
    try {
      userRole = await AuthStorage.getUserRole();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user role: $e');
      }
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

    

    // Helper function to get user's approval level based on role
    int? getUserApprovalLevel() {
      if (userRole == null) return null;
      final r = userRole.toLowerCase().trim();
      final isSystemAdmin = r.contains('system admin') || r.contains('system administrator') || r.contains('sysadmin') || r.contains('it admin');
      if (isSystemAdmin) return null;
      final isHod = r.contains('hod') || r.contains('head of department') || r.contains('unit incharge') || r.contains('unit in charge') || r.contains('unit head') || r.contains('department head') || r.contains('unit in-charge');
      final isHr = r.contains('hr') || r.contains('human resources') || r.contains('human resource');
      final isHospitalAdmin = r.contains('hospital administrator') || r.contains('principal administrator');
      final isAccountant = r.contains('accountant') || r.contains('finance');
      
      if (req.type.toLowerCase() == 'leave duty station') {
        if (isAccountant) return 1;
        if (isHod) return 2;
        if (isHospitalAdmin) return 3;
      } else {
        if (isHod) return 1;
        if (isHr) return 2;
        if (isHospitalAdmin) return 3;
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

    if (!context.mounted) return;
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
                            initialValue: hrLeaveGrantStatus,
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
                    // Only show General Comment field if user can approve
                    if (canApprove) ...[
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'General Comment (optional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => comment = v,
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Only show action buttons if user hasn't already approved at their level
                    if (canApprove) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await RequestsService.denyRequest(req.id);
                                  if (ctx.mounted) Navigator.of(ctx).pop();
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
                                if (ctx.mounted) Navigator.of(ctx).pop();
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

}

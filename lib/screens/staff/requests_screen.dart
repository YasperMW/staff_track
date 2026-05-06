import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/leave_form_widget.dart';
import '../../services/requests_service.dart';
import '../../services/complete_user_profile_service.dart';
import '../../services/lookup_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> requestsHistory = [];
  List<LeaveBalance> leaveBalances = [];
  bool isLoading = false;
  CompleteUserProfile? userProfile;
  List<Grade> grades = [];
  int userAnnualLeaveDays = 21;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRequests(),
      _loadLeaveBalances(),
      _loadUserProfile(),
      _loadGrades(),
    ]);
    _calculateUserAnnualLeaveDays();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await CompleteUserProfileService.getCompleteUserProfile();
      if (mounted) {
        setState(() {
          userProfile = profile;
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
          grades = gradesList;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading grades: $e');
      }
    }
  }

  void _calculateUserAnnualLeaveDays() {
    if (userProfile?.gradeId != null && grades.isNotEmpty) {
      // Find user's grade based on their grade_id
      final userGrade = grades.firstWhere(
        (grade) => grade.id == userProfile!.gradeId,
        orElse: () => grades.firstWhere(
          (grade) => grade.name == 'Grade D', // Default fallback
          orElse: () => grades.first, // Last resort fallback
        ),
      );
      
      setState(() {
        userAnnualLeaveDays = userGrade.annualLeaveDays;
      });
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await RequestsService.getMyRequests();
      if (!mounted) return;
      setState(() {
        requestsHistory = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        requestsHistory = [];
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load requests')),
        );
      }
    }
  }

  Future<void> _loadLeaveBalances() async {
    try {
      final data = await RequestsService.getLeaveBalances();
      if (!mounted) return;
      setState(() {
        leaveBalances = data;
      });
    } catch (e) {
      if (!mounted) return;
      // Silently fail for now, will use fallback values
    }
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

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadRequests(),
      _loadLeaveBalances(),
      _loadUserProfile(),
      _loadGrades(),
    ]);
    _calculateUserAnnualLeaveDays();
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Leave & WFH requests',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                        ),
                        _buildAddButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSummaryGrid(context),
                    const SizedBox(height: 24),
                    _buildRequestStatusCards(context),
                    const SizedBox(height: 24),
                    _buildRequestsList(context),
                    const SizedBox(height: 24),
                  ],
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
            color: AppTheme.skyBlue.withValues(alpha:0.3),
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

  Widget _buildSummaryGrid(BuildContext context) {
    // Find annual leave balance from API
    final annualBalance = leaveBalances.firstWhere(
      (balance) => balance.leaveType.toLowerCase().contains('annual'),
      orElse: () => LeaveBalance(
        leaveType: 'annual_leave',
        allocatedDays: userAnnualLeaveDays, // Use user's grade-based allocation
        usedDays: 0,
        bonusDays: 0,
        remainingDays: userAnnualLeaveDays, // Use user's grade-based allocation
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
                'Leave Balance Summary',
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
            label: 'Annual Leave (${userProfile?.gradeName ?? 'Grade Based'})',
            icon: Icons.event_available,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStatusCards(BuildContext context) {
    // Count requests by status
    int approvedCount = 0;
    int pendingCount = 0;
    int rejectedCount = 0;

    for (var request in requestsHistory) {
      final status = request['status']?.toString().toLowerCase();
      if (status == 'approved') {
        approvedCount++;
      } else if (status == 'pending') {
        pendingCount++;
      } else if (status == 'rejected' || status == 'denied') {
        rejectedCount++;
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
                'Request Status Summary',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'All Time',
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
                  count: approvedCount,
                  label: 'Approved',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _requestStatusCard(
                  count: pendingCount,
                  label: 'Pending',
                  icon: Icons.pending,
                  color: AppTheme.lightGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _requestStatusCard(
                  count: rejectedCount,
                  label: 'Rejected',
                  icon: Icons.cancel,
                  color: AppTheme.paleRed,
                ),
              ),
            ],
          ),
        ],
      ),
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
      case 'Denied':
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

    return InkWell(
      onTap: () => _showApprovalHistory(context, request),
      child: Container(
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
                request['date_range'] ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 16, color: AppTheme.textLightBlue),
              const SizedBox(width: 4),
              Text(
                request['duration'] ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request['description'] ?? '',
                  style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 13),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.skyBlue, size: 20),
            ],
          ),
          if (request['status'] == 'Pending') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleWithdrawAction(context, request),
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleWithdrawAction(BuildContext context, Map<String, dynamic> request) async {
    final requestId = request['id']?.toString();
    if (requestId == null || requestId.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Request'),
        content: Text(
          'Are you sure you want to withdraw your ${request['type']} request?\n\n'
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
      await _withdrawRequest(requestId);
    }
  }

  Future<void> _showApprovalHistory(BuildContext context, Map<String, dynamic> request) async {
    final requestId = request['id']?.toString();
    if (requestId == null || requestId.isEmpty) return;
    List<Map<String, dynamic>> approvals = [];
    bool loading = true;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> load() async {
              try {
                final data = await RequestsService.getRequestApprovals(requestId);
                setState(() {
                  approvals = data;
                  loading = false;
                });
              } catch (_) {
                setState(() {
                  approvals = [];
                  loading = false;
                });
              }
            }
            if (loading) {
              load();
            }
            return Container(
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
                        const Text(
                          'Approval Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Request Type: ${request['type']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Current Status: ${request['status']}', style: const TextStyle(color: AppTheme.skyBlue)),
                    const SizedBox(height: 16),
                    
                    if (loading)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else if (approvals.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Waiting for initial review...', style: TextStyle(color: AppTheme.textLightBlue)),
                        ),
                      )
                    else
                      ...approvals.map((a) {
                        final action = a['action']?.toString() ?? '';
                        final comment = a['comment']?.toString() ?? '';
                        final ts = a['timestamp']?.toString() ?? '';
                        final name = a['approver_name']?.toString() ?? 'Approver';
                        final level = (a['level'] as num?)?.toInt() ?? 0;
                        
                        List<Widget> detailWidgets = [];
                        final type = (request['type'] as String).toLowerCase();

                        if (type.contains('duty station')) {
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
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    action == 'approved' ? Icons.check_circle : Icons.cancel,
                                    size: 18,
                                    color: action == 'approved' ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$name - ${action.toUpperCase()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    ts.split('T')[0],
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Comment: $comment',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
                              if (detailWidgets.isNotEmpty) ...[
                                const Divider(height: 16),
                                ...detailWidgets.map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateRequestSheet() async {
    // Find annual leave balance for the form
    final annualBalance = leaveBalances.firstWhere(
      (balance) => balance.leaveType.toLowerCase().contains('annual'),
      orElse: () => LeaveBalance(
        leaveType: 'annual_leave',
        allocatedDays: userAnnualLeaveDays,
        usedDays: 0,
        bonusDays: 0,
        remainingDays: userAnnualLeaveDays,
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
                    userRole: null,
                    isAdmin: false,
                    leaveBalance: annualBalance,
                    userAnnualLeaveDays: userAnnualLeaveDays,
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
}

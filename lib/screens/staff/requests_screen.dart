import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/tile_date_picker.dart';
import '../../widgets/single_date_picker.dart';
import '../../services/requests_service.dart';

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

  Future<void> _onRefresh() async {
    await _loadRequests();
  }

  int _parseDuration(String? duration) {
    if (duration == null) return 0;
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  Map<String, int> _calculateStats() {
    int annualUsed = 0;
    int sickUsed = 0;
    int personalUsed = 0;

    for (var request in requestsHistory) {
      // The status from API is capitalized in get_my_requests
      if (request['status'] == 'Approved') {
        int days = _parseDuration(request['duration']);
        String type = (request['type'] as String).toLowerCase();

        if (type.contains('annual')) {
          annualUsed += days;
        } else if (type.contains('sick')) {
          sickUsed += days;
        } else if (type.contains('personal')) {
          personalUsed += days;
        } else if (type == 'leave') {
          // Default 'Leave' to Annual if no specific type
          annualUsed += days;
        }
      }
    }

    return {
      'annual': annualUsed,
      'sick': sickUsed,
      'personal': personalUsed,
    };
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
                physics: const AlwaysScrollableScrollPhysics(),
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
                      _buildRequestsList(context),
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
    final stats = _calculateStats();
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(context, '${stats['annual']}', '/ 21 Annual')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard(context, '${stats['sick']}', '/ 10 Sick')),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard(context, '${stats['personal']}', '/ 5 Personal')),
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
              color: AppTheme.skyBlue,
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
          ],
        ),
      ),
    );
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
                      }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildCostField(String label, TextEditingController controller, StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          const Text('K '),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
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
        bool leaveGrantRequired = false;
        final contactAddressController = TextEditingController();
        
        // Trip fields
        final reasonForLeavingController = TextEditingController();
        DateTime? travelDate;
        final travelPlaceController = TextEditingController();
        final accCostController = TextEditingController();
        final bfCostController = TextEditingController();
        final lunchCostController = TextEditingController();
        final supperCostController = TextEditingController();
        final transportCostController = TextEditingController();
        final fuelCostController = TextEditingController();
        
        bool isSubmitting = false;

        String formatDate(DateTime d) {
          return d.toIso8601String().split('T').first;
        }

        double? parseDouble(String val) => double.tryParse(val);

        double calculateTotal() {
          return (parseDouble(accCostController.text) ?? 0) +
                 (parseDouble(bfCostController.text) ?? 0) +
                 (parseDouble(lunchCostController.text) ?? 0) +
                 (parseDouble(supperCostController.text) ?? 0) +
                 (parseDouble(transportCostController.text) ?? 0) +
                 (parseDouble(fuelCostController.text) ?? 0);
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
                    leaveGrantRequired: leaveGrantRequired,
                    contactAddress: contactAddressController.text,
                    // Trip fields
                    reasonForLeaving: reasonForLeavingController.text,
                    travelDate: travelDate != null ? formatDate(travelDate!) : null,
                    travelPlace: travelPlaceController.text,
                    costAccommodation: parseDouble(accCostController.text),
                    costBreakfast: parseDouble(bfCostController.text),
                    costLunch: parseDouble(lunchCostController.text),
                    costSupper: parseDouble(supperCostController.text),
                    costPublicTransport: parseDouble(transportCostController.text),
                    costFuelLubricants: parseDouble(fuelCostController.text),
                    costTotal: calculateTotal(),
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
                child: SingleChildScrollView(
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
                          ChoiceChip(
                            label: const Text('Leave Duty Station'),
                            selected: selectedType == 'Leave Duty Station',
                            onSelected: (v) {
                              if (!v) return;
                              setSheetState(() {
                                selectedType = 'Leave Duty Station';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (selectedType == 'Leave Duty Station') ...[
                        const Text(
                          'Section A: Reason for leaving station',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.skyBlue),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: reasonForLeavingController,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'Reason(s)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Travel Date',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showSingleDatePicker(
                              context: ctx,
                              initialDate: travelDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              title: 'Select Travel Date',
                            );
                            if (picked != null) {
                              setSheetState(() {
                                travelDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(travelDate == null ? 'Select Date' : formatDate(travelDate!)),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Place where traveling to',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: travelPlaceController,
                          decoration: const InputDecoration(hintText: 'Place', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Section B: Cost of the trip (MK)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.skyBlue),
                        ),
                        const SizedBox(height: 12),
                        _buildCostField('Accommodation', accCostController, setSheetState),
                        _buildCostField('Breakfast', bfCostController, setSheetState),
                        _buildCostField('Lunch', lunchCostController, setSheetState),
                        _buildCostField('Supper', supperCostController, setSheetState),
                        _buildCostField('Public transport', transportCostController, setSheetState),
                        _buildCostField('Fuel & lubricants', fuelCostController, setSheetState),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('MK ${calculateTotal().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.skyBlue)),
                            ],
                          ),
                        ),
                      ] else ...[
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Leave Grant Required',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Switch(
                              value: leaveGrantRequired,
                              activeColor: AppTheme.skyBlue,
                              onChanged: (v) {
                                setSheetState(() {
                                  leaveGrantRequired = v;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Contact Address while on Leave',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: contactAddressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                ),
              );
            },
          ),
        );
      },
    );
  }
}

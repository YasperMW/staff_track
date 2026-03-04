import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/tile_date_picker.dart';
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
          Text(
            request['description'] ?? '',
            style: const TextStyle(color: AppTheme.textLightBlue),
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
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Approval History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (loading)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (approvals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No approval history', style: TextStyle(color: AppTheme.textLightBlue)),
                    )
                  else
                    Column(
                      children: approvals.map((a) {
                        final action = a['action']?.toString() ?? '';
                        final comment = a['comment']?.toString() ?? '';
                        final ts = a['timestamp']?.toString() ?? '';
                        return ListTile(
                          leading: Icon(
                            action == 'approved' ? Icons.check_circle : Icons.cancel,
                            color: action == 'approved' ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                          ),
                          title: Text(
                            action[0].toUpperCase() + action.substring(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            comment.isNotEmpty ? '$comment\n$ts' : ts,
                            style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
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
}

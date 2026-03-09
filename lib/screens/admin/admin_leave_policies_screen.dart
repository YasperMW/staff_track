import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_header.dart';
import '../../services/leave_policy_service.dart';

class AdminLeavePoliciesScreen extends StatefulWidget {
  const AdminLeavePoliciesScreen({super.key});
  @override
  State<AdminLeavePoliciesScreen> createState() => _AdminLeavePoliciesScreenState();
}

class _AdminLeavePoliciesScreenState extends State<AdminLeavePoliciesScreen> {
  bool _loading = true;
  List<LeavePolicyItem> _policies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await LeavePolicyService.listPolicies();
      setState(() {
        _policies = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load policies: $e')));
      }
    }
  }

  Future<void> _showApplyPolicySheet() async {
    String leaveType = 'annual_leave';
    int allocated = 21;
    int bonus = 0;
    String? roleName;
    String? departmentName;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Apply Leave Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: leaveType,
                items: const [
                  DropdownMenuItem(value: 'annual_leave', child: Text('Annual Leave')),
                  DropdownMenuItem(value: 'compassionate_leave', child: Text('Compassionate Leave')),
                  DropdownMenuItem(value: 'maternity', child: Text('Maternity')),
                  DropdownMenuItem(value: 'paternity', child: Text('Paternity')),
                  DropdownMenuItem(value: 'unpaid_leave', child: Text('Unpaid')),
                ],
                onChanged: (v) => leaveType = v ?? 'annual_leave',
                decoration: const InputDecoration(labelText: 'Leave Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: allocated.toString(),
                decoration: const InputDecoration(labelText: 'Allocated Days'),
                keyboardType: TextInputType.number,
                onChanged: (v) => allocated = int.tryParse(v) ?? allocated,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: bonus.toString(),
                decoration: const InputDecoration(labelText: 'Bonus Days'),
                keyboardType: TextInputType.number,
                onChanged: (v) => bonus = int.tryParse(v) ?? bonus,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Role Name (optional)'),
                onChanged: (v) => roleName = v.isEmpty ? null : v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Department Name (optional)'),
                onChanged: (v) => departmentName = v.isEmpty ? null : v,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await LeavePolicyService.applyPolicy(
                        leaveType: leaveType,
                        allocatedDays: allocated,
                        bonusDays: bonus,
                        roleName: roleName,
                        departmentName: departmentName,
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      await _load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy applied')));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.skyBlue, foregroundColor: Colors.white),
                  child: const Text('Apply Policy'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleHeader(title: 'Leave Policies'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.skyBlue))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Policies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton.icon(
                        onPressed: _showApplyPolicySheet,
                        icon: const Icon(Icons.tune, color: AppTheme.skyBlue),
                        label: const Text('Apply Policy', style: TextStyle(color: AppTheme.skyBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _policies.length,
                      itemBuilder: (ctx, i) {
                        final p = _policies[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.leaveType,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p.roleName ?? 'All Roles'} • ${p.departmentName ?? 'All Departments'}',
                                      style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text('${p.allocatedDays} + ${p.bonusDays}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

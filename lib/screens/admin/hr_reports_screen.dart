import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../widgets/tile_date_picker.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import '../../services/auth_storage.dart';
import '../../widgets/simple_header.dart';
import '../../services/organization_service.dart';

class HrReportsScreen extends StatefulWidget {
  const HrReportsScreen({super.key});

  @override
  State<HrReportsScreen> createState() => _HrReportsScreenState();
}

class _HrReportsScreenState extends State<HrReportsScreen> {
  bool _isLoadingStaff = false;
  List<dynamic> _staffList = [];
  List<DepartmentTodaySummary> _departments = [];
  dynamic _selectedStaff;
  DepartmentTodaySummary? _selectedDepartment;
  DateTime? _startDate;
  DateTime? _endDate;
  String _reportType = 'individual';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingStaff = true);
    try {
      final staffData = await OrganizationService.getAllStaff();
      final deptData = await OrganizationService.getAllDepartmentsToday();
      if (!mounted) return;
      setState(() {
        _staffList = staffData;
        _departments = deptData;
        _isLoadingStaff = false;
        _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
        _endDate = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStaff = false);
      _showError('Failed to load data: $e');
    }
  }

  Future<void> _generateReport() async {
    if (_reportType == 'department' && _selectedDepartment == null) {
      _showError('Please select a department');
      return;
    }
    if (_reportType == 'individual' && _selectedStaff == null) {
      _showError('Please select a staff member');
      return;
    }

    try {
      final startStr = _startDate?.toIso8601String().split('T')[0];
      final endStr = _endDate?.toIso8601String().split('T')[0];
      
      final params = <String>[];
      if (startStr != null) params.add('start_date=$startStr');
      if (endStr != null) params.add('end_date=$endStr');
      if (_reportType == 'department' && _selectedDepartment != null) {
        params.add('department_id=${_selectedDepartment!.departmentId}');
      }
      
      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      
      String url;
      if (_reportType == 'individual') {
        url = '${AppConfig.apiBaseUrl}/attendance/reports/attendance/pdf/${_selectedStaff['user_id']}$queryString';
      } else {
        url = '${AppConfig.apiBaseUrl}/attendance/reports/department/pdf$queryString';
      }
      
      final token = await AuthStorage.getToken();
      if (token == null) {
        _showError('Authentication required');
        return;
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating report...')));
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = _reportType == 'individual' 
            ? 'attendance_${_selectedStaff['surname'] ?? 'report'}_$stamp.pdf'
            : 'department_report_$stamp.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: _reportType == 'individual'
                ? 'Attendance Report - ${_selectedStaff['first_name']} ${_selectedStaff['surname']}'
                : 'Department Attendance Report',
          ),
        );
      } else {
        _showError('Failed to generate report: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error generating report: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.paleRed),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showTileDateRangePicker(
      context: context,
      initialStartDate: _startDate,
      initialEndDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      title: 'Select Date Range',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SimpleHeader(title: 'Generate Reports'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.skyBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportTypeSelector(),
              const SizedBox(height: 24),
              _buildDateRangeSelector(),
              const SizedBox(height: 24),
              if (_reportType == 'individual') _buildStaffSelector() else _buildDepartmentSelector(),
              const SizedBox(height: 32),
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Report Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTypeButton('individual', 'Staff Report', Icons.person)),
            const SizedBox(width: 12),
            Expanded(child: _buildTypeButton('department', 'Department', Icons.business)),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    final isSelected = _reportType == type;
    return GestureDetector(
      onTap: () => setState(() => _reportType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.skyBlue : Colors.transparent,
          border: Border.all(color: isSelected ? AppTheme.skyBlue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final startStr = _startDate != null ? dateFormat.format(_startDate!) : 'Select start';
    final endStr = _endDate != null ? dateFormat.format(_endDate!) : 'Select end';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Colors.grey),
                const SizedBox(width: 12),
                Text('$startStr - $endStr', style: const TextStyle(fontSize: 16)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

Widget _buildStaffSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Staff Member', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showStaffPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedStaff != null ? '${_selectedStaff['first_name']} ${_selectedStaff['surname']}' : 'Select staff member',
                    style: TextStyle(fontSize: 16, color: _selectedStaff != null ? Colors.black87 : Colors.grey),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Department', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showDepartmentPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.business, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDepartment?.departmentName ?? 'All Departments',
                    style: TextStyle(fontSize: 16, color: _selectedDepartment != null ? Colors.black87 : Colors.grey),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStaffPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _buildStaffPickerSheet(),
    );
  }

  Widget _buildStaffPickerSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Select Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoadingStaff
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _staffList.length,
                    itemBuilder: (ctx, index) {
                      final staff = _staffList[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.skyBlue,
                          child: Text('${staff['first_name']?[0]}${staff['surname']?[0]}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text('${staff['first_name']} ${staff['surname']}'),
                        subtitle: Text(staff['email'] ?? ''),
                        onTap: () {
                          setState(() => _selectedStaff = staff);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDepartmentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _buildDepartmentPickerSheet(),
    );
  }

  Widget _buildDepartmentPickerSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Select Department', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('All Departments'),
            leading: const Icon(Icons.business),
            onTap: () {
              setState(() => _selectedDepartment = null);
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _departments.length,
              itemBuilder: (ctx, index) {
                final dept = _departments[index];
                return ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(dept.departmentName),
                  onTap: () {
                    setState(() => _selectedDepartment = dept);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateReport,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate PDF Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.skyBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
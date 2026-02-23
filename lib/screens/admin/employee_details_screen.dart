import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../services/employees_service.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({super.key});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  List<Employee> employees = [];
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await EmployeesService.getAllEmployees();
      if (!mounted) return;
      setState(() {
        employees = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load employees')),
        );
      }
    }
  }

  List<Employee> get filteredEmployees {
    if (searchQuery.isEmpty) return employees;
    
    final query = searchQuery.toLowerCase();
    return employees.where((employee) {
      return employee.fullName.toLowerCase().contains(query) ||
             employee.email.toLowerCase().contains(query) ||
             (employee.departmentName?.toLowerCase().contains(query) ?? false) ||
             (employee.designation?.toLowerCase().contains(query) ?? false) ||
             employee.roleName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              subtitle: 'Employee Directory',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'All Employees',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: _buildEmployeesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search employees...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textLightBlue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    final activeCount = employees.where((e) => e.status.toLowerCase() == 'active').length;
    final totalDepartments = employees.map((e) => e.departmentName).where((d) => d != null).toSet().length;
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('$activeCount', 'Active')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('${employees.length}', 'Total')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('$totalDepartments', 'Departments')),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredEmployees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.2),
              ),
              const SizedBox(height: 16),
              Text(
                searchQuery.isEmpty ? 'No employees found' : 'No employees match your search',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ListView.builder(
        itemCount: filteredEmployees.length,
        itemBuilder: (context, index) {
          final employee = filteredEmployees[index];
          return _buildEmployeeCard(employee);
        },
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.roleName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: employee.status.toLowerCase() == 'active' 
                      ? Colors.green.withValues(alpha:0.1)
                      : Colors.grey.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  employee.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: employee.status.toLowerCase() == 'active' 
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (employee.departmentName != null) ...[
                const Icon(Icons.business_outlined, size: 16, color: AppTheme.textLightBlue),
                const SizedBox(width: 4),
                Text(
                  employee.departmentName!,
                  style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 12),
                ),
                const SizedBox(width: 16),
              ],
              if (employee.designation != null) ...[
                const Icon(Icons.work_outline, size: 16, color: AppTheme.textLightBlue),
                const SizedBox(width: 4),
                Text(
                  employee.designation!,
                  style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 12),
                ),
                const SizedBox(width: 16),
              ],
              const Icon(Icons.email_outlined, size: 16, color: AppTheme.textLightBlue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  employee.email,
                  style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

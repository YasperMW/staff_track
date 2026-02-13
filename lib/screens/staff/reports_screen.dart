import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Your work analytics',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatsGrid(context),
                    const SizedBox(height: 24),
                    _buildWeeklyHoursChart(context),
                    const SizedBox(height: 24),
                    _buildMonthlySummary(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha:0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ST JOHN'S HOSPITAL",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'HR Portal',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildReportStatCard(
                context: context,
                icon: Icons.access_time,
                value: '9h 02m',
                label: 'Avg Hours/Day',
                subLabel: 'This month',
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportStatCard(
                context: context,
                icon: Icons.trending_up,
                value: '96%',
                label: 'Punctuality',
                subLabel: '+2% vs last month',
                iconColor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReportStatCard(
                context: context,
                icon: Icons.calendar_today,
                value: '22 / 23',
                label: 'Days Worked',
                subLabel: 'Feb 2026',
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportStatCard(
                context: context,
                icon: Icons.bar_chart,
                value: '4h 30m',
                label: 'Overtime',
                subLabel: 'This month',
                iconColor: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required String subLabel,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
          Text(
            subLabel,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLightBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHoursChart(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                'Weekly Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Avg: 8.9h',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLightBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Custom Bar Chart Simulation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(context, 9.2, 'Mon'),
              _buildBar(context, 9.1, 'Tue'),
              _buildBar(context, 9.3, 'Wed', isToday: true),
              _buildBar(context, 8.5, 'Thu'),
              _buildBar(context, 9.0, 'Fri'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, double heightFactor, String day, {bool isToday = false}) {
    return Column(
      children: [
        Text(
          '${heightFactor}h',
          style: TextStyle(
            fontSize: 12, 
            color: isToday ? AppTheme.primaryBlue : AppTheme.textLightBlue,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: heightFactor * 15, // Scaling factor
          decoration: BoxDecoration(
            gradient: isToday 
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryBlue, Color(0xFF5D8BF4)],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha:0.2),
                    AppTheme.primaryBlue.withValues(alpha:0.1),
                  ],
                ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isToday ? [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha:0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
            color: isToday ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha:0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressRow(context, 'Regular Hours', '176h', 0.8),
          const SizedBox(height: 20),
          _buildProgressRow(context, 'Overtime', '4.5h', 0.1),
          const SizedBox(height: 20),
          _buildProgressRow(context, 'Leave Taken', '8h', 0.05),
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context, String label, String value, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.05),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
      ),
    ],
  );
}
}

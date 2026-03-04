import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/holidays_service.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_header.dart';
import '../../widgets/single_date_picker.dart';

class HolidaysManagementScreen extends StatefulWidget {
  const HolidaysManagementScreen({super.key});

  @override
  State<HolidaysManagementScreen> createState() => _HolidaysManagementScreenState();
}

class _HolidaysManagementScreenState extends State<HolidaysManagementScreen> {
  List<PublicHoliday> _holidays = [];
  List<PublicHoliday> _filteredHolidays = [];
  bool _isLoading = true;
  String _selectedYear = DateTime.now().year.toString();
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'institutional', 'public'

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Print loading details
      print('=== LOAD HOLIDAYS DEBUG ===');
      print('Selected year: ${_selectedYear}');
      print('Selected category: ${_selectedCategory}');
      print('Category filter: ${_selectedCategory == 'all' ? null : _selectedCategory}');
      
      final holidays = await HolidaysService.getHolidays(
        year: int.parse(_selectedYear),
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      
      print('Total holidays returned: ${holidays.length}');
      print('Holiday categories:');
      for (var holiday in holidays) {
        print('  - ${holiday.name}: ${holiday.category} (${holiday.source})');
      }
      
      setState(() {
        _holidays = holidays;
        _filteredHolidays = holidays;
        _isLoading = false;
      });
      
      print('Institutional holidays: ${holidays.where((h) => h.category == 'institutional').length}');
      print('Public holidays: ${holidays.where((h) => h.category == 'public').length}');
      print('Filtered holidays count: ${_filteredHolidays.length}');
      
    } catch (e) {
      print('Error loading holidays: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load holidays: $e')),
        );
      }
    }
  }

  void _filterHolidays() {
    setState(() {
      _filteredHolidays = _holidays.where((holiday) {
        final matchesSearch = holiday.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (holiday.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _showAddHolidaySheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddHolidaySheet(
        onHolidayAdded: (holiday) {
          _loadHolidays();
        },
      ),
    );
  }

  Future<void> _showEditHolidaySheet(PublicHoliday holiday) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => EditHolidaySheet(
        holiday: holiday,
        onHolidayUpdated: () {
          _loadHolidays();
        },
      ),
    );
  }

  Future<void> _deleteHoliday(PublicHoliday holiday) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Are you sure you want to delete "${holiday.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.paleRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Debug: Print delete attempt
        print('=== DELETE HOLIDAY UI DEBUG ===');
        print('Attempting to delete holiday: ${holiday.name}');
        print('Holiday ID: ${holiday.id}');
        
        await HolidaysService.deleteHoliday(holiday.id);
        print('Delete service call completed successfully');
        
        _loadHolidays();
        print('Holidays reloaded after delete');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Holiday deleted successfully')),
          );
        }
      } catch (e) {
        // Debug: Print error details
        print('=== DELETE HOLIDAY UI ERROR DEBUG ===');
        print('Error: $e');
        print('Error type: ${e.runtimeType}');
        print('Error stack trace: ${StackTrace.current}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete holiday: $e')),
          );
        }
      }
    }
  }

  Future<void> _fetchPublicHolidays() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final holidays = await HolidaysService.fetchPublicHolidays(
        int.parse(_selectedYear),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${holidays.length} public holidays')),
        );
        _loadHolidays(); // Reload to show the new holidays
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch public holidays: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendNotifications(PublicHoliday holiday) async {
    try {
      await NotificationsService.sendHolidayNotificationToAll(holiday);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Holiday notifications sent for ${holiday.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(
        title: 'Holidays Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _fetchPublicHolidays,
            tooltip: 'Fetch Public Holidays',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildFilters(),
                const SizedBox(height: 16),
                _buildUpcomingSection(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.skyBlue),
                  )
                : _buildHolidaysList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHolidaySheet,
        backgroundColor: AppTheme.skyBlue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Holiday',
      ),
    );
  }

  Widget _buildUpcomingSection() {
    return FutureBuilder<List<PublicHoliday>>(
      future: HolidaysService.getUpcomingHolidays(monthsAhead: 3),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 2,
            child: LinearProgressIndicator(color: AppTheme.skyBlue),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Holidays',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: items.take(5).map((h) {
                  final daysUntil = h.date.difference(DateTime.now()).inDays;
                  return ListTile(
                    leading: const Icon(Icons.event_available, color: AppTheme.skyBlue),
                    title: Text(h.name),
                    subtitle: Text(
                      '${DateFormat('EEEE, MMM d').format(h.date)} • in $daysUntil day${daysUntil == 1 ? '' : 's'}',
                      style: const TextStyle(color: AppTheme.textLightBlue, fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () => _sendNotifications(h),
                      child: const Text('Notify', style: TextStyle(color: AppTheme.skyBlue)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Public Holidays',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.skyBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_filteredHolidays.length} holidays',
            style: const TextStyle(
              color: AppTheme.skyBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search holidays...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.skyBlue),
                  ),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterHolidays();
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedYear,
                underline: const SizedBox(),
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem(
                    value: year.toString(),
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedYear = value;
                    });
                    _loadHolidays();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'All Holidays'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('institutional', 'Institutional'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('public', 'Public Holidays'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = value;
          });
          _loadHolidays();
        }
      },
      backgroundColor: Colors.grey.withValues(alpha: 0.2),
      selectedColor: AppTheme.skyBlue.withValues(alpha: 0.3),
      checkmarkColor: AppTheme.skyBlue,
    );
  }

  Widget _buildHolidaysList() {
    if (_filteredHolidays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No holidays found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first public holiday using the + button',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _filteredHolidays.length,
      itemBuilder: (context, index) {
        final holiday = _filteredHolidays[index];
        return _buildHolidayCard(holiday);
      },
    );
  }

  Widget _buildHolidayCard(PublicHoliday holiday) {
    final isInstitutional = holiday.category == 'institutional';
    final isFromAPI = holiday.source == 'government_api';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getHolidayTypeColor(holiday.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getHolidayTypeIcon(holiday.type),
                    color: _getHolidayTypeColor(holiday.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              holiday.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isInstitutional 
                                  ? AppTheme.lightGold.withValues(alpha: 0.2)
                                  : AppTheme.skyBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isInstitutional ? 'Institutional' : 'Public',
                              style: TextStyle(
                                fontSize: 10,
                                color: isInstitutional 
                                    ? AppTheme.lightGold 
                                    : AppTheme.skyBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (holiday.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          holiday.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isInstitutional) // Only show menu for institutional holidays
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _showEditHolidaySheet(holiday);
                          break;
                        case 'notify':
                          _sendNotifications(holiday);
                          break;
                        case 'delete':
                          _deleteHoliday(holiday);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'notify',
                        child: Row(
                          children: [
                            Icon(Icons.notifications, size: 16),
                            SizedBox(width: 8),
                            Text('Send Notifications'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: AppTheme.paleRed),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppTheme.paleRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(holiday.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                if (holiday.isRecurring) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Recurring',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.lightGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (isFromAPI) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'API',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHolidayTypeColor(String? type) {
    switch (type) {
      case 'national':
        return AppTheme.skyBlue;
      case 'religious':
        return AppTheme.paleRed;
      default:
        return AppTheme.lightGold;
    }
  }

  IconData _getHolidayTypeIcon(String? type) {
    switch (type) {
      case 'national':
        return Icons.flag;
      case 'religious':
        return Icons.church;
      default:
        return Icons.event;
    }
  }
}

class AddHolidaySheet extends StatefulWidget {
  final Function(PublicHoliday) onHolidayAdded;

  const AddHolidaySheet({super.key, required this.onHolidayAdded});

  @override
  State<AddHolidaySheet> createState() => _AddHolidaySheetState();
}

class _AddHolidaySheetState extends State<AddHolidaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedType = 'Institutional Holiday';
  bool _isRecurring = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showSingleDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
      title: 'Select Holiday Date',
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final holiday = await HolidaysService.createHoliday(
        name: _nameController.text.trim(),
        date: _selectedDate!,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _selectedType,
        category: 'institutional', // Always institutional for manual creation
        isRecurring: _isRecurring,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onHolidayAdded(holiday);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Holiday added successfully')),
        );
      }
    } catch (e) {
      // Debug: Print the error details
      print('=== HOLIDAY CREATION ERROR DEBUG ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add holiday: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Holiday',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Holiday Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter holiday name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                            : 'Select Date',
                        style: TextStyle(
                          color: _selectedDate != null 
                              ? null 
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Holiday Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Institutional Holiday', child: Text('Institutional Holiday')),
                  DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Recurring Yearly'),
                subtitle: const Text('This holiday will repeat every year'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.skyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Holiday'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class EditHolidaySheet extends StatefulWidget {
  final PublicHoliday holiday;
  final Function() onHolidayUpdated;

  const EditHolidaySheet({
    super.key,
    required this.holiday,
    required this.onHolidayUpdated,
  });

  @override
  State<EditHolidaySheet> createState() => _EditHolidaySheetState();
}

class _EditHolidaySheetState extends State<EditHolidaySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  DateTime? _selectedDate;
  late String _selectedType;
  late bool _isRecurring;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.holiday.name);
    _descriptionController = TextEditingController(text: widget.holiday.description ?? '');
    _selectedDate = widget.holiday.date;
    _selectedType = widget.holiday.type ?? 'custom';
    _isRecurring = widget.holiday.isRecurring;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showSingleDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
      title: 'Select Holiday Date',
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await HolidaysService.updateHoliday(
        id: widget.holiday.id,
        name: _nameController.text.trim(),
        date: _selectedDate,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _selectedType,
        isRecurring: _isRecurring,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onHolidayUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Holiday updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update holiday: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Public Holiday',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Holiday Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter holiday name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                            : 'Select Date',
                        style: TextStyle(
                          color: _selectedDate != null 
                              ? null 
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Holiday Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'national', child: Text('National')),
                  DropdownMenuItem(value: 'religious', child: Text('Religious')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Recurring Yearly'),
                subtitle: const Text('This holiday will repeat every year'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.skyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Update Holiday'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/tile_date_picker.dart';
import '../widgets/single_date_picker.dart';
import '../services/requests_service.dart';

class LeaveFormWidget extends StatefulWidget {
  final String? userRole;
  final bool isAdmin;
  final LeaveBalance? leaveBalance;
  final int? userAnnualLeaveDays;
  final VoidCallback? onSubmitted;

  const LeaveFormWidget({
    super.key,
    this.userRole,
    this.isAdmin = false,
    this.leaveBalance,
    this.userAnnualLeaveDays,
    this.onSubmitted,
  });

  @override
  State<LeaveFormWidget> createState() => _LeaveFormWidgetState();
}

class _LeaveFormWidgetState extends State<LeaveFormWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final _contactAddressController = TextEditingController();
  final _reasonForLeavingController = TextEditingController();
  final _travelPlaceController = TextEditingController();
  final _accCostController = TextEditingController();
  final _bfCostController = TextEditingController();
  final _lunchCostController = TextEditingController();
  final _supperCostController = TextEditingController();
  final _transportCostController = TextEditingController();
  final _fuelCostController = TextEditingController();
  
  // Form state
  String _selectedType = 'Annual Leave';
  DateTimeRange? _selectedRange;
  bool _leaveGrantRequired = false;
  DateTime? _travelDate;

  @override
  void dispose() {
    _contactAddressController.dispose();
    _reasonForLeavingController.dispose();
    _travelPlaceController.dispose();
    _accCostController.dispose();
    _bfCostController.dispose();
    _lunchCostController.dispose();
    _supperCostController.dispose();
    _transportCostController.dispose();
    _fuelCostController.dispose();
    super.dispose();
  }

  String formatDate(DateTime d) {
    return d.toIso8601String().split('T').first;
  }

  double? parseDouble(String val) => double.tryParse(val);

  double calculateTotal() {
    return (parseDouble(_accCostController.text) ?? 0) +
           (parseDouble(_bfCostController.text) ?? 0) +
           (parseDouble(_lunchCostController.text) ?? 0) +
           (parseDouble(_supperCostController.text) ?? 0) +
           (parseDouble(_transportCostController.text) ?? 0) +
           (parseDouble(_fuelCostController.text) ?? 0);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showTileDateRangePicker(
      context: context,
      initialStartDate: _selectedRange?.start,
      initialEndDate: _selectedRange?.end,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      title: 'Select Request Dates',
    );
    if (range != null) {
      setState(() {
        _selectedRange = range;
      });
    }
  }

  Future<void> _pickTravelDate() async {
    final picked = await showSingleDatePicker(
      context: context,
      initialDate: _travelDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      title: 'Select Travel Date',
    );
    if (picked != null) {
      setState(() {
        _travelDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if ((_selectedType == 'Leave Duty Station' ? _travelDate == null : _selectedRange == null) || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String start, end;
      if (_selectedType == 'Leave Duty Station') {
        start = end = formatDate(_travelDate!);
      } else {
        start = formatDate(_selectedRange!.start);
        end = formatDate(_selectedRange!.end);
      }

      await RequestsService.createRequest(
        type: _selectedType,
        startDate: start,
        endDate: end,
        leaveGrantRequired: _leaveGrantRequired,
        contactAddress: _contactAddressController.text,
        reasonForLeaving: _reasonForLeavingController.text,
        travelDate: _travelDate != null ? formatDate(_travelDate!) : null,
        travelPlace: _travelPlaceController.text,
        costAccommodation: parseDouble(_accCostController.text),
        costBreakfast: parseDouble(_bfCostController.text),
        costLunch: parseDouble(_lunchCostController.text),
        costSupper: parseDouble(_supperCostController.text),
        costPublicTransport: parseDouble(_transportCostController.text),
        costFuelLubricants: parseDouble(_fuelCostController.text),
        costTotal: calculateTotal(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSubmitted?.call();
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _contactAddressController.clear();
    _reasonForLeavingController.clear();
    _travelPlaceController.clear();
    _accCostController.clear();
    _bfCostController.clear();
    _lunchCostController.clear();
    _supperCostController.clear();
    _transportCostController.clear();
    _fuelCostController.clear();
    
    setState(() {
      _selectedType = 'Annual Leave';
      _selectedRange = null;
      _leaveGrantRequired = false;
      _travelDate = null;
    });
  }

  Widget _buildLeaveTypeDropdown() {
    final leaveTypes = [
      {'value': 'Annual Leave', 'icon': Icons.beach_access},
      {'value': 'Sick Leave', 'icon': Icons.medical_services},
      {'value': 'Personal Leave', 'icon': Icons.person},
      {'value': 'Work From Home', 'icon': Icons.home_work},
      {'value': 'Leave Duty Station', 'icon': Icons.flight_takeoff},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          hint: const Text('Select leave type'),
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.skyBlue),
          items: leaveTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type['value'] as String?,
              child: Row(
                children: [
                  Icon(
                    type['icon'] as IconData,
                    size: 20,
                    color: AppTheme.skyBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type['value'] as String,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedType = newValue;
              });
            }
          },
        ),
      ),
    );
  }


  Widget _buildLeaveBalanceInfo() {
    if (_selectedType != 'Annual Leave' || widget.leaveBalance == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.skyBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.skyBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Annual Leave Balance',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.skyBlue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.leaveBalance!.remainingDays} days remaining out of ${widget.leaveBalance!.allocatedDays} allocated',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    if (_selectedType == 'Leave Duty Station') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Travel Date',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickTravelDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.skyBlue),
                  const SizedBox(width: 12),
                  Text(
                    _travelDate == null ? 'Select Date' : formatDate(_travelDate!),
                    style: TextStyle(
                      color: _travelDate == null 
                          ? Colors.grey.shade600 
                          : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.skyBlue),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDateRange,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.skyBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedRange == null
                        ? 'Select dates'
                        : _selectedRange!.start == _selectedRange!.end
                        ? formatDate(_selectedRange!.start)
                        : '${formatDate(_selectedRange!.start)} - ${formatDate(_selectedRange!.end)}',
                    style: TextStyle(
                      color: _selectedRange == null 
                          ? Colors.grey.shade600 
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppTheme.skyBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveGrantToggle() {
    if (_selectedType == 'Leave Duty Station' || _selectedType == 'Work From Home') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Text(
            'Leave Grant Required',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const Spacer(),
          Switch(
            value: _leaveGrantRequired,
            activeThumbColor: AppTheme.skyBlue,
            activeTrackColor: AppTheme.skyBlue.withValues(alpha: 0.3),
            onChanged: (v) {
              setState(() {
                _leaveGrantRequired = v;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactAddressField() {
    if (_selectedType == 'Leave Duty Station' || _selectedType == 'Work From Home') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Address while on Leave',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contactAddressController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Enter your contact address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.skyBlue),
            ),
          ),
          validator: (value) {
            if (_selectedType != 'Work From Home' && (value == null || value.trim().isEmpty)) {
              return 'Please enter contact address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDutyStationFields() {
    if (_selectedType != 'Leave Duty Station') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section A: Reason for leaving station
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.skyBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.skyBlue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flight_takeoff, color: AppTheme.skyBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Section A: Reason for leaving station',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.skyBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonForLeavingController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason(s) for leaving station',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide reason for leaving station';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _travelPlaceController,
                decoration: InputDecoration(
                  labelText: 'Place where traveling to',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter travel destination';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Section B: Cost of the trip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Section B: Cost of the trip (Optional - MK)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Use 2 columns on wider screens, 1 column on smaller screens
                  final isWideScreen = constraints.maxWidth > 600;
                  return Column(
                    children: [
                      if (isWideScreen) ...[
                        // Two column layout for wider screens
                        Row(
                          children: [
                            Expanded(child: _buildCostField('Accommodation', _accCostController)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCostField('Breakfast', _bfCostController)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildCostField('Lunch', _lunchCostController)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCostField('Supper', _supperCostController)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildCostField('Public transport', _transportCostController)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCostField('Fuel & lubricants', _fuelCostController)),
                          ],
                        ),
                      ] else ...[
                        // Single column layout for smaller screens
                        _buildCostField('Accommodation', _accCostController),
                        _buildCostField('Breakfast', _bfCostController),
                        _buildCostField('Lunch', _lunchCostController),
                        _buildCostField('Supper', _supperCostController),
                        _buildCostField('Public transport', _transportCostController),
                        _buildCostField('Fuel & lubricants', _fuelCostController),
                      ],
                    ],
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Flexible(
                      child: Text(
                        'MK ${calculateTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.skyBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixText: 'MK ',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.assignment_add,
                    color: AppTheme.skyBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Leave Request Form',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Request Type Selection
              const Text(
                'Request Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildLeaveTypeDropdown(),
              const SizedBox(height: 24),
              
              // Leave Balance Info (for Annual Leave)
              _buildLeaveBalanceInfo(),
              if (_selectedType == 'Annual Leave') const SizedBox(height: 16),
              
              // Date Selection
              _buildDateSection(),
              const SizedBox(height: 24),
              
              // Leave Grant Toggle
              _buildLeaveGrantToggle(),
              
              // Contact Address
              _buildContactAddressField(),
              if (_selectedType != 'Leave Duty Station' && _selectedType != 'Work From Home') 
                const SizedBox(height: 24),
              
              // Duty Station Specific Fields
              _buildDutyStationFields(),
              if (_selectedType == 'Leave Duty Station') const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.skyBlue,
                        side: const BorderSide(color: AppTheme.skyBlue),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined),
                          SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedType == 'Leave Duty Station' ? _travelDate == null : _selectedRange == null) || _isLoading
                          ? null
                          : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.skyBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Submitting...'),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send),
                                SizedBox(width: 8),
                                Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

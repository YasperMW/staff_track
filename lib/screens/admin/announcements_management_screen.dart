import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/announcements_service.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/simple_header.dart';

class AnnouncementsManagementScreen extends StatefulWidget {
  const AnnouncementsManagementScreen({super.key});

  @override
  State<AnnouncementsManagementScreen> createState() => _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState extends State<AnnouncementsManagementScreen> {
  List<Announcement> _announcements = [];
  List<Announcement> _filteredAnnouncements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'active', 'expired'

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final announcements = await AnnouncementsService.getAnnouncements(limit: 100);
      setState(() {
        _announcements = announcements;
        _filteredAnnouncements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load announcements: $e')),
        );
      }
    }
  }

  void _filterAnnouncements() {
    setState(() {
      _filteredAnnouncements = _announcements.where((announcement) {
        final matchesSearch = announcement.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            announcement.message.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesFilter = _selectedFilter == 'all' ||
            (_selectedFilter == 'active' && announcement.isValid) ||
            (_selectedFilter == 'expired' && !announcement.isValid);
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _showCreateAnnouncementSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CreateAnnouncementSheet(
        onAnnouncementCreated: (announcement) {
          // Optimistic update - add new announcement immediately
          setState(() {
            _announcements.insert(0, announcement); // Add at the beginning for newest first
            _filterAnnouncements(); // Reapply filters
          });
          
          // Refresh in background to get latest data from server
          _loadAnnouncements();
        },
      ),
    );
  }

  Future<void> _showEditAnnouncementSheet(Announcement announcement) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => EditAnnouncementSheet(
        announcement: announcement,
        onAnnouncementUpdated: (updatedAnnouncement) {
          // Optimistic update - update the announcement in the list
          setState(() {
            final index = _announcements.indexWhere((a) => a.id == updatedAnnouncement.id);
            if (index != -1) {
              _announcements[index] = updatedAnnouncement;
              _filterAnnouncements(); // Reapply filters
            }
          });
          
          // Refresh in background to get latest data from server
          _loadAnnouncements();
        },
      ),
    );
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"?'),
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
      // Optimistic update - remove announcement immediately
      setState(() {
        _announcements.removeWhere((a) => a.id == announcement.id);
        _filterAnnouncements(); // Reapply filters
      });
      
      try {
        await AnnouncementsService.deleteAnnouncement(announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully')),
          );
        }
      } catch (e) {
        // If delete fails, refresh to restore the announcement
        _loadAnnouncements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete announcement: $e')),
          );
        }
      }
    }
  }

  Future<void> _sendNotifications(Announcement announcement) async {
    try {
      await AnnouncementsService.sendAnnouncementNotifications(announcement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifications sent to ${announcement.targetAudience}')),
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
      appBar: const SimpleHeader(
        title: 'Announcements Management',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.skyBlue),
                    )
                  : _buildAnnouncementsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAnnouncementSheet,
        backgroundColor: AppTheme.skyBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Announcements',
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
            '${_filteredAnnouncements.length} announcements',
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search announcements...',
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
              _filterAnnouncements();
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
            value: _selectedFilter,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'expired', child: Text('Expired')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFilter = value;
                });
                _filterAnnouncements();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    if (_filteredAnnouncements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.announcement_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No announcements found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first announcement using the + button',
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
      itemCount: _filteredAnnouncements.length,
      itemBuilder: (context, index) {
        final announcement = _filteredAnnouncements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final isValid = announcement.isValid;
    final typeColor = Color(int.parse(announcement.typeColor.replaceFirst('#', '0xFF')));
    
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
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAnnouncementTypeIcon(announcement.type),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement.typeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        _showEditAnnouncementSheet(announcement);
                        break;
                      case 'notify':
                        _sendNotifications(announcement);
                        break;
                      case 'toggle':
                        _toggleAnnouncementStatus(announcement);
                        break;
                      case 'delete':
                        _deleteAnnouncement(announcement);
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
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            announcement.isActive ? Icons.visibility_off : Icons.visibility,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(announcement.isActive ? 'Deactivate' : 'Activate'),
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
            Text(
              announcement.message,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  announcement.targetAudience,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(announcement.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                if (!isValid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (!announcement.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.paleRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.paleRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAnnouncementTypeIcon(String type) {
    switch (type) {
      case 'urgent':
        return Icons.warning;
      case 'policy':
        return Icons.policy;
      case 'event':
        return Icons.celebration;
      default:
        return Icons.announcement;
    }
  }

  Future<void> _toggleAnnouncementStatus(Announcement announcement) async {
    try {
      await AnnouncementsService.updateAnnouncement(
        id: announcement.id,
        isActive: !announcement.isActive,
      );
      _loadAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              announcement.isActive 
                  ? 'Announcement deactivated' 
                  : 'Announcement activated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update announcement: $e')),
        );
      }
    }
  }
}

class CreateAnnouncementSheet extends StatefulWidget {
  final Function(Announcement) onAnnouncementCreated;

  const CreateAnnouncementSheet({super.key, required this.onAnnouncementCreated});

  @override
  State<CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'general';
  List<String> _selectedDepartments = [];  // Changed to support multiple departments
  String? _selectedRole;
  bool _isActive = true;
  DateTime? _expiresAt;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _expiresAt = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final announcement = await AnnouncementsService.createAnnouncement(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
        targetDepartments: _selectedDepartments.isNotEmpty ? _selectedDepartments : null,
        targetRole: _selectedRole,
        isActive: _isActive,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onAnnouncementCreated(announcement);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create announcement: $e')),
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
                    'Create Announcement',
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Announcement Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter announcement title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter announcement message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Announcement Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('📢 General')),
                  DropdownMenuItem(value: 'urgent', child: Text('🚨 Urgent')),
                  DropdownMenuItem(value: 'policy', child: Text('📋 Policy Update')),
                  DropdownMenuItem(value: 'event', child: Text('🎉 Event')),
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
              // Multi-department selection for CreateAnnouncementSheet
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target Departments (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: AnnouncementsService.getAvailableDepartments().map((dept) {
                      final isSelected = _selectedDepartments.contains(dept);
                      return FilterChip(
                        label: Text(dept),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDepartments.add(dept);
                            } else {
                              _selectedDepartments.remove(dept);
                            }
                            _selectedRole = null; // Reset role when departments change
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppTheme.skyBlue.withOpacity(0.2),
                        checkmarkColor: AppTheme.skyBlue,
                      );
                    }).toList(),
                  ),
                  if (_selectedDepartments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'No departments selected - will send to all staff',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedDepartments.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Target Role (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Roles')),
                    ...AnnouncementsService.getAvailableRoles()
                        .where((role) => _selectedDepartments.any((dept) => _isRoleInDepartment(role, dept)))
                        .map((role) => DropdownMenuItem(value: role, child: Text(role))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectExpirationDate,
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
                        _expiresAt != null
                            ? 'Expires: ${DateFormat('MMMM d, yyyy').format(_expiresAt!)}'
                            : 'No Expiration Date',
                        style: TextStyle(
                          color: _expiresAt != null 
                              ? null 
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Active Immediately'),
                subtitle: const Text('Announcement will be visible to target audience'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? false;
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
                      : const Text('Create Announcement'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  bool _isRoleInDepartment(String role, String department) {
    // Simple mapping - in real app this would come from database
    switch (department) {
      case 'Medical':
        return ['Doctor'].contains(role);
      case 'Nursing':
        return ['Nurse', 'Head Nurse'].contains(role);
      case 'Pharmacy':
        return ['Pharmacist'].contains(role);
      case 'Laboratory':
        return ['Lab Technician'].contains(role);
      case 'Radiology':
        return ['Radiologist'].contains(role);
      case 'Administration':
        return ['Administrator', 'Medical Director', 'Principal Hospital Administrator'].contains(role);
      case 'Finance':
        return ['Accountant'].contains(role);
      case 'IT':
        return ['IT Support'].contains(role);
      case 'Human Resources':
        return ['HR Manager'].contains(role);
      case 'Facilities':
        return ['Facility Manager'].contains(role);
      case 'Security':
        return ['Security Officer'].contains(role);
      case 'Catering':
        return ['Cook'].contains(role);
      default:
        return true;
    }
  }
}

class EditAnnouncementSheet extends StatefulWidget {
  final Announcement announcement;
  final Function(Announcement) onAnnouncementUpdated;

  const EditAnnouncementSheet({
    super.key,
    required this.announcement,
    required this.onAnnouncementUpdated,
  });

  @override
  State<EditAnnouncementSheet> createState() => _EditAnnouncementSheetState();
}

class _EditAnnouncementSheetState extends State<EditAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late String _selectedType;
  String? _selectedDepartment;
  String? _selectedRole;
  late bool _isActive;
  DateTime? _expiresAt;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _messageController = TextEditingController(text: widget.announcement.message);
    _selectedType = widget.announcement.type;
    _selectedDepartment = widget.announcement.targetDepartment;
    _selectedRole = widget.announcement.targetRole;
    _isActive = widget.announcement.isActive;
    _expiresAt = widget.announcement.expiresAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _expiresAt = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedAnnouncement = await AnnouncementsService.updateAnnouncement(
        id: widget.announcement.id,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
        targetDepartment: _selectedDepartment,
        targetRole: _selectedRole,
        isActive: _isActive,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onAnnouncementUpdated(updatedAnnouncement);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update announcement: $e')),
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
                    'Edit Announcement',
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Announcement Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter announcement title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter announcement message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Announcement Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('📢 General')),
                  DropdownMenuItem(value: 'urgent', child: Text('🚨 Urgent')),
                  DropdownMenuItem(value: 'policy', child: Text('📋 Policy Update')),
                  DropdownMenuItem(value: 'event', child: Text('🎉 Event')),
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
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Target Department (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Departments')),
                  ...AnnouncementsService.getAvailableDepartments()
                      .map((dept) => DropdownMenuItem(value: dept, child: Text(dept))),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                    _selectedRole = null; // Reset role when department changes
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedDepartment != null) ...[
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Target Role (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Roles')),
                    ...AnnouncementsService.getAvailableRoles()
                        .where((role) => _isRoleInDepartment(role, _selectedDepartment!))
                        .map((role) => DropdownMenuItem(value: role, child: Text(role))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              GestureDetector(
                onTap: _selectExpirationDate,
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
                        _expiresAt != null
                            ? 'Expires: ${DateFormat('MMMM d, yyyy').format(_expiresAt!)}'
                            : 'No Expiration Date',
                        style: TextStyle(
                          color: _expiresAt != null 
                              ? null 
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Active'),
                subtitle: const Text('Announcement will be visible to target audience'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? false;
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
                      : const Text('Update Announcement'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  bool _isRoleInDepartment(String role, String department) {
    // Simple mapping - in real app this would come from database
    switch (department) {
      case 'Medical':
        return ['Doctor'].contains(role);
      case 'Nursing':
        return ['Nurse', 'Head Nurse'].contains(role);
      case 'Pharmacy':
        return ['Pharmacist'].contains(role);
      case 'Laboratory':
        return ['Lab Technician'].contains(role);
      case 'Radiology':
        return ['Radiologist'].contains(role);
      case 'Administration':
        return ['Administrator', 'Medical Director', 'Principal Hospital Administrator'].contains(role);
      case 'Finance':
        return ['Accountant'].contains(role);
      case 'IT':
        return ['IT Support'].contains(role);
      case 'Human Resources':
        return ['HR Manager'].contains(role);
      case 'Facilities':
        return ['Facility Manager'].contains(role);
      case 'Security':
        return ['Security Officer'].contains(role);
      case 'Catering':
        return ['Cook'].contains(role);
      default:
        return true;
    }
  }
}

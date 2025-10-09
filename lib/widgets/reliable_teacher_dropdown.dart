import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/teacher_model.dart';
import '../services/database_service.dart';

class ReliableTeacherDropdown extends StatefulWidget {
  final String? selectedTeacherUid;
  final Function(String? uid, String? name) onTeacherChanged;
  final String? Function(String?)? validator;
  final bool forceOfflineMode;

  const ReliableTeacherDropdown({
    super.key,
    required this.selectedTeacherUid,
    required this.onTeacherChanged,
    this.validator,
    this.forceOfflineMode = false,
  });

  @override
  State<ReliableTeacherDropdown> createState() => _ReliableTeacherDropdownState();
}

class _ReliableTeacherDropdownState extends State<ReliableTeacherDropdown> {
  late Stream<List<TeacherModel>> _teachersStream;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize with default teachers immediately to prevent LateInitializationError
    _teachersStream = Stream.value(_getDefaultTeachers());
    // Then try to load real teachers
    _loadTeachersFromDatabaseService();
  }

  void _initializeTeachersStream() {
    // Check if we should force offline mode or if user is not authenticated
    final user = FirebaseAuth.instance.currentUser;
    
    if (widget.forceOfflineMode) {
      print('📴 Using offline teacher list (forced offline mode)');
      _loadTeachersFromDatabaseService();
      return;
    }
    
    if (user == null) {
      print('📴 Using offline teacher list (user not authenticated)');
      _teachersStream = Stream.value(_getDefaultTeachers());
      setState(() {
        _hasError = false;
        _errorMessage = 'Offline teacher list';
      });
      return;
    }
    
    print('🌐 Attempting to load teachers from DatabaseService for user: ${user.email}');
    _loadTeachersFromDatabaseService();
  }

  void _loadTeachersFromDatabaseService() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final teachers = await dbService.getAllTeachers();
      
      print('✅ Loaded ${teachers.length} teachers from DatabaseService');
      
      _teachersStream = Stream.value(teachers);
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Failed to load teachers from DatabaseService: $e');
      // Fallback to default teachers
      _teachersStream = Stream.value(_getDefaultTeachers());
      setState(() {
        _hasError = true;
        _errorMessage = 'Using offline teacher list';
      });
    }
  }

  List<TeacherModel> _getDefaultTeachers() {
    return [
      TeacherModel(
        uid: 'default_teacher_1',
        email: 'teacher1@pvppcoe.ac.in',
        name: 'Dr. Rajesh Kumar',
      ),
      TeacherModel(
        uid: 'default_teacher_2',
        email: 'teacher2@pvppcoe.ac.in',
        name: 'Prof. Priya Sharma',
      ),
      TeacherModel(
        uid: 'default_teacher_3',
        email: 'teacher3@pvppcoe.ac.in',
        name: 'Dr. Amit Patel',
      ),
      TeacherModel(
        uid: 'default_teacher_4',
        email: 'teacher4@pvppcoe.ac.in',
        name: 'Prof. Snehal Patil',
      ),
      TeacherModel(
        uid: 'default_teacher_5',
        email: 'teacher5@pvppcoe.ac.in',
        name: 'Dr. Suresh Mehta',
      ),
      TeacherModel(
        uid: 'default_teacher_6',
        email: 'teacher6@pvppcoe.ac.in',
        name: 'Prof. Kavita Joshi',
      ),
    ];
  }

  void _retryConnection() {
    print('🔄 Retrying teacher connection...');
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _loadTeachersFromDatabaseService();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select Teacher',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_hasError)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _retryConnection,
                    tooltip: 'Retry loading teachers',
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            StreamBuilder<List<TeacherModel>>(
              stream: _teachersStream,
              builder: (context, snapshot) {
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                
                // Handle error state
                if (snapshot.hasError || _hasError) {
                  return _buildErrorState();
                }
                
                // Handle data state
                final teachers = snapshot.data ?? _getDefaultTeachers();
                
                if (teachers.isEmpty) {
                  return _buildEmptyState();
                }
                
                return _buildDropdownField(teachers);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: const Row(
        children: [
          SizedBox(width: 16),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text(
            'Loading teachers...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    // If we have error but still showing default teachers, show a friendlier UI
    if (_errorMessage == 'Using offline teacher list' || _errorMessage == 'Offline teacher list') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.offline_pin, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teachers available',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select from our list of faculty members',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Show the dropdown with default teachers
          _buildDropdownField(_getDefaultTeachers()),
        ],
      );
    }
    
    // For other errors, show the original error UI
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failed to load teachers',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _retryConnection,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No teachers available',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact the administrator to add teachers to the system.',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(List<TeacherModel> teachers) {

    return DropdownButtonFormField<String>(
      initialValue: widget.selectedTeacherUid,
      menuMaxHeight: 300,
      decoration: InputDecoration(
        hintText: 'Choose your guide teacher',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      isExpanded: true,
      
      // Custom selected item display (compact, single line)
      selectedItemBuilder: (BuildContext context) {
        return teachers.map((teacher) {
          return Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                radius: 12, // Smaller for selected display
                child: Text(
                  teacher.name.isNotEmpty 
                      ? teacher.name[0].toUpperCase()
                      : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10, // Smaller for selected display
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  teacher.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );
        }).toList();
      },
      
      // Dropdown items (detailed view)
      items: teachers.map((teacher) {
        return DropdownMenuItem(
          value: teacher.uid,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), // Reduced padding
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 14,
                  child: Text(
                    teacher.name.isNotEmpty 
                        ? teacher.name[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 1), // Reduced spacing
                      Text(
                        teacher.email,
                        style: TextStyle(
                          fontSize: 10, // Even smaller
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final selectedTeacher = teachers.firstWhere((t) => t.uid == value);
          widget.onTeacherChanged(value, selectedTeacher.name);
        }
      },
      validator: widget.validator,
    );
  }
}
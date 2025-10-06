import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/error_service.dart';
import '../models/student_model.dart';
import '../widgets/enhanced_loading_widget.dart';
import '../widgets/reliable_teacher_dropdown.dart';
import 'student_dashboard_screen.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teamLeaderController = TextEditingController();
  final _memberController = TextEditingController();
  final List<String> _teamMembers = [];
  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedTeacherUid;
  String? _selectedTeacherName;
  List<TeacherModel> _teachers = [];
  bool _isLoading = false;
  bool _isLoadingTeachers = true;
  bool _teacherLoadError = false;
  String? _teacherErrorMessage;
  bool _obscurePassword = true;

  final List<String> _years = ['FE', 'SE', 'TE', 'BE'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void initState() {
    super.initState();
    // Load teachers after the widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeachers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload teachers if they failed to load initially
    if (_teacherLoadError && _teachers.isEmpty) {
      _loadTeachers();
    }
  }

  Future<void> _loadTeachers() async {
    print('🔄 Loading teachers - Start');
    try {
      setState(() {
        _isLoadingTeachers = true;
        _teacherLoadError = false;
        _teacherErrorMessage = null;
      });

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      // Use network service to ensure connectivity
      final teachers = await NetworkService.instance.executeWithConnectivityCheck(
        () => dbService.getAllTeachers(),
        offlineMessage: 'Cannot load teachers while offline. Please check your connection.',
      );
      
      if (mounted) {
        print('✅ Teachers loaded successfully: ${teachers?.length ?? 0} teachers');
        setState(() {
          _teachers = teachers ?? [];
          _isLoadingTeachers = false;
          _teacherLoadError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTeachers = false;
          _teacherLoadError = true;
          _teacherErrorMessage = ErrorService.getErrorMessage(e);
        });
        print('❌ Error loading teachers: $e');
        ErrorService.showErrorSnackBar(context, e);
      }
    }
  }

  void _addTeamMember() {
    if (_memberController.text.trim().isNotEmpty) {
      setState(() {
        _teamMembers.add(_memberController.text.trim());
        _memberController.clear();
      });
    }
  }

  void _removeTeamMember(int index) {
    setState(() {
      _teamMembers.removeAt(index);
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a teacher'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final userCredential = await authService.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final student = StudentModel(
        uid: userCredential.user!.uid,
        email: _emailController.text.trim(),
        teamLeaderName: _teamLeaderController.text.trim(),
        teamMembers: _teamMembers,
        year: _selectedYear!,
        semester: _selectedSemester!,
        teacherUid: _selectedTeacherUid!,
        teacherName: _selectedTeacherName!,
      );

      await dbService.saveStudent(student);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const StudentDashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _teamLeaderController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        actions: [
          if (_teacherLoadError || _teachers.isEmpty)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: _isLoadingTeachers 
                    ? Colors.grey 
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: _isLoadingTeachers ? null : _loadTeachers,
              tooltip: 'Reload Teachers',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.endsWith('@pvppcoe.ac.in')) {
                      return 'Must use @pvppcoe.ac.in email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _teamLeaderController,
                  decoration: const InputDecoration(
                    labelText: 'Team Leader Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter team leader name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team Members',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _memberController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter member name',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: _addTeamMember,
                            ),
                          ],
                        ),
                        if (_teamMembers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _teamMembers
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Chip(
                                    label: Text(entry.value),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () => _removeTeamMember(entry.key),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year of Study',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  items: _years
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select year';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  items: _semesters
                      .map((sem) => DropdownMenuItem(
                            value: sem,
                            child: Text('Semester $sem'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select semester';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Reliable Teacher Dropdown with offline-first approach for student registration
                ReliableTeacherDropdown(
                  selectedTeacherUid: _selectedTeacherUid,
                  onTeacherChanged: (uid, name) {
                    setState(() {
                      _selectedTeacherUid = uid;
                      _selectedTeacherName = name;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a teacher';
                    }
                    return null;
                  },
                  forceOfflineMode: true, // Always use offline mode for student registration
                ),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a teacher';
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

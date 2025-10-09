import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/error_service.dart';
import '../services/network_service.dart';
import '../models/student_model.dart';
import '../models/project_model.dart';
import '../widgets/enhanced_loading_widget.dart';
import '../widgets/similarity_check_widget.dart';
import 'role_selection_screen.dart';
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  StudentModel? _student;
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _listenToNetworkChanges();
  }

  void _listenToNetworkChanges() {
    NetworkService.instance.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
        
        if (!isConnected) {
          ErrorService.showInfoSnackBar(
            context, 
            'You are offline. Some features may not work.',
          );
        } else if (_isOffline) {
          ErrorService.showSuccessSnackBar(
            context,
            'Connection restored!',
          );
        }
      }
    });
  }

  Future<void> _loadStudentData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final user = authService.currentUser;
      if (user != null) {
        final student = await dbService.getStudent(user.uid);
        setState(() {
          _student = student;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showErrorSnackBar(context, e);
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _refreshData() async {
    await _loadStudentData();
  }


  /// Check similarity and show analysis dialog before submission
  Future<void> _checkSimilarityAndSubmit(String title, String description) async {
    // Show loading dialog
    if (!mounted) return;
    SimilarityCheckLoadingDialog.show(context);

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      // Check similarity
      final similarityResult = await dbService.checkProjectSimilarity(
        title: title,
        description: description,
        studentYear: _student?.year,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Show similarity analysis dialog
      await SimilarityCheckDialog.show(
        context: context,
        result: similarityResult,
        projectTitle: title,
        projectDescription: description,
        onConfirm: () async {
          await _submitProjectDirectly(
            title,
            description,
            similarityResult.suggestedDomain.domain,
            similarityResult.maxSimilarity,
          );
        },
        onCancel: () {
          // User cancelled - nothing to do
        },
        onEdit: () {
          // Re-open the edit dialog
          _showSubmitProjectDialog();
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ErrorService.showErrorSnackBar(context, e);
      }
    }
  }

  /// Submit project directly without similarity check
  Future<void> _submitProjectDirectly(
    String title,
    String description,
    String domain,
    double similarityScore,
  ) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);

      final project = ProjectModel(
        studentUid: _student!.uid,
        studentName: _student!.teamLeaderName,
        teacherUid: _student!.teacherUid,
        teacherName: _student!.teacherName,
        topic: title,
        description: description,
        submittedAt: DateTime.now(),
        year: _student!.year,
        semester: _student!.semester,
        teamMembers: _student!.teamMembers,
        domain: domain,
        similarityScore: similarityScore,
      );

      await dbService.submitProject(project);

      if (mounted) {
        ErrorService.showSuccessSnackBar(
          context,
          'Project submitted successfully!',
        );
        await _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showErrorSnackBar(context, e);
      }
    }
  }

  /// Update existing project
  Future<void> _updateExistingProject(
    String projectId,
    String title,
    String description,
  ) async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      await dbService.updateProject(projectId, title, description);

      if (mounted) {
        ErrorService.showSuccessSnackBar(
          context,
          'Project updated successfully!',
        );
        await _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _handleLogout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  void _showSubmitProjectDialog({ProjectModel? existingProject}) {
    final topicController =
        TextEditingController(text: existingProject?.topic ?? '');
    final descriptionController =
        TextEditingController(text: existingProject?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            existingProject != null ? 'Resubmit Project' : 'Submit Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existingProject != null &&
                  existingProject.feedback != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher Feedback:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(existingProject.feedback!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                  labelText: 'Project Topic',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Project Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (existingProject == null) // Only show for new projects
            ElevatedButton.icon(
              onPressed: () async {
                if (topicController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                await _checkSimilarityAndSubmit(
                  topicController.text.trim(),
                  descriptionController.text.trim(),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Check Similarity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              if (topicController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (existingProject != null) {
                // Direct update for resubmission
                await _updateExistingProject(
                  existingProject.id!,
                  topicController.text.trim(),
                  descriptionController.text.trim(),
                );
              } else {
                // For new projects, submit directly without similarity check
                await _submitProjectDirectly(
                  topicController.text.trim(),
                  descriptionController.text.trim(),
                  'Web Development', // Default domain
                  0.0, // Default similarity
                );
              }
              
              if (mounted) Navigator.pop(context);
            },
            child: Text(existingProject != null ? 'Update' : 'Submit Directly'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_student == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading student data'),
              ElevatedButton(
                onPressed: _handleLogout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${_student!.teamLeaderName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_student!.year} - Semester ${_student!.semester}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Guide: ${_student!.teacherName}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Offline indicator
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[100],
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'You are offline. Some features may not work.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ProjectModel>>(
              stream: Provider.of<DatabaseService>(context, listen: false)
                  .watchProjectsForStudent(_student!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const EnhancedLoadingWidget.circular(
                    message: 'Loading your projects...',
                  );
                }


                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No projects submitted yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Submit New Project'),
                          onPressed: () => _showSubmitProjectDialog(),
                        ),
                      ],
                    ),
                  );
                }

                final projects = snapshot.data!;
                final hasApprovedProject = projects.any((p) => p.status == 'approved');

                return Column(
                  children: [
                    // Status indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: hasApprovedProject ? Colors.green.shade50 : Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(
                            hasApprovedProject ? Icons.check_circle : Icons.info,
                            color: hasApprovedProject ? Colors.green.shade700 : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasApprovedProject
                                  ? 'One project has been approved by your teacher'
                                  : 'Submitted ${projects.length} of 4 allowed projects',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: hasApprovedProject ? Colors.green.shade700 : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Project list with pull-to-refresh
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  project.topic,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              _StatusChip(status: project.status),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            project.description,
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                          const SizedBox(height: 12),
                                          if (project.feedback != null) ...[
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: project.status == 'rejected'
                                                    ? Colors.red.shade50
                                                    : project.status == 'declined'
                                                        ? Colors.orange.shade50
                                                        : Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Teacher Feedback:',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: project.status == 'rejected'
                                                          ? Colors.red
                                                          : project.status == 'declined'
                                                              ? Colors.orange
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(project.feedback!),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                          if (project.status == 'declined')
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Resubmit Project'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _showSubmitProjectDialog(existingProject: project),
                                            ),
                                          if (project.status == 'rejected')
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red.shade300),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.block, color: Colors.red.shade700),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'This project has been rejected and cannot be resubmitted.',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.red.shade700,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<List<ProjectModel>>(
        stream: Provider.of<DatabaseService>(context, listen: false)
            .watchProjectsForStudent(_student!.uid),
        builder: (context, snapshot) {
          final canSubmit = !snapshot.hasData || snapshot.data!.length < 4;
          final hasApprovedProject = snapshot.hasData && snapshot.data!.any((p) => p.status == 'approved');

          if (!canSubmit || hasApprovedProject) {
            return const SizedBox.shrink();
          }

          if (!canSubmit) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _showSubmitProjectDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Submit Project'),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'declined':
        color = Colors.orange;
        icon = Icons.refresh;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
    );
  }
}

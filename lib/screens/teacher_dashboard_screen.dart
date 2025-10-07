import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/similarity_service.dart';
import '../models/teacher_model.dart';
import '../models/project_model.dart';
import 'role_selection_screen.dart';
import 'project_detail_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  TeacherModel? _teacher;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    final user = authService.currentUser;
    if (user != null) {
      final teachers = await dbService.getAllTeachers();
      final teacher = teachers.firstWhere(
        (t) => t.email == user.email,
        orElse: () => TeacherModel(
          uid: user.uid,
          email: user.email!,
          name: 'Teacher',
        ),
      );
      setState(() {
        _teacher = teacher;
        _isLoading = false;
      });
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

  void _showSimilarityCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SimilarityAnalysisDialog(
        teacherUid: _teacher?.uid ?? '',
      ),
    );
  }

  Map<String, List<ProjectModel>> _groupProjectsByTeamLeader(
      List<ProjectModel> projects) {
    final Map<String, List<ProjectModel>> grouped = {};

    for (var project in projects) {
      final key = '${project.studentUid}_${project.studentName}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(project);
    }

    return grouped;
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_teacher == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading teacher data'),
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
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Check Project Similarities',
            onPressed: () => _showSimilarityCheckDialog(context),
          ),
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
                  'Welcome, ${_teacher!.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Project Submissions by Team',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProjectModel>>(
              stream: Provider.of<DatabaseService>(context, listen: false)
                  .watchProjectsForTeacher(_teacher!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                          'No project submissions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final projects = snapshot.data!;
                final groupedProjects = _groupProjectsByTeamLeader(projects);
                final pendingCount =
                    projects.where((p) => p.status == 'pending').length;

                return Column(
                  children: [
                    if (pendingCount > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.orange.shade50,
                        child: Row(
                          children: [
                            Icon(Icons.pending_actions,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Text(
                              '$pendingCount project${pendingCount > 1 ? 's' : ''} awaiting review',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedProjects.length,
                        itemBuilder: (context, index) {
                          final key = groupedProjects.keys.elementAt(index);
                          final teamProjects = groupedProjects[key]!;
                          final firstProject = teamProjects.first;

                          return _TeamLeaderCard(
                            teamLeaderName: firstProject.studentName,
                            year: firstProject.year,
                            semester: firstProject.semester,
                            teamMembers: firstProject.teamMembers,
                            projects: teamProjects,
                            onProjectTap: (project) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProjectDetailScreen(project: project),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarityAnalysisDialog extends StatefulWidget {
  final String teacherUid;

  const _SimilarityAnalysisDialog({
    required this.teacherUid,
  });

  @override
  State<_SimilarityAnalysisDialog> createState() => _SimilarityAnalysisDialogState();
}

class _SimilarityAnalysisDialogState extends State<_SimilarityAnalysisDialog> {
  bool _isLoading = true;
  List<ProjectModel> _allProjects = [];
  Map<String, List<SimilarityResult>> _similarityMatrix = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _performBulkSimilarityAnalysis();
  }

  Future<void> _performBulkSimilarityAnalysis() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final allProjects = await dbService.getAllProjects();
      
      setState(() {
        _allProjects = allProjects;
      });

      // Perform similarity analysis for each project against all others
      Map<String, List<SimilarityResult>> matrix = {};
      
      for (int i = 0; i < allProjects.length; i++) {
        final currentProject = allProjects[i];
        if (currentProject.id == null) continue; // Skip projects without IDs
        
        final otherProjects = allProjects
            .where((p) => p.id != null && p.id != currentProject.id)
            .map((p) => {
              'id': p.id!,
              'topic': p.topic,
              'description': p.description,
              'domain': p.domain,
              'studentName': p.studentName,
              'year': p.year,
              'semester': p.semester,
            })
            .toList();

        final result = SimilarityService.calculateSimilarity(
          title: currentProject.topic,
          description: currentProject.description,
          existingProjects: otherProjects,
        );

        matrix[currentProject.id!] = result.topSimilarProjects;
      }

      setState(() {
        _similarityMatrix = matrix;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Project Similarity Analysis Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Analyzing project similarities...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error performing similarity analysis',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _error = null;
                                      _isLoading = true;
                                    });
                                    _performBulkSimilarityAnalysis();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildAnalysisResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    if (_allProjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No projects available for analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate statistics
    final highSimilarityProjects = _similarityMatrix.entries
        .where((entry) => entry.value.any((result) => result.similarity > 0.7))
        .length;
    final totalProjects = _allProjects.length;
    
    // Group projects by domain for analysis
    final domainGroups = <String, List<ProjectModel>>{};
    for (final project in _allProjects) {
      domainGroups[project.domain] = (domainGroups[project.domain] ?? [])..add(project);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Projects',
                  value: totalProjects.toString(),
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'High Similarity',
                  value: highSimilarityProjects.toString(),
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Domains',
                  value: domainGroups.length.toString(),
                  icon: Icons.category,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Projects with High Similarity
          if (highSimilarityProjects > 0) ...[
            const Text(
              'Projects with High Similarity (>70%)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildHighSimilarityProjects(),
            const SizedBox(height: 20),
          ],

          // All Projects Analysis
          const Text(
            'All Projects Similarity Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildAllProjectsAnalysis(),
        ],
      ),
    );
  }

  List<Widget> _buildHighSimilarityProjects() {
    final highSimilarityEntries = _similarityMatrix.entries
        .where((entry) => entry.value.any((result) => result.similarity > 0.7))
        .toList();

    return highSimilarityEntries.map((entry) {
      final project = _allProjects.firstWhere((p) => p.id == entry.key, orElse: () => _allProjects.first);
      final highSimilarResults = entry.value.where((r) => r.similarity > 0.7).toList();
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.topic,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      project.domain,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'by ${project.studentName} (${project.year} - Sem ${project.semester})',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Text(
                'Similar to ${highSimilarResults.length} project${highSimilarResults.length > 1 ? 's' : ''}:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              ...highSimilarResults.map((result) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• ${result.projectTitle} (${result.studentName})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(result.similarity * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAllProjectsAnalysis() {
    return _allProjects.where((project) => project.id != null).map((project) {
      final similarities = _similarityMatrix[project.id!] ?? [];
      final maxSimilarity = similarities.isNotEmpty 
          ? similarities.first.similarity 
          : 0.0;
      final similarityColor = _getSimilarityColor(maxSimilarity);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.topic,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${project.studentName} (${project.year} - Sem ${project.semester})',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: similarityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: similarityColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${(maxSimilarity * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: similarityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          project.domain,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (similarities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Top similar projects:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...similarities.take(3).map((result) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${result.projectTitle}',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(result.similarity * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getSimilarityColor(result.similarity),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity > 0.7) {
      return Colors.red;
    } else if (similarity > 0.4) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamLeaderCard extends StatelessWidget {
  final String teamLeaderName;
  final String year;
  final String semester;
  final List<String> teamMembers;
  final List<ProjectModel> projects;
  final Function(ProjectModel) onProjectTap;

  const _TeamLeaderCard({
    required this.teamLeaderName,
    required this.year,
    required this.semester,
    required this.teamMembers,
    required this.projects,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              teamLeaderName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            teamLeaderName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('$year - Semester $semester'),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${teamMembers.length + 1} members'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${projects.length} project${projects.length > 1 ? 's' : ''} submitted',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            ...projects.map((project) => _ProjectTile(
                  project: project,
                  onTap: () => onProjectTap(project),
                )),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.category,
                    label: project.domain,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.analytics,
                    label: '${(project.similarityScore * 100).toStringAsFixed(0)}%',
                    color: project.similarityScore < 0.3
                        ? Colors.green
                        : project.similarityScore < 0.6
                            ? Colors.orange
                            : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
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
        color = Colors.blue;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

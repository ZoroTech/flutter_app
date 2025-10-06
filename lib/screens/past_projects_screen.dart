import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class PastProjectsScreen extends StatefulWidget {
  const PastProjectsScreen({super.key});

  @override
  State<PastProjectsScreen> createState() => _PastProjectsScreenState();
}

class _PastProjectsScreenState extends State<PastProjectsScreen> {
  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedDomain;
  String? _selectedAcademicYear;

  List<String> _availableDomains = [];
  List<String> _availableAcademicYears = [];

  final List<String> _years = ['FE', 'SE', 'TE', 'BE'];
  final List<String> _semesters = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final domains = await dbService.getAvailableDomains();
    final years = await dbService.getAvailableAcademicYears();

    setState(() {
      _availableDomains = domains;
      _availableAcademicYears = years;
    });
  }

  Future<List<Map<String, dynamic>>> _loadProjects() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    return await dbService.getAllPastProjects(
      year: _selectedYear,
      semester: _selectedSemester,
      domain: _selectedDomain,
      academicYear: _selectedAcademicYear,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedSemester = null;
      _selectedDomain = null;
      _selectedAcademicYear = null;
    });
  }

  void _showProjectDetails(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(project['topic'] ?? 'Project Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Team Leader',
                value: project['studentName'] ?? 'N/A',
              ),
              _DetailRow(
                label: 'Year',
                value: project['year'] ?? 'N/A',
              ),
              _DetailRow(
                label: 'Semester',
                value: project['semester'] ?? 'N/A',
              ),
              _DetailRow(
                label: 'Domain',
                value: project['domain'] ?? 'N/A',
              ),
              _DetailRow(
                label: 'Guide',
                value: project['teacherName'] ?? 'N/A',
              ),
              _DetailRow(
                label: 'Academic Year',
                value: project['academicYear']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 8),
              const Text(
                'Team Members:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (project['teamMembers'] != null)
                ...(project['teamMembers'] as List).map((member) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text('• $member'),
                    ))
              else
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('No team members'),
                ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(project['description'] ?? 'No description available'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Projects Archive'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                const Text(
                  'Filter Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown(
                        value: _selectedYear,
                        hint: 'Year',
                        items: _years,
                        onChanged: (value) => setState(() => _selectedYear = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown(
                        value: _selectedSemester,
                        hint: 'Semester',
                        items: _semesters,
                        onChanged: (value) => setState(() => _selectedSemester = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown(
                        value: _selectedDomain,
                        hint: 'Domain',
                        items: _availableDomains,
                        onChanged: (value) => setState(() => _selectedDomain = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown(
                        value: _selectedAcademicYear,
                        hint: 'Academic Year',
                        items: _availableAcademicYears,
                        onChanged: (value) => setState(() => _selectedAcademicYear = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, color: Colors.white),
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadProjects(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading projects',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final projects = snapshot.data ?? [];

                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No past projects found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Text(
                            '${projects.length} project${projects.length != 1 ? 's' : ''} found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () => _showProjectDetails(project),
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
                                            project['topic'] ?? 'Untitled',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'APPROVED',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          project['studentName'] ?? 'Unknown',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.school,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${project['year']} - Sem ${project['semester']}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.category,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          project['domain'] ?? 'Unknown',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AY ${project['academicYear'] ?? 'N/A'}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      project['description'] ?? 'No description',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

class _FilterDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

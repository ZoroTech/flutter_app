import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProjectsScreen extends StatefulWidget {
  const PublicProjectsScreen({super.key});

  @override
  State<PublicProjectsScreen> createState() => _PublicProjectsScreenState();
}

class _PublicProjectsScreenState extends State<PublicProjectsScreen> {
  String? _selectedYear;
  String? _selectedDomain;
  String? _selectedAcademicYear;
  String _searchQuery = '';
  
  List<String> _availableDomains = [];
  List<String> _availableAcademicYears = [];
  
  final List<String> _years = ['FE', 'SE', 'TE', 'BE'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Load available domains
      final domainsSnapshot = await firestore.collection('approved_projects').get();
      final domains = <String>{};
      final academicYears = <String>{};
      
      for (var doc in domainsSnapshot.docs) {
        final data = doc.data();
        if (data['domain'] != null) {
          domains.add(data['domain'].toString());
        }
        if (data['academicYear'] != null) {
          academicYears.add(data['academicYear'].toString());
        }
      }
      
      if (mounted) {
        setState(() {
          _availableDomains = domains.toList()..sort();
          _availableAcademicYears = academicYears.toList()..sort((a, b) => b.compareTo(a));
        });
      }
    } catch (e) {
      print('Error loading filter options: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> _getProjectsStream() {
    Query query = FirebaseFirestore.instance.collection('approved_projects');
    
    if (_selectedYear != null) {
      query = query.where('year', isEqualTo: _selectedYear);
    }
    
    if (_selectedDomain != null) {
      query = query.where('domain', isEqualTo: _selectedDomain);
    }
    
    if (_selectedAcademicYear != null) {
      query = query.where('academicYear', isEqualTo: int.parse(_selectedAcademicYear!));
    }
    
    return query
        .orderBy('approvedAt', descending: true)
        .limit(100) // Limit for performance
        .snapshots()
        .map((snapshot) {
      var projects = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final lowercaseQuery = _searchQuery.toLowerCase();
        projects = projects.where((project) {
          final title = (project['topic'] ?? '').toString().toLowerCase();
          final description = (project['description'] ?? '').toString().toLowerCase();
          final domain = (project['domain'] ?? '').toString().toLowerCase();
          final studentName = (project['studentName'] ?? '').toString().toLowerCase();
          
          return title.contains(lowercaseQuery) ||
                 description.contains(lowercaseQuery) ||
                 domain.contains(lowercaseQuery) ||
                 studentName.contains(lowercaseQuery);
        }).toList();
      }
      
      return projects;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedDomain = null;
      _selectedAcademicYear = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _showProjectDetails(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                project['topic'] ?? 'Project Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                'APPROVED',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Domain', value: project['domain'] ?? 'N/A'),
              _DetailRow(label: 'Year', value: project['year'] ?? 'N/A'),
              _DetailRow(label: 'Semester', value: project['semester'] ?? 'N/A'),
              _DetailRow(label: 'Team Leader', value: project['studentName'] ?? 'N/A'),
              _DetailRow(label: 'Guide Teacher', value: project['teacherName'] ?? 'N/A'),
              _DetailRow(label: 'Academic Year', value: project['academicYear']?.toString() ?? 'N/A'),
              
              if (project['teamMembers'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Team Members:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...(project['teamMembers'] as List).map((member) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text('• $member'),
                    )),
              ],
              
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
        title: const Text('Past Projects Gallery'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with info
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
                  '💡 Get Inspired by Past Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore successful projects from previous years to spark your creativity',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search projects by title, description, or domain...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Filter dropdowns
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        value: _selectedYear,
                        hint: 'Year',
                        items: _years,
                        onChanged: (value) => setState(() => _selectedYear = value),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        value: _selectedDomain,
                        hint: 'Domain',
                        items: _availableDomains,
                        onChanged: (value) => setState(() => _selectedDomain = value),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        value: _selectedAcademicYear,
                        hint: 'Academic Year',
                        items: _availableAcademicYears,
                        onChanged: (value) => setState(() => _selectedAcademicYear = value),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Projects list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getProjectsStream(),
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
                          Icons.lightbulb_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No projects found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
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
                    // Results count
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Text(
                            '${projects.length} inspiring project${projects.length != 1 ? 's' : ''} found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Projects grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return _ProjectCard(
                            project: project,
                            onTap: () => _showProjectDetails(project),
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

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Domain tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDomainColor(project['domain'] ?? '').withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getDomainColor(project['domain'] ?? '').withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  project['domain'] ?? 'General',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getDomainColor(project['domain'] ?? ''),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Project title
              Text(
                project['topic'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Expanded(
                child: Text(
                  project['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Project info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project['studentName'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.school, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${project['year'] ?? '?'} - AY ${project['academicYear'] ?? '?'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDomainColor(String domain) {
    switch (domain.toLowerCase()) {
      case 'ai/ml':
      case 'artificial intelligence':
      case 'machine learning':
        return Colors.purple;
      case 'web development':
        return Colors.blue;
      case 'mobile development':
        return Colors.green;
      case 'iot':
        return Colors.orange;
      case 'blockchain':
        return Colors.indigo;
      case 'data science':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterChip({
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: const TextStyle(fontSize: 12)),
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 12)),
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
            width: 100,
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
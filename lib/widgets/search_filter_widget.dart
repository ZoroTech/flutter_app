import 'package:flutter/material.dart';
import '../models/project_model.dart';

enum ProjectSortBy {
  newest,
  oldest,
  topic,
  status,
  similarity,
}

enum ProjectFilterBy {
  all,
  pending,
  approved,
  rejected,
  declined,
}

class SearchFilterWidget extends StatefulWidget {
  final Function(String query, ProjectSortBy sortBy, ProjectFilterBy filterBy) onChanged;
  final String initialQuery;
  final ProjectSortBy initialSortBy;
  final ProjectFilterBy initialFilterBy;
  final bool showStatusFilter;
  final bool showSimilaritySort;

  const SearchFilterWidget({
    super.key,
    required this.onChanged,
    this.initialQuery = '',
    this.initialSortBy = ProjectSortBy.newest,
    this.initialFilterBy = ProjectFilterBy.all,
    this.showStatusFilter = true,
    this.showSimilaritySort = false,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  late TextEditingController _searchController;
  late ProjectSortBy _currentSortBy;
  late ProjectFilterBy _currentFilterBy;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentSortBy = widget.initialSortBy;
    _currentFilterBy = widget.initialFilterBy;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    widget.onChanged(query, _currentSortBy, _currentFilterBy);
  }

  void _onSortChanged(ProjectSortBy? sortBy) {
    if (sortBy != null) {
      setState(() => _currentSortBy = sortBy);
      widget.onChanged(_searchController.text, sortBy, _currentFilterBy);
    }
  }

  void _onFilterChanged(ProjectFilterBy? filterBy) {
    if (filterBy != null) {
      setState(() => _currentFilterBy = filterBy);
      widget.onChanged(_searchController.text, _currentSortBy, filterBy);
    }
  }

  String _getSortByLabel(ProjectSortBy sortBy) {
    switch (sortBy) {
      case ProjectSortBy.newest:
        return 'Newest First';
      case ProjectSortBy.oldest:
        return 'Oldest First';
      case ProjectSortBy.topic:
        return 'Topic A-Z';
      case ProjectSortBy.status:
        return 'Status';
      case ProjectSortBy.similarity:
        return 'Similarity Score';
    }
  }

  String _getFilterByLabel(ProjectFilterBy filterBy) {
    switch (filterBy) {
      case ProjectFilterBy.all:
        return 'All Status';
      case ProjectFilterBy.pending:
        return 'Pending';
      case ProjectFilterBy.approved:
        return 'Approved';
      case ProjectFilterBy.rejected:
        return 'Rejected';
      case ProjectFilterBy.declined:
        return 'Declined';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search projects by topic, description, or student name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : IconButton(
                            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                            onPressed: () {
                              setState(() => _isExpanded = !_isExpanded);
                            },
                          ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: _onSearchChanged,
                ),
                
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  // Sort and Filter options
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ProjectSortBy>(
                          value: _currentSortBy,
                          decoration: const InputDecoration(
                            labelText: 'Sort by',
                            prefixIcon: Icon(Icons.sort),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          items: [
                            ProjectSortBy.newest,
                            ProjectSortBy.oldest,
                            ProjectSortBy.topic,
                            ProjectSortBy.status,
                            if (widget.showSimilaritySort) ProjectSortBy.similarity,
                          ].map((sortBy) => DropdownMenuItem(
                            value: sortBy,
                            child: Text(_getSortByLabel(sortBy)),
                          )).toList(),
                          onChanged: _onSortChanged,
                        ),
                      ),
                      if (widget.showStatusFilter) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<ProjectFilterBy>(
                            value: _currentFilterBy,
                            decoration: const InputDecoration(
                              labelText: 'Filter by',
                              prefixIcon: Icon(Icons.filter_alt),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            items: ProjectFilterBy.values.map((filterBy) => DropdownMenuItem(
                              value: filterBy,
                              child: Text(_getFilterByLabel(filterBy)),
                            )).toList(),
                            onChanged: _onFilterChanged,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Quick filter chips (always visible)
          if (widget.showStatusFilter)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', ProjectFilterBy.all),
                  _buildFilterChip('Pending', ProjectFilterBy.pending),
                  _buildFilterChip('Approved', ProjectFilterBy.approved),
                  _buildFilterChip('Declined', ProjectFilterBy.declined),
                  _buildFilterChip('Rejected', ProjectFilterBy.rejected),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ProjectFilterBy filterBy) {
    final isSelected = _currentFilterBy == filterBy;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(filterBy),
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class ProjectSearchHelper {
  static List<ProjectModel> searchAndFilterProjects(
    List<ProjectModel> projects,
    String query,
    ProjectSortBy sortBy,
    ProjectFilterBy filterBy,
  ) {
    // Apply filters first
    List<ProjectModel> filtered = projects;
    
    // Filter by status
    if (filterBy != ProjectFilterBy.all) {
      filtered = filtered.where((project) {
        switch (filterBy) {
          case ProjectFilterBy.pending:
            return project.status == 'pending';
          case ProjectFilterBy.approved:
            return project.status == 'approved';
          case ProjectFilterBy.rejected:
            return project.status == 'rejected';
          case ProjectFilterBy.declined:
            return project.status == 'declined';
          case ProjectFilterBy.all:
            return true;
        }
      }).toList();
    }

    // Apply search query
    if (query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filtered = filtered.where((project) {
        return project.topic.toLowerCase().contains(lowercaseQuery) ||
               project.description.toLowerCase().contains(lowercaseQuery) ||
               project.studentName.toLowerCase().contains(lowercaseQuery) ||
               project.domain.toLowerCase().contains(lowercaseQuery) ||
               project.teamMembers.any((member) => 
                   member.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case ProjectSortBy.newest:
        filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        break;
      case ProjectSortBy.oldest:
        filtered.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
        break;
      case ProjectSortBy.topic:
        filtered.sort((a, b) => a.topic.toLowerCase().compareTo(b.topic.toLowerCase()));
        break;
      case ProjectSortBy.status:
        filtered.sort((a, b) {
          const statusOrder = {
            'pending': 0,
            'approved': 1,
            'declined': 2,
            'rejected': 3,
          };
          return (statusOrder[a.status] ?? 4).compareTo(statusOrder[b.status] ?? 4);
        });
        break;
      case ProjectSortBy.similarity:
        filtered.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
        break;
    }

    return filtered;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';
import '../models/project_model.dart';
import 'network_service.dart';
import 'similarity_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveStudent(StudentModel student) async {
    return await NetworkService.instance.executeWithConnectivityCheck(
      () => _db.collection('students').doc(student.uid).set(student.toMap()),
      offlineMessage: 'Cannot save student data while offline.',
    );
  }

  Future<StudentModel?> getStudent(String uid) async {
    return await NetworkService.instance.executeWithConnectivityCheck<StudentModel?>(
      () async {
        final doc = await _db.collection('students').doc(uid).get();
        if (doc.exists) {
          return StudentModel.fromMap(doc.data()!);
        }
        return null;
      },
      offlineMessage: 'Cannot load student data while offline.',
    );
  }

  Future<void> addTeacher(TeacherModel teacher) async {
    await _db.collection('teachers').doc(teacher.uid).set(teacher.toMap());
  }

  Future<List<TeacherModel>> getAllTeachers() async {
    return await NetworkService.instance.executeWithConnectivityCheck(
      () async {
        final snapshot = await _db.collection('teachers').get();
        return snapshot.docs
            .map((doc) => TeacherModel.fromMap(doc.data()))
            .toList();
      },
      offlineMessage: 'Cannot load teachers while offline. Please check your connection.',
    ) ?? [];
  }

  Future<TeacherModel?> getTeacher(String uid) async {
    final doc = await _db.collection('teachers').doc(uid).get();
    if (doc.exists) {
      return TeacherModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<String?> getUserRole(String email) async {
    if (email == 'admin@pvppcoe.ac.in') {
      return 'admin';
    }

    final teachersSnapshot = await _db
        .collection('teachers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (teachersSnapshot.docs.isNotEmpty) {
      return 'teacher';
    }

    final studentsSnapshot = await _db
        .collection('students')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (studentsSnapshot.docs.isNotEmpty) {
      return 'student';
    }

    return null;
  }

  Future<void> submitProject(ProjectModel project) async {
    return await NetworkService.instance.executeWithConnectivityCheck(
      () async {
        final existingProjects = await getProjectsForStudent(project.studentUid);
        if (existingProjects.length >= 4) {
          throw Exception('Maximum 4 project submissions allowed');
        }

        final docRef = await _db.collection('projects').add(project.toMap());
        await docRef.update({'id': docRef.id});
      },
      offlineMessage: 'Cannot submit project while offline. Please check your connection.',
    );
  }

  Future<List<ProjectModel>> getProjectsForTeacher(String teacherUid) async {
    final snapshot = await _db
        .collection('projects')
        .where('teacherUid', isEqualTo: teacherUid)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProjectModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<ProjectModel>> getProjectsForStudent(String studentUid) async {
    final snapshot = await _db
        .collection('projects')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProjectModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateProjectStatus(
    String projectId,
    String status, {
    String? feedback,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    };

    if (feedback != null) {
      updateData['feedback'] = feedback;
    }

    await _db.collection('projects').doc(projectId).update(updateData);

    if (status == 'approved') {
      final projectDoc = await _db.collection('projects').doc(projectId).get();
      if (projectDoc.exists) {
        final project = ProjectModel.fromMap(projectDoc.data()!);
        await _saveToApprovedProjects(project);
      }
    }
  }

  Future<void> _saveToApprovedProjects(ProjectModel project) async {
    final approvedData = {
      'topic': project.topic,
      'description': project.description,
      'domain': project.domain,
      'year': project.year,
      'semester': project.semester,
      'studentName': project.studentName,
      'teacherName': project.teacherName,
      'teamMembers': project.teamMembers,
      'approvedAt': FieldValue.serverTimestamp(),
      'academicYear': DateTime.now().year,
    };

    await _db.collection('approved_projects').add(approvedData);
  }

  Future<List<Map<String, dynamic>>> getApprovedProjectsByYear(String year) async {
    final snapshot = await _db
        .collection('approved_projects')
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateProject(String projectId, String topic, String description) async {
    await _db.collection('projects').doc(projectId).update({
      'topic': topic,
      'description': description,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ProjectModel>> watchProjectsForTeacher(String teacherUid) {
    return _db
        .collection('projects')
        .where('teacherUid', isEqualTo: teacherUid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList());
  }

  Stream<List<ProjectModel>> watchProjectsForStudent(String studentUid) {
    return _db
        .collection('projects')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProjectModel.fromMap(doc.data())).toList());
  }

  Future<List<Map<String, dynamic>>> getAllPastProjects({
    String? year,
    String? semester,
    String? domain,
    String? academicYear,
  }) async {
    Query query = _db.collection('approved_projects');

    if (year != null) {
      query = query.where('year', isEqualTo: year);
    }

    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }

    if (domain != null) {
      query = query.where('domain', isEqualTo: domain);
    }

    if (academicYear != null) {
      query = query.where('academicYear', isEqualTo: int.parse(academicYear));
    }

    final snapshot = await query.orderBy('approvedAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, int>> getPastProjectsStatistics() async {
    final snapshot = await _db.collection('approved_projects').get();

    final stats = <String, int>{
      'total': snapshot.docs.length,
    };

    final domainCounts = <String, int>{};
    final yearCounts = <String, int>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final domain = data['domain'] as String?;
      if (domain != null) {
        domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
      }

      final year = data['year'] as String?;
      if (year != null) {
        yearCounts[year] = (yearCounts[year] ?? 0) + 1;
      }
    }

    stats.addAll(domainCounts);
    stats.addAll(yearCounts);

    return stats;
  }

  Future<List<String>> getAvailableDomains() async {
    final snapshot = await _db.collection('approved_projects').get();
    final domains = <String>{};

    for (var doc in snapshot.docs) {
      final domain = doc.data()['domain'] as String?;
      if (domain != null) {
        domains.add(domain);
      }
    }

    return domains.toList()..sort();
  }

  Future<List<String>> getAvailableAcademicYears() async {
    final snapshot = await _db.collection('approved_projects').get();
    final years = <String>{};

    for (var doc in snapshot.docs) {
      final year = doc.data()['academicYear'];
      if (year != null) {
        years.add(year.toString());
      }
    }

    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  Stream<List<Map<String, dynamic>>> watchAllPastProjects() {
    return _db
        .collection('approved_projects')
        .orderBy('approvedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Check similarity and get domain suggestion for a new project
  Future<SimilarityCheckResult> checkProjectSimilarity({
    required String title,
    required String description,
    String? studentYear,
  }) async {
    return await NetworkService.instance.executeWithConnectivityCheck(
      () async {
        // Get all approved projects for similarity comparison
        List<Map<String, dynamic>> existingProjects = [];
        
        if (studentYear != null) {
          // First try to get projects from the same year
          existingProjects = await getApprovedProjectsByYear(studentYear);
        }
        
        // If we don't have enough projects from the same year, get from all years
        if (existingProjects.length < 10) {
          final allProjectsSnapshot = await _db.collection('approved_projects')
              .orderBy('approvedAt', descending: true)
              .limit(100) // Limit to recent 100 projects for performance
              .get();
          
          existingProjects = allProjectsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        }
        
        // Calculate similarity using our similarity service
        return SimilarityService.calculateSimilarity(
          title: title,
          description: description,
          existingProjects: existingProjects,
        );
      },
      offlineMessage: 'Cannot check project similarity while offline.',
    ) ?? SimilarityCheckResult(
      topSimilarProjects: [],
      suggestedDomain: DomainSuggestion(
        domain: 'Web Development',
        confidence: 0.0,
        supportingProjects: [],
      ),
      hasHighSimilarity: false,
      maxSimilarity: 0.0,
    );
  }

  Future<void> initializeTeachers() async {
    try {
      final teachersSnapshot = await _db.collection('teachers').get();

      if (teachersSnapshot.docs.isEmpty) {
        final teachers = [
          {
            'email': 'teacher1@pvppcoe.ac.in',
            'name': 'Dr. Rajesh Kumar',
            'uid': 'teacher1_uid',
          },
          {
            'email': 'teacher2@pvppcoe.ac.in',
            'name': 'Prof. Priya Sharma',
            'uid': 'teacher2_uid',
          },
          {
            'email': 'teacher3@pvppcoe.ac.in',
            'name': 'Dr. Amit Patel',
            'uid': 'teacher3_uid',
          },
        ];

        for (var teacher in teachers) {
          await _db.collection('teachers').doc(teacher['uid'] as String).set(teacher);
        }
      }
    } catch (e) {
      print('Error initializing teachers: $e');
    }
  }
}

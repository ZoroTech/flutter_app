import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';
import '../models/project_model.dart';
import 'network_service.dart';
import 'error_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveStudent(StudentModel student) async {
    return await NetworkService.instance.executeWithConnectivityCheck(
      () => _db.collection('students').doc(student.uid).set(student.toMap()),
      offlineMessage: 'Cannot save student data while offline.',
    );
  }

  Future<StudentModel?> getStudent(String uid) async {
    return await NetworkService.instance.executeWithConnectivityCheck(
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
}

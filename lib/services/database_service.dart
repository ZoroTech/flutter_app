import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';
import '../models/project_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initializeTeachers() async {
    try {
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
      ];

      for (var teacher in teachers) {
        final doc = await _db.collection('teachers').doc(teacher['uid']).get();
        if (!doc.exists) {
          await _db.collection('teachers').doc(teacher['uid']).set(teacher);
        }
      }
    } catch (e) {
      print('Error initializing teachers: $e');
    }
  }

  Future<void> saveStudent(StudentModel student) async {
    await _db.collection('students').doc(student.uid).set(student.toMap());
  }

  Future<StudentModel?> getStudent(String uid) async {
    final doc = await _db.collection('students').doc(uid).get();
    if (doc.exists) {
      return StudentModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> addTeacher(TeacherModel teacher) async {
    await _db.collection('teachers').doc(teacher.uid).set(teacher.toMap());
  }

  Future<List<TeacherModel>> getAllTeachers() async {
    final snapshot = await _db.collection('teachers').get();
    return snapshot.docs
        .map((doc) => TeacherModel.fromMap(doc.data()))
        .toList();
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
    final docRef = await _db.collection('projects').add(project.toMap());
    await docRef.update({'id': docRef.id});
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

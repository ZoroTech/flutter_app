import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String? id;
  final String studentUid;
  final String studentName;
  final String teacherUid;
  final String teacherName;
  final String topic;
  final String description;
  final String status;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String year;
  final String semester;
  final List<String> teamMembers;
  final String domain;
  final double similarityScore;

  ProjectModel({
    this.id,
    required this.studentUid,
    required this.studentName,
    required this.teacherUid,
    required this.teacherName,
    required this.topic,
    required this.description,
    this.status = 'pending',
    this.feedback,
    required this.submittedAt,
    this.reviewedAt,
    required this.year,
    required this.semester,
    required this.teamMembers,
    this.domain = 'Web Development',
    this.similarityScore = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'studentUid': studentUid,
      'studentName': studentName,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'topic': topic,
      'description': description,
      'status': status,
      'feedback': feedback,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'year': year,
      'semester': semester,
      'teamMembers': teamMembers,
      'domain': domain,
      'similarityScore': similarityScore,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      studentUid: map['studentUid'] ?? '',
      studentName: map['studentName'] ?? '',
      teacherUid: map['teacherUid'] ?? '',
      teacherName: map['teacherName'] ?? '',
      topic: map['topic'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      feedback: map['feedback'],
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      year: map['year'] ?? '',
      semester: map['semester'] ?? '',
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      domain: map['domain'] ?? 'Web Development',
      similarityScore: (map['similarityScore'] ?? 0.0).toDouble(),
    );
  }

  ProjectModel copyWith({
    String? topic,
    String? description,
    String? status,
    String? feedback,
    DateTime? submittedAt,
  }) {
    return ProjectModel(
      id: id,
      studentUid: studentUid,
      studentName: studentName,
      teacherUid: teacherUid,
      teacherName: teacherName,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      status: status ?? this.status,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt,
      year: year,
      semester: semester,
      teamMembers: teamMembers,
      domain: domain,
      similarityScore: similarityScore,
    );
  }
}

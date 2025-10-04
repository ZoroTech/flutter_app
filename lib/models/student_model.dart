class StudentModel {
  final String uid;
  final String email;
  final String teamLeaderName;
  final List<String> teamMembers;
  final String year;
  final String semester;
  final String teacherUid;
  final String teacherName;

  StudentModel({
    required this.uid,
    required this.email,
    required this.teamLeaderName,
    required this.teamMembers,
    required this.year,
    required this.semester,
    required this.teacherUid,
    required this.teacherName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'teamLeaderName': teamLeaderName,
      'teamMembers': teamMembers,
      'year': year,
      'semester': semester,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      teamLeaderName: map['teamLeaderName'] ?? '',
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      year: map['year'] ?? '',
      semester: map['semester'] ?? '',
      teacherUid: map['teacherUid'] ?? '',
      teacherName: map['teacherName'] ?? '',
    );
  }
}

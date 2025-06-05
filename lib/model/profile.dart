class Profile {
  final int? id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: DateTime.parse(json['birthDate']),
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String().split('T')[0], // formato yyyy-MM-dd
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
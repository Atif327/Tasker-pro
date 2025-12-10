class User {
  final int? id;
  final String email;
  final String password;
  final String name;
  final DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

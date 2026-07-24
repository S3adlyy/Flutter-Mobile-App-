/// Represents a user document stored in Firestore under `users/{uid}`.
///
/// `role` is intentionally the only field that determines access —
/// never trust a role passed around in memory without it having come
/// from this model, which is always built from a Firestore read.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "admin" | "employee"
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final ts = map['createdAt'];
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      // Default to 'employee' if a role is ever missing — fail closed,
      // never fail open into admin access.
      role: map['role'] as String? ?? 'employee',
      createdAt: ts == null ? null : (ts as dynamic).toDate() as DateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({String? name, String? role}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
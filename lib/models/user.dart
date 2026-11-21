class User {
  final String userId;
  final String name;
  final String nim;
  final String email;
  final String role;
  final bool isActive;

  const User({
    required this.userId,
    required this.name,
    required this.nim,
    required this.email,
    this.role = 'student',
    this.isActive = true,
  });
}
class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
    required this.roles,
  });

  final String token;
  final String userId;
  final String username;
  final List<String> roles;
}

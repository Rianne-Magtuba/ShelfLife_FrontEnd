class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarPath;

  UserProfile({
    required this.id, required this.username,
    required this.email, this.displayName, this.avatarPath,
  });

  String get initials {
    final name = displayName ?? username;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length < 2 ? name.length : 2).toUpperCase();
  }
}
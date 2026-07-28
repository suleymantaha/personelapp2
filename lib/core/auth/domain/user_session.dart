enum UserRole {
  admin('yönetici'),
  teamCommander('tim_komutani');

  const UserRole(this.storageValue);

  final String storageValue;

  static UserRole? fromStorageValue(String value) {
    for (final role in values) {
      if (role.storageValue == value) return role;
    }
    return null;
  }
}

class UserSessionState {
  const UserSessionState({
    required this.username,
    required this.role,
    this.timId,
  });

  final String username;
  final UserRole role;
  final int? timId;

  bool get isAdmin => role == UserRole.admin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSessionState &&
          username == other.username &&
          role == other.role &&
          timId == other.timId;

  @override
  int get hashCode => Object.hash(username, role, timId);
}

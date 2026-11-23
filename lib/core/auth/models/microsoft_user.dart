class MicrosoftUser {
  final String? id;
  final String? displayName;
  final String? email;
  final String? username;
  final String? tenantId;

  const MicrosoftUser({
    this.id,
    this.displayName,
    this.email,
    this.username,
    this.tenantId,
  });

  factory MicrosoftUser.fromMap(Map<String, dynamic> map) {
    return MicrosoftUser(
      id: map['id']?.toString(),
      displayName: map['name']?.toString() ?? map['displayName']?.toString(),
      email: map['email']?.toString(),
      username:
          map['username']?.toString() ?? map['preferred_username']?.toString(),
      tenantId: map['tenantId']?.toString() ?? map['tenant_id']?.toString(),
    );
  }
}

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  /// İstifadəçinin özü seçdiyi qrup adı
  /// Məsələn: "Naxır", "Sürü", "Otlaq", "Qrup", "İnəklər" ...
  /// Default: "Naxır"
  final String herdGroupLabel;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    this.herdGroupLabel = 'Naxır',
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    String? herdGroupLabel,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      herdGroupLabel: herdGroupLabel ?? this.herdGroupLabel,
    );
  }
}

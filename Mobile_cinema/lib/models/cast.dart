class Cast {
  final int? id;
  final String name;
  final String? avatar;
  final String? characterName;
  final int billingOrder;
  final String role; // 'actor' or 'director'

  Cast({
    this.id,
    required this.name,
    this.avatar,
    this.characterName,
    required this.billingOrder,
    required this.role,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0'),
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      characterName: json['character_name']?.toString(),
      billingOrder: json['billing_order'] is int
          ? json['billing_order']
          : int.tryParse(json['billing_order']?.toString() ?? '0') ?? 0,
      role: json['role']?.toString() ?? 'actor',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'character_name': characterName,
      'billing_order': billingOrder,
      'role': role,
    };
  }

  Cast copyWith({
    int? id,
    String? name,
    String? avatar,
    String? characterName,
    int? billingOrder,
    String? role,
  }) {
    return Cast(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      characterName: characterName ?? this.characterName,
      billingOrder: billingOrder ?? this.billingOrder,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'Cast(id: $id, name: $name, characterName: $characterName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cast && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

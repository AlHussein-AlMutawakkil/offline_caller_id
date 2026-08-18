class TelecomCompany {
  final int? id;
  final String name;
  final String prefix;
  final bool isActive;
  final int sortOrder;

  const TelecomCompany({
    this.id,
    required this.name,
    required this.prefix,
    this.isActive = true,
    this.sortOrder = 0,
  });

  TelecomCompany copyWith({
    int? id,
    String? name,
    String? prefix,
    bool? isActive,
    int? sortOrder,
  }) {
    return TelecomCompany(
      id: id ?? this.id,
      name: name ?? this.name,
      prefix: prefix ?? this.prefix,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory TelecomCompany.fromMap(Map<String, Object?> map) {
    return TelecomCompany(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      prefix: map['prefix']?.toString() ?? '',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId && id != null) 'id': id,
      'name': name,
      'prefix': prefix,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}

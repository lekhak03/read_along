class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isTemporary;
  final List<String> messageIds;

  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    this.isTemporary = false,
    this.messageIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isTemporary': isTemporary,
      'messageIds': messageIds,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      isTemporary: json['isTemporary'] ?? false,
      messageIds: List<String>.from(json['messageIds'] ?? []),
    );
  }

  Chat copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isTemporary,
    List<String>? messageIds,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isTemporary: isTemporary ?? this.isTemporary,
      messageIds: messageIds ?? this.messageIds,
    );
  }
}


class AlarmData {
  final String id;
  final String familyId;
  final String targetUserId;
  final String createdBy;
  final String createdByName;
  final DateTime scheduledTime;
  final String title;
  final String message;
  final bool isActive;
  final List<int> repeatDays;

  AlarmData({
    required this.id,
    required this.familyId,
    required this.targetUserId,
    required this.createdBy,
    required this.createdByName,
    required this.scheduledTime,
    required this.title,
    required this.message,
    this.isActive = true,
    this.repeatDays = const [],
  });

  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'targetUserId': targetUserId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'title': title,
      'message': message,
      'isActive': isActive,
      'repeatDays': repeatDays,
    };
  }

  
  factory AlarmData.fromMap(Map<String, dynamic> map) {
    return AlarmData(
      id: map['id'] as String,
      familyId: map['familyId'] as String,
      targetUserId: map['targetUserId'] as String,
      createdBy: map['createdBy'] as String,
      createdByName: map['createdByName'] as String? ?? 'Family Member',
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      title: map['title'] as String,
      message: map['message'] as String,
      isActive: map['isActive'] as bool? ?? true,
      repeatDays: List<int>.from(map['repeatDays'] as List? ?? []),
    );
  }

  
  AlarmData copyWith({
    String? id,
    String? familyId,
    String? targetUserId,
    String? createdBy,
    String? createdByName,
    DateTime? scheduledTime,
    String? title,
    String? message,
    bool? isActive,
    List<int>? repeatDays,
  }) {
    return AlarmData(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      targetUserId: targetUserId ?? this.targetUserId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      title: title ?? this.title,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  @override
  String toString() {
    return 'AlarmData(id: $id, title: $title, scheduledTime: $scheduledTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AlarmData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final int? bookingId;
  final String? type;
  final int? targetId;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.bookingId,
    this.type,
    this.targetId,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      createdAt: DateTime.parse(json['created_at']),
      bookingId: json['booking_id'] != null
          ? int.tryParse(json['booking_id'].toString())
          : null,
      type: json['type'],
      targetId: json['target_id'] != null
          ? int.tryParse(json['target_id'].toString())
          : null,
      isRead: json['is_read'] == '1' || json['is_read'] == true,
    );
  }
}

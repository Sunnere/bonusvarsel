class PushDispatchPreview {
  final String id;
  final String deviceToken;
  final String platform;
  final String notificationId;
  final String title;
  final String body;
  final String status;

  PushDispatchPreview({
    required this.id,
    required this.deviceToken,
    required this.platform,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.status,
  });

  factory PushDispatchPreview.fromJson(Map<String, dynamic> json) {
    return PushDispatchPreview(
      id: (json['id'] ?? '').toString(),
      deviceToken: (json['deviceToken'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      notificationId: (json['notificationId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

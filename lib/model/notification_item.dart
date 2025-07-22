import 'package:flutter/foundation.dart'; // สำหรับ @required

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? payload;
  final String? eventKey; // เพิ่ม field นี้

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.payload,
    this.eventKey, // เพิ่มใน constructor
  });

  // Factory constructor สำหรับสร้าง NotificationItem จาก JSON
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      payload: json['payload'] as String?,
      eventKey: json['eventKey'] as String?, // ดึงค่า eventKey จาก JSON
    );
  }

  // แปลง NotificationItem เป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
      'eventKey': eventKey, // เพิ่ม eventKey ใน JSON
    };
  }

  // เมธอด copyWith สำหรับสร้าง NotificationItem ใหม่โดยเปลี่ยนบาง field
  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? payload,
    String? eventKey, // เพิ่มใน copyWith
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      eventKey: eventKey ?? this.eventKey, // ใช้ค่าใหม่หรือค่าเดิม
    );
  }
}

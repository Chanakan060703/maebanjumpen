import 'package:flutter/material.dart';
import 'package:maebanjumpen/boxs/notification_service.dart';
import 'package:maebanjumpen/model/notification_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // สำหรับ jsonEncode, jsonDecode
import 'package:uuid/uuid.dart'; // สำหรับสร้าง unique ID

class NotificationManager with ChangeNotifier {
  static const String _notificationsKey = 'notifications';
  List<NotificationItem> _notifications = [];
  final Uuid _uuid = Uuid(); // สร้าง instance ของ Uuid

  // Constructor: โหลดการแจ้งเตือนเมื่อ NotificationManager ถูกสร้าง
  NotificationManager() {
    _loadNotifications();
  }

  List<NotificationItem> get notifications => _notifications;

  // จำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // โหลดการแจ้งเตือนจาก SharedPreferences
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_notificationsKey);
    if (notificationsJson != null) {
      final List<dynamic> decodedList = jsonDecode(notificationsJson);
      _notifications = decodedList
          .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    notifyListeners(); // แจ้งเตือนผู้ฟังว่าข้อมูลมีการเปลี่ยนแปลง
  }

  // บันทึกการแจ้งเตือนลง SharedPreferences
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList =
        jsonEncode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_notificationsKey, encodedList);
  }

  // เพิ่มการแจ้งเตือนใหม่
  Future<void> addNotification({
    required String title,
    required String body,
    String? payload,
    bool showNow = true, // เพิ่ม parameter เพื่อควบคุมการแสดงผลทันที
    DateTime? scheduledDate, // เพิ่ม parameter สำหรับการตั้งเวลา
    String? eventKey, // เพิ่ม eventKey ที่นี่
  }) async {
    // ตรวจสอบว่ามีการแจ้งเตือนด้วย eventKey นี้แล้วหรือไม่
    if (eventKey != null && _notifications.any((n) => n.eventKey == eventKey)) {
      print('Notification with eventKey "$eventKey" already exists. Skipping.');
      return; // ไม่ต้องแจ้งเตือนซ้ำ
    }

    final newNotification = NotificationItem(
      id: _uuid.v4(), // สร้าง unique ID สำหรับการแจ้งเตือน (String)
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      payload: payload,
      eventKey: eventKey, // กำหนด eventKey ให้กับ NotificationItem
    );
    _notifications.insert(0, newNotification); // เพิ่มที่ด้านบนสุด
    await _saveNotifications();
    notifyListeners(); // แจ้งเตือนผู้ฟัง

    // *** เรียกใช้ NotificationService เพื่อแสดงการแจ้งเตือนจริง ***
    final int notificationPluginId = newNotification.id.hashCode; // แปลง String ID เป็น int สำหรับปลั๊กอิน

    if (showNow) {
      await NotificationService.showNotification(
        id: notificationPluginId,
        title: title,
        body: body,
        payload: payload,
      );
    } else if (scheduledDate != null) {
      await NotificationService.scheduleNotification(
        id: notificationPluginId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      );
    }
  }

  // ทำเครื่องหมายว่าการแจ้งเตือนอ่านแล้ว
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners(); // แจ้งเตือนผู้ฟัง
    }
  }

  // ทำเครื่องหมายว่าอ่านทั้งหมด
  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      await _saveNotifications();
      notifyListeners();
    }
  }

  // ลบการแจ้งเตือน
  Future<void> deleteNotification(String notificationId) async {
    // *** ยกเลิกการแจ้งเตือนจาก NotificationService ด้วย ***
    await NotificationService.cancelNotification(notificationId.hashCode); // ใช้ hashCode เพื่อยกเลิก
    
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  // ลบการแจ้งเตือนทั้งหมด
  Future<void> clearAllNotifications() async {
    // *** ยกเลิกการแจ้งเตือนทั้งหมดจาก NotificationService ด้วย ***
    await NotificationService.cancelAllNotifications();

    _notifications = [];
    await _saveNotifications();
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // เปลี่ยนมาใช้ awesome_notifications

class NotificationService {
  // ไม่ต้องใช้ FlutterLocalNotificationsPlugin แล้ว
  // static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // ฟังก์ชันสำหรับเริ่มต้นการทำงานของ Awesome Notifications
  static Future<void> initializeNotifications() async {
    AwesomeNotifications().initialize(
      // 'resource://drawable/res_app_icon', // ไอคอนแอปของคุณ (ต้องมีไฟล์ res_app_icon.png ใน android/app/src/main/res/drawable)
      null, // สามารถตั้งค่าเป็น null เพื่อใช้ไอคอนเริ่มต้นของแอปได้
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic app notifications',
          defaultColor: Color(0xFF9D50DD), // สีเริ่มต้นของช่องการแจ้งเตือน
          ledColor: Colors.white, // สีของไฟ LED (ถ้ามี)
          importance: NotificationImportance.Max, // ระดับความสำคัญสูงสุด
          channelShowBadge: true, // แสดง Badge บนไอคอนแอป
          onlyAlertOnce: true, // แจ้งเตือนเสียง/สั่นแค่ครั้งเดียว
          playSound: true, // เล่นเสียงแจ้งเตือน
          criticalAlerts: true, // การแจ้งเตือนที่สำคัญมาก (สำหรับ iOS)
        ),
        NotificationChannel(
          channelKey: 'scheduled_channel',
          channelName: 'Scheduled notifications',
          channelDescription: 'Notification channel for scheduled notifications',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        ),
      ],
      debug: true, // ตั้งค่าเป็น true เพื่อดู Log ในโหมด Debug
    );

    // ตรวจสอบและขอสิทธิ์การแจ้งเตือน (สำหรับ Android 13+ และ iOS)
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // ถ้ายังไม่ได้รับอนุญาต ให้ขอสิทธิ์
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // ตั้งค่า Listener สำหรับการแจ้งเตือนที่ถูกแตะ (Foreground)
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  // เมธอดสำหรับจัดการการแจ้งเตือนที่ถูกสร้างขึ้น (เมื่อแอปอยู่ใน Foreground)
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.body}');
  }

  // เมธอดสำหรับจัดการการแจ้งเตือนที่แสดงผล (เมื่อแอปอยู่ใน Foreground)
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.body}');
  }

  // เมธอดสำหรับจัดการการแจ้งเตือนที่ถูกปิด (Dismissed)
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification dismissed: ${receivedAction.body}');
  }

  // เมธอดสำหรับจัดการการแจ้งเตือนที่ถูกแตะ (เมื่อผู้ใช้แตะการแจ้งเตือน)
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.body}');
    // คุณสามารถเพิ่ม logic เพื่อนำทางผู้ใช้ไปยังหน้าจอที่เกี่ยวข้องกับ payload ได้ที่นี่
    // ตัวอย่าง: Navigator.of(MyApp.navigatorKey.currentContext!).pushNamed('/notification-page');
  }


  // แสดงการแจ้งเตือนทันที
  static Future<void> showNotification({
    required int id, // Awesome Notifications ใช้ int สำหรับ ID
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel', // ใช้ channelKey ที่เราสร้างไว้
        title: title,
        body: body,
        payload: {'notification_payload': payload ?? ''}, // Awesome Notifications ใช้ Map สำหรับ payload
        notificationLayout: NotificationLayout.Default, // รูปแบบการแจ้งเตือน
      ),
    );
  }

  // ตั้งเวลาแจ้งเตือน
  static Future<void> scheduleNotification({
    required int id, // Awesome Notifications ใช้ int สำหรับ ID
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'scheduled_channel', // ใช้ channelKey สำหรับการแจ้งเตือนแบบตั้งเวลา
        title: title,
        body: body,
        payload: {'notification_payload': payload ?? ''},
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: scheduledDate.year,
        month: scheduledDate.month,
        day: scheduledDate.day,
        hour: scheduledDate.hour,
        minute: scheduledDate.minute,
        second: scheduledDate.second,
        millisecond: 0, // ตั้งค่าเป็น 0
        repeats: false, // ตั้งค่าเป็น true หากต้องการให้แจ้งเตือนซ้ำ
      ),
    );
  }

  // ยกเลิกการแจ้งเตือนที่ระบุ ID
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  // ยกเลิกการแจ้งเตือนทั้งหมด
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}

import 'package:flutter/material.dart';
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/model/notification_item.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // สำหรับจัดรูปแบบวันที่

class NotificationScreen extends StatelessWidget {
  final bool isEnglish;

  const NotificationScreen({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    // Consumer จะ rebuild เฉพาะส่วนนี้เมื่อ NotificationManager มีการเปลี่ยนแปลง
    return Consumer<NotificationManager>(
      builder: (context, notificationManager, child) {
        final notifications = notificationManager.notifications;

        return Scaffold(
          appBar: AppBar(
            title: Text(isEnglish ? 'Notifications' : 'การแจ้งเตือน'),
            backgroundColor: Colors.red,
            actions: [
              // ปุ่มทำเครื่องหมายว่าอ่านทั้งหมด
              if (notificationManager.unreadCount > 0)
                TextButton(
                  onPressed: () {
                    notificationManager.markAllAsRead();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(isEnglish ? 'Mark All Read' : 'ทำเครื่องหมายว่าอ่านทั้งหมด'),
                ),
              // ปุ่มลบทั้งหมด
              if (notifications.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep, color: Colors.white),
                  onPressed: () {
                    // แสดง Dialog ยืนยันก่อนลบ
                    _showClearAllConfirmationDialog(context, notificationManager, isEnglish);
                  },
                ),
            ],
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Text(
                    isEnglish ? 'No notifications yet.' : 'ยังไม่มีการแจ้งเตือน',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: notification.isRead ? Colors.white : Colors.red.shade50, // สีต่างกันถ้ายังไม่อ่าน
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Icon(
                          notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: notification.isRead ? Colors.grey : Colors.red,
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.body),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy HH:mm', isEnglish ? 'en' : 'th').format(notification.timestamp),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        onTap: () {
                          // เมื่อแตะ ให้ทำเครื่องหมายว่าอ่านแล้ว
                          notificationManager.markAsRead(notification.id);
                          // คุณสามารถเพิ่ม logic การนำทางตาม payload ได้ที่นี่
                          // if (notification.payload != null) {
                          //   Navigator.pushNamed(context, notification.payload!);
                          // }
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, notificationManager, notification, isEnglish);
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // Dialog ยืนยันการลบการแจ้งเตือนเดียว
  void _showDeleteConfirmationDialog(BuildContext context, NotificationManager notificationManager, NotificationItem notification, bool isEnglish) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEnglish ? "Delete Notification" : "ลบการแจ้งเตือน"),
          content: Text(isEnglish ? "Are you sure you want to delete this notification?" : "คุณแน่ใจหรือไม่ว่าต้องการลบการแจ้งเตือนนี้?"),
          actions: <Widget>[
            TextButton(
              child: Text(isEnglish ? "Cancel" : "ยกเลิก"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(isEnglish ? "Delete" : "ลบ"),
              onPressed: () {
                notificationManager.deleteNotification(notification.id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog ยืนยันการลบทั้งหมด
  void _showClearAllConfirmationDialog(BuildContext context, NotificationManager notificationManager, bool isEnglish) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEnglish ? "Clear All Notifications" : "ล้างการแจ้งเตือนทั้งหมด"),
          content: Text(isEnglish ? "Are you sure you want to clear all notifications?" : "คุณแน่ใจหรือไม่ว่าต้องการล้างการแจ้งเตือนทั้งหมด?"),
          actions: <Widget>[
            TextButton(
              child: Text(isEnglish ? "Cancel" : "ยกเลิก"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(isEnglish ? "Clear All" : "ล้างทั้งหมด"),
              onPressed: () {
                notificationManager.clearAllNotifications();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

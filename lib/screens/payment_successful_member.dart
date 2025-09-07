import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/model/hirer.dart'; // Import Hirer model
import 'package:maebanjumpen/screens/home_member.dart';

class PaymentSuccessfulPage extends StatelessWidget {
  final double amount;
  final bool isEnglish;
  final Hirer user; // เพิ่ม Hirer user เข้ามาในหน้า PaymentSuccessfulPage

  const PaymentSuccessfulPage({
    super.key,
    required this.amount,
    required this.isEnglish,
    required this.user, // กำหนดให้ user เป็น required
  });

  @override
  Widget build(BuildContext context) {
    final String displayAmount = NumberFormat('#,##0.00').format(amount);
    final String currentDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    final String currentTime = DateFormat('hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle, // หรือไอคอนวงกลมถูกตามรูป
                color: Colors.red, // สีแดงตามรูป
                size: 100, // ขนาดใหญ่พอสมควร
              ),
              const SizedBox(height: 30),
              Text(
                isEnglish ? 'Deposit Successful!' : 'เติมเงินสำเร็จ!', // ข้อความ "Payment Successful!"
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '฿$displayAmount', // จำนวนเงินที่แสดง
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[100], // สีพื้นหลังอ่อนๆ
                  borderRadius: BorderRadius.circular(10), // ขอบโค้งมน
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEnglish ? 'Date & Time' : 'วันที่และเวลา', // ข้อความ "Date & Time"
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$currentDate • $currentTime', // วันที่และเวลาปัจจุบัน
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // กลับไปหน้า Home โดยล้าง Stack ของ Route ทั้งหมดที่อยู่ข้างใต้
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          user: user, // ส่ง Hirer user กลับไปที่ HomePage
                          isEnglish: isEnglish,
                        ),
                      ),
                      (Route<dynamic> route) => false, // ลบทุก Route ที่อยู่ข้างใต้
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // ปุ่มสีแดง
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.home, color: Colors.white), // ไอคอนบ้าน
                  label: Text(
                    isEnglish ? 'Back to Home' : 'กลับสู่หน้าหลัก', // ข้อความ "Back to Home"
                    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

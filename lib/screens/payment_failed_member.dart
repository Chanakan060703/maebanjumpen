import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/screens/home_member.dart';

class PaymentFailedPage extends StatelessWidget {
  final bool isEnglish;
  final Hirer user;

  const PaymentFailedPage({
    super.key,
    required this.isEnglish,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 30),
              Text(
                isEnglish ? 'Deposit Failed!' : 'เติมเงินไม่สำเร็จ!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isEnglish ? 'Please try again or contact support.' : 'กรุณาลองใหม่อีกครั้ง หรือติดต่อฝ่ายสนับสนุน',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          user: user,
                          isEnglish: isEnglish,
                        ),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: Text(
                    isEnglish ? 'Back to Home' : 'กลับสู่หน้าหลัก',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
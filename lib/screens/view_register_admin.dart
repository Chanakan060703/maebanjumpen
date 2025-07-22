import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart'; // Import controller

class VerlifyRegisterDetailScreen extends StatelessWidget {
  final Housekeeper housekeeper;
  final bool isEnglish;

  // <<< แก้ไขตรงนี้: เพิ่ม const constructor
  const VerlifyRegisterDetailScreen({
    super.key,
    required this.housekeeper,
    required this.isEnglish,
  });

  // สร้าง instance ของ controller
  final HousekeeperController _housekeeperController = const HousekeeperController(); // <<< ต้องเป็น const ด้วย

  @override
  Widget build(BuildContext context) {
    // กำหนด ImageProvider สำหรับรูปโปรไฟล์
    ImageProvider profileImageProvider;
    if (housekeeper.person?.pictureUrl != null &&
        (housekeeper.person!.pictureUrl!.startsWith('http://') ||
            housekeeper.person!.pictureUrl!.startsWith('https://'))) {
      profileImageProvider = NetworkImage(housekeeper.person!.pictureUrl!);
    } else {
      profileImageProvider = const AssetImage('assets/images/default_profile.png');
    }

    // กำหนด ImageProvider สำหรับรูปบัตรประชาชน (ถ้ามี)
    ImageProvider idCardImageProvider;
    if (housekeeper.photoVerifyUrl != null &&
        (housekeeper.photoVerifyUrl!.startsWith('http://') ||
            housekeeper.photoVerifyUrl!.startsWith('https://'))) {
      idCardImageProvider = NetworkImage(housekeeper.photoVerifyUrl!);
    } else {
      idCardImageProvider = const AssetImage('assets/images/default_id_card.png'); // รูปภาพเริ่มต้นสำหรับบัตรประชาชน
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // ปิดหน้าปัจจุบัน
          },
        ),
        title: Text(
          isEnglish ? 'Verification Details' : 'รายละเอียดการยืนยัน',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // รูปภาพโปรไฟล์ด้านบน
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImageProvider,
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 20),
                    // รายละเอียดข้อมูล
                    _buildDetailRow(isEnglish ? 'Account Type' : 'ประเภทบัญชี', 'Housekeeper'),
                    _buildDetailRow(isEnglish ? 'ID' : 'รหัส', 'H${housekeeper.id ?? 'N/A'}'),
                    _buildDetailRow(isEnglish ? 'Username' : 'ชื่อผู้ใช้', housekeeper.person?.login?.username ?? 'N/A'),
                    _buildDetailRow(isEnglish ? 'First Name' : 'ชื่อ', housekeeper.person?.firstName ?? 'N/A'),
                    _buildDetailRow(isEnglish ? 'Last Name' : 'นามสกุล', housekeeper.person?.lastName ?? 'N/A'),
                    _buildDetailRow(isEnglish ? 'Email' : 'อีเมล', housekeeper.person?.email ?? 'N/A'),
                    _buildDetailRow(isEnglish ? 'Phone' : 'เบอร์โทรศัพท์', housekeeper.person?.phoneNumber ?? 'N/A'),
                    _buildDetailRow(isEnglish ? 'Address' : 'ที่อยู่', housekeeper.person?.address ?? 'N/A'),
                    _buildDetailRow(isEnglish ? 'ID Card Number' : 'เลขบัตรประชาชน', housekeeper.person?.idCardNumber ?? 'N/A'),
                    _buildDetailRow(isEnglish ? 'Password' : 'รหัสผ่าน', '********'),
                    _buildDetailRow(isEnglish ? 'Confirm Password' : 'ยืนยันรหัสผ่าน', '********'),
                    const SizedBox(height: 20),
                    // รูปภาพบัตรประชาชนด้านล่าง
                    Text(
                      isEnglish ? 'ID Card Verification Photo' : 'รูปภาพบัตรประชาชนเพื่อยืนยันตัวตน',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                        image: DecorationImage(
                          image: idCardImageProvider,
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            print('Error loading ID card image: $exception');
                            // Fallback to default image if network image fails
                            // Note: This won't update the UI immediately unless wrapped in a StatefullWidget
                            // For simplicity, we keep it as StatelessWidget for now, but in a real app,
                            // you might want to manage image loading state.
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ปุ่ม Reject และ Approve
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // อัปเดตสถานะเป็น 'rejected'
                      try {
                        await _housekeeperController.updateHousekeeperStatus(housekeeper.id!, 'rejected');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEnglish ? 'Housekeeper Rejected!' : 'ปฏิเสธแม่บ้านสำเร็จ!')),
                        );
                        Navigator.pop(context); // กลับไปยังหน้าก่อนหน้า
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEnglish ? 'Failed to reject: $e' : 'ปฏิเสธไม่สำเร็จ: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      isEnglish ? 'Reject' : 'ปฏิเสธ',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // อัปเดตสถานะเป็น 'verified'
                      try {
                        await _housekeeperController.updateHousekeeperStatus(housekeeper.id!, 'verified');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEnglish ? 'Housekeeper verified!' : 'ยืนยันแม่บ้านสำเร็จ!')),
                        );
                        Navigator.pop(context); // กลับไปยังหน้าก่อนหน้า
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEnglish ? 'Failed to verified: $e' : 'ยืนยันไม่สำเร็จ: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      isEnglish ? 'Verify' : 'อนุมัติ',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title :',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

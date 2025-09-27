import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/controller/housekeeperController.dart';

class VerifyRegisterDetailScreen extends StatefulWidget {
  final Housekeeper housekeeper;
  final bool isEnglish;

  const VerifyRegisterDetailScreen({
    super.key,
    required this.housekeeper,
    required this.isEnglish,
  });

  @override
  State<VerifyRegisterDetailScreen> createState() => _VerifyRegisterDetailScreenState();
}

class _VerifyRegisterDetailScreenState extends State<VerifyRegisterDetailScreen> {
  late HousekeeperController _housekeeperController;
  late Housekeeper _housekeeper;

  @override
  void initState() {
    super.initState();
    _housekeeperController = HousekeeperController();
    _housekeeper = widget.housekeeper;
  }

  ImageProvider _getProfileImage() {
    final url = _housekeeper.person?.pictureUrl;
    if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
      return NetworkImage(url);
    }
    return const AssetImage('assets/images/default_profile.png');
  }

  ImageProvider _getIdCardImage() {
    final url = _housekeeper.photoVerifyUrl;
    if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
      return NetworkImage(url);
    }
    return const AssetImage('assets/images/default_id_card.png');
  }

  Future<void> _updateStatus(String status) async {
    try {
      await _housekeeperController.updateHousekeeperStatus(_housekeeper.id!, status);
      setState(() {
        _housekeeper.statusVerify = status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? (status == 'verified' ? 'Housekeeper Verified!' : 'Housekeeper Rejected!')
                : (status == 'verified' ? 'ยืนยันแม่บ้านสำเร็จ!' : 'ปฏิเสธแม่บ้านสำเร็จ!'),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Failed to $status: $e'
                : 'ไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = _housekeeper;
    final p = h.person;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isEnglish ? 'Verification Details' : 'รายละเอียดการยืนยัน',
            style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: _getProfileImage(), backgroundColor: Colors.grey[200]),
                    const SizedBox(height: 20),
                    _buildDetailRow(widget.isEnglish ? 'Account Type' : 'ประเภทบัญชี',
                        widget.isEnglish ? 'Housekeeper' : 'แม่บ้าน'),
                    _buildDetailRow(widget.isEnglish ? 'ID' : 'รหัส', 'H${h.id ?? 'N/A'}'),
                    _buildDetailRow(widget.isEnglish ? 'First Name' : 'ชื่อ', p?.firstName ?? 'N/A'),
                    _buildDetailRow(widget.isEnglish ? 'Last Name' : 'นามสกุล', p?.lastName ?? 'N/A'),
                    _buildDetailRow(widget.isEnglish ? 'Email' : 'อีเมล', p?.email ?? 'N/A'),
                    _buildDetailRow(widget.isEnglish ? 'Phone' : 'เบอร์โทรศัพท์', p?.phoneNumber ?? 'N/A'),
                    _buildDetailRow(widget.isEnglish ? 'Address' : 'ที่อยู่', p?.address ?? 'N/A'),
                    _buildDetailRow(widget.isEnglish ? 'ID Card Number' : 'เลขบัตรประชาชน', p?.idCardNumber ?? 'N/A'),
                    const SizedBox(height: 20),
                    Text(widget.isEnglish ? 'ID Card Verification Photo' : 'รูปภาพบัตรประชาชนเพื่อยืนยันตัวตน',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                        image: DecorationImage(
                          image: _getIdCardImage(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('REJECTED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(widget.isEnglish ? 'Reject' : 'ปฏิเสธ',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus('APPROVED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(widget.isEnglish ? 'Verify' : 'อนุมัติ',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

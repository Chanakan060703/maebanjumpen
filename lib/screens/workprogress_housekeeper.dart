import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/controller/image_uploadController.dart';
import 'package:maebanjumpen/model/hire.dart'; // Import Hire model
// หากคุณมีไฟล์ AppColors หรือ Styles โปรดนำเข้ามาที่นี่
// import 'package:maebanjumpen/styles/app_colors.dart'; // ตัวอย่าง

class WorkProgressScreen extends StatefulWidget {
  final Hire hire; // เพิ่มตัวแปรสำหรับรับ Hire object
  final bool isEnglish; // เพิ่มตัวแปรสำหรับภาษา

  const WorkProgressScreen({
    super.key,
    required this.hire,
    required this.isEnglish,
  });

  @override
  State<WorkProgressScreen> createState() => _WorkProgressScreenState();
}

class _WorkProgressScreenState extends State<WorkProgressScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedFiles = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // ถ้ามี progressionImageUrl อยู่แล้วจากการทำงานครั้งก่อน (Continue Work Report)
    // คุณอาจจะดึงรูปภาพเหล่านั้นมาแสดงที่นี่ได้
    // ตัวอย่าง:
    // if (widget.hire.progressionImageUrl != null && widget.hire.progressionImageUrl!.isNotEmpty) {
    //   // คุณจะต้องแปลง URL เป็น XFile หรือ File เพื่อแสดง
    //   // ซึ่งอาจจะซับซ้อนและต้องใช้ packages เช่น cached_network_image และ path_provider
    //   // สำหรับตอนนี้ เราจะละไว้ก่อน
    // }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    if (_pickedFiles.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish
              ? 'You can upload a maximum of 4 photos.'
              : 'สามารถอัปโหลดรูปภาพได้สูงสุด 4 รูป.'),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _pickedFiles.add(image);
        });
      }
    } catch (e) {
      // Handle potential PlatformException (e.g., no camera, permissions not granted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish
              ? 'Failed to pick image: ${e.toString()}'
              : 'ไม่สามารถเลือกรูปภาพได้: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(widget.isEnglish ? 'Take Photo' : 'ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(widget.isEnglish ? 'Choose from Gallery' : 'เลือกจากคลังรูปภาพ'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImagesAndSubmitReport() async {
    if (_pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish
              ? 'Please add at least one photo before submitting.'
              : 'โปรดเพิ่มรูปภาพอย่างน้อยหนึ่งรูปก่อนส่ง.'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final ImageUploadService imageUploadService = ImageUploadService();
    String? latestUploadedUrl; // หาก Backend คาดหวังเพียง URL เดียว หรืออัปเดตเรื่อยๆ

    for (XFile file in _pickedFiles) {
      final String? imageUrl = await imageUploadService.uploadImage(
        id: widget.hire.hireId!, // ใช้ hireId จาก Hire object
        imageType: 'hire',
        imageFile: file,
      );
      if (imageUrl != null) {
        latestUploadedUrl = imageUrl; // เก็บ URL ล่าสุด
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish
                ? 'Failed to upload image: ${file.name}'
                : 'ไม่สามารถอัปโหลดรูปภาพ: ${file.name}'),
          ),
        );
        setState(() {
          _isUploading = false;
        });
        return; // หยุดการทำงานถ้ามีรูปใดรูปหนึ่งอัปโหลดไม่สำเร็จ
      }
    }

    final Hirecontroller hireController = Hirecontroller();
    try {
      // สร้าง Hire object ใหม่ที่มีสถานะและ URL รูปภาพที่อัปเดต
      final updatedHire = widget.hire.copyWith(
        jobStatus: 'pendingapproval', // เปลี่ยนเป็น 'pendingapproval'
        progressionImageUrl: latestUploadedUrl, // ใช้ URL ล่าสุดที่อัปโหลด
      );

      final Hire? responseHire = await hireController.updateHire(
        widget.hire.hireId!,
        updatedHire,
      );

      if (responseHire != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish
                ? 'Work report submitted and job status updated to pending approval!'
                : 'ส่งรายงานการทำงานและอัปเดตสถานะงานเป็นรอการอนุมัติแล้ว!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ส่ง true กลับไปเพื่อรีเฟรชหน้าก่อนหน้า
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish
                ? 'Failed to update job status after image upload.'
                : 'ไม่สามารถอัปเดตสถานะงานหลังจากอัปโหลดรูปภาพ.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish
              ? 'Error submitting report: $e'
              : 'เกิดข้อผิดพลาดในการส่งรายงาน: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pickedFiles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    File(_pickedFiles.elementAt(index).path),
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    iconSize: 20,
                    onPressed: () {
                      setState(() {
                        _pickedFiles.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดวันที่ในรูปแบบที่อ่านง่าย
    String formattedServiceDate = widget.hire.startDate != null
        ? '${widget.hire.startDate!.day} '
            '${_getMonthName(widget.hire.startDate!.month, widget.isEnglish)} '
            '${widget.hire.startDate!.year}'
        : (widget.isEnglish ? 'N/A' : 'ไม่มีข้อมูล');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isEnglish ? 'Work Report' : 'รายงานการทำงาน',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              // TODO: แสดงข้อมูลช่วยเหลือ
              print('Help button pressed');
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashedBorderContainer(
              backgroundColor: Colors.grey,
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: _pickedFiles.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined,
                                color: Colors.red, size: 40),
                            onPressed: _showImageSourceActionSheet, // เรียกใช้ ActionSheet
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.isEnglish
                                ? 'Add Photos (0/4)'
                                : 'เพิ่มรูปภาพ (0/4)',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildImagePreview()),
                          if (_pickedFiles.length < 4)
                            TextButton.icon(
                              onPressed: _showImageSourceActionSheet, // เรียกใช้ ActionSheet
                              icon: const Icon(Icons.add_a_photo,
                                  color: Colors.red),
                              label: Text(
                                widget.isEnglish
                                    ? 'Add More (${_pickedFiles.length}/4)'
                                    : 'เพิ่มอีก (${_pickedFiles.length}/4)',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              widget.isEnglish ? 'Work Details' : 'รายละเอียดงาน',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            _buildDetailCard(
              title: widget.isEnglish ? 'Client Name' : 'ชื่อลูกค้า',
              value: widget.hire.hirer?.person?.firstName != null
                  ? '${widget.hire.hirer!.person!.firstName} ${widget.hire.hirer!.person!.lastName}'
                  : (widget.isEnglish ? 'Unknown Client' : 'ลูกค้าไม่ทราบชื่อ'),
            ),
            const SizedBox(height: 15),
            _buildDetailCard(
              title: widget.isEnglish ? 'Service Date' : 'วันที่ให้บริการ',
              value: formattedServiceDate,
            ),
            const SizedBox(height: 15),
            _buildDetailCard(
              title: widget.isEnglish ? 'Service Time' : 'เวลาให้บริการ',
              value:
                  '${widget.hire.startTime ?? (widget.isEnglish ? 'N/A' : 'ไม่มีข้อมูล')} - ${widget.hire.endTime ?? (widget.isEnglish ? 'N/A' : 'ไม่มีข้อมูล')}',
            ),
            const SizedBox(height: 15),
            _buildDetailCard(
              title: widget.isEnglish ? 'Location' : 'สถานที่',
              value: widget.hire.location ??
                  (widget.isEnglish ? 'No address provided' : 'ไม่มีที่อยู่'),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImagesAndSubmitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        widget.isEnglish ? 'Submit Progress' : 'ส่งความคืบหน้า',
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // ควรตั้งค่าให้ถูกต้องตามหน้าปัจจุบัน
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.work),
            label: widget.isEnglish ? 'History' : 'ประวัติงาน',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: widget.isEnglish ? 'Withdrawal' : 'ถอนเงิน',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
        onTap: (index) {
          // TODO: Implement navigation logic
          print('Tapped item: $index');
        },
      ),
    );
  }

  // Helper function for month name (optional)
  String _getMonthName(int month, bool isEnglish) {
    if (isEnglish) {
      switch (month) {
        case 1:
          return 'January';
        case 2:
          return 'February';
        case 3:
          return 'March';
        case 4:
          return 'April';
        case 5:
          return 'May';
        case 6:
          return 'June';
        case 7:
          return 'July';
        case 8:
          return 'August';
        case 9:
          return 'September';
        case 10:
          return 'October';
        case 11:
          return 'November';
        case 12:
          return 'December';
        default:
          return '';
      }
    } else {
      switch (month) {
        case 1:
          return 'มกราคม';
        case 2:
          return 'กุมภาพันธ์';
        case 3:
          return 'มีนาคม';
        case 4:
          return 'เมษายน';
        case 5:
          return 'พฤษภาคม';
        case 6:
          return 'มิถุนายน';
        case 7:
          return 'กรกฎาคม';
        case 8:
          return 'สิงหาคม';
        case 9:
          return 'กันยายน';
        case 10:
          return 'ตุลาคม';
        case 11:
          return 'พฤศจิกายน';
        case 12:
          return 'ธันวาคม';
        default:
          return '';
      }
    }
  }

  Widget _buildDetailCard({required String title, required String value}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter สำหรับวาดเส้นประ (DashedBorderPainter)
class DashedBorderPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;
  final double dashLength;
  final BorderRadius borderRadius;

  DashedBorderPainter({
    this.strokeWidth = 2.0,
    this.color = Colors.grey,
    this.gap = 5.0,
    this.dashLength = 10.0,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect outerRect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    Path path = Path();
    path.addRRect(outerRect);

    ui.PathMetric pathMetric = path.computeMetrics().first;
    double currentLength = 0;
    while (currentLength < pathMetric.length) {
      canvas.drawPath(
        pathMetric.extractPath(currentLength, currentLength + dashLength),
        paint,
      );
      currentLength += dashLength + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Custom Widget เพื่อให้ใช้งานเส้นประได้ง่ายขึ้น (DashedBorderContainer)
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double strokeWidth;
  final Color color;
  final double gap;
  final double dashLength;
  final BorderRadius borderRadius;
  final MaterialColor backgroundColor;

  const DashedBorderContainer({
    super.key,
    required this.child,
    this.strokeWidth = 2.0,
    this.color = Colors.grey,
    this.gap = 5.0,
    this.dashLength = 10.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(15.0)),
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.shade100,
        borderRadius: borderRadius,
      ),
      child: CustomPaint(
        painter: DashedBorderPainter(
          strokeWidth: strokeWidth,
          color: color,
          gap: gap,
          dashLength: dashLength,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}
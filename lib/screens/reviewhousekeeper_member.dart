import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/controller/hireController.dart';
import 'package:maebanjumpen/controller/reviewController.dart';
import 'package:maebanjumpen/model/review.dart';
import 'package:maebanjumpen/model/hire.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/profile_member.dart';
import 'package:http/http.dart' as http;
import 'package:maebanjumpen/constant/constant_value.dart';

class ReviewHousekeeperPage extends StatefulWidget {
  final Hire hire;
  final bool isEnglish;
  final Hirer user;

  const ReviewHousekeeperPage({
    super.key,
    required this.hire,
    this.isEnglish = true,
    required this.user,
  });

  @override
  _ReviewHousekeeperPageState createState() => _ReviewHousekeeperPageState();
}

class _ReviewHousekeeperPageState extends State<ReviewHousekeeperPage> {
  int _rating = 0;
  final TextEditingController _reviewTextController = TextEditingController();
  final int _selectedIndex = 2;
  bool _isLoading = false;

  late final String _housekeeperName;
  late final String? _housekeeperImage;
  late final String _hireId;
  late final DateTime _hireDate;
  late final String _hireName;

  final Reviewcontroller _reviewApi = Reviewcontroller();
  final Hirecontroller _hireApi = Hirecontroller();

  @override
  void initState() {
    super.initState();
    final hire = widget.hire;

    _housekeeperName =
        hire.housekeeper?.person?.firstName ??
        (widget.isEnglish ? 'N/A' : 'ไม่ระบุ');
    _housekeeperImage = hire.housekeeper?.person?.pictureUrl;
    _hireId = hire.hireId?.toString() ?? '0';
    _hireDate = hire.startDate ?? DateTime.now();
    _hireName =
        hire.hireName ??
        (widget.isEnglish ? 'No Service Name' : 'ไม่มีชื่องาน');
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  void _onStarTap(int index) {
    setState(() {
      _rating = index;
    });
  }

  bool get _canSubmit =>
      _rating > 0 &&
      _reviewTextController.text.trim().isNotEmpty &&
      !_isLoading;

  String _formatDate(DateTime date) {
    if (widget.isEnglish) {
      return DateFormat.yMMMd('en_US').format(date);
    } else {
      return "${DateFormat('dd MMM', 'th_TH').format(date)} ${date.year + 543}";
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitReview() async {
    if (!_canSubmit) {
      _showSnackbar(
        widget.isEnglish
            ? 'Please rate and write a review.'
            : 'โปรดให้คะแนนและเขียนรีวิวก่อนส่ง',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final String reviewDateTime = now.toIso8601String();
      final int? hireId = int.tryParse(_hireId);

      if (hireId == null) {
        throw Exception(
          widget.isEnglish
              ? 'Invalid hireId: $_hireId'
              : 'รหัสการจ้างไม่ถูกต้อง: $_hireId',
        );
      }

      final response = await _reviewApi.addReview(
        reviewMessage: _reviewTextController.text.trim(),
        reviewDate: reviewDateTime,
        score: _rating,
        hireId: hireId,
      );

      if (response.containsKey('reviewId')) {
        _showSnackbar(
          widget.isEnglish
              ? 'Review submitted successfully!'
              : 'ส่งรีวิวเรียบร้อยแล้ว!',
        );
        if (mounted) {
          // ส่งค่า true กลับไปเมื่อรีวิวสำเร็จ
          // เพื่อแจ้งให้หน้า HireListPage โหลดข้อมูลใหม่
          Navigator.pop(context, true); 
        }
      } else {
        _showSnackbar(
          widget.isEnglish
              ? 'Failed to submit review: ${response['message'] ?? 'Unknown error'}'
              : 'ส่งรีวิวไม่สำเร็จ: ${response['message'] ?? 'เกิดข้อผิดพลาดไม่ทราบสาเหตุ'}',
        );
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      _showSnackbar(
        widget.isEnglish ? 'An error occurred: $e' : 'เกิดข้อผิดพลาด: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    final user = widget.user;
    final bool isEnglish = widget.isEnglish;
    final pages = [
      HomePage(user: user, isEnglish: isEnglish),
      CardpageMember(user: user, isEnglish: isEnglish),
      HireListPage(user: user, isEnglish: isEnglish,),
      ProfileMemberPage(user: user, isEnglish: isEnglish),
    ];

    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => pages[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildReviewBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.red),
        onPressed: () {
          // ส่งค่า true กลับไปเมื่อผู้ใช้กดปุ่มย้อนกลับ
          // ซึ่งจะกระตุ้นให้หน้าก่อนหน้า (HireListPage) โหลดข้อมูลใหม่
          Navigator.pop(context, true); 
        },
      ),
      title: Text(
        widget.isEnglish ? 'Review Housekeeper' : 'รีวิวแม่บ้าน',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildReviewBody() {
    ImageProvider housekeeperImageProvider;
    if (_housekeeperImage != null &&
        _housekeeperImage!.isNotEmpty &&
        (_housekeeperImage!.startsWith('http://') ||
            _housekeeperImage!.startsWith('https://'))) {
      housekeeperImageProvider = NetworkImage(_housekeeperImage!);
    } else {
      housekeeperImageProvider = const AssetImage(
        'assets/placeholder_housekeeper.png',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            widget.isEnglish
                ? 'Rate Your Experience'
                : 'ให้คะแนนประสบการณ์ของคุณ',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: index < _rating ? Colors.amber : Colors.grey,
                ),
                onPressed: _isLoading ? null : () => _onStarTap(index + 1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isEnglish ? 'Tap stars to rate' : 'แตะดาวเพื่อให้คะแนน',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundImage: housekeeperImageProvider,
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Error loading housekeeper image: $exception');
            },
          ),
          const SizedBox(height: 8),
          Text(
            _housekeeperName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDate(_hireDate)} • ${widget.hire.startTime ?? ''} - ${widget.hire.endTime ?? ''}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _hireName,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reviewTextController,
            maxLines: 5,
            maxLength: 500,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText:
                  widget.isEnglish
                      ? 'Write your review...'
                      : 'เขียนรีวิวของคุณ...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submitReview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canSubmit ? Colors.red : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.isEnglish ? 'Submit Review' : 'ส่งรีวิว',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      onTap: _onItemTapped,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: widget.isEnglish ? 'Home' : 'หน้าหลัก',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.credit_card),
          label: widget.isEnglish ? 'Card' : 'บัตร',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month),
          label: widget.isEnglish ? 'Booking' : 'การจอง',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/screens/editprofile_member.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/deposit_member.dart';
import 'package:maebanjumpen/screens/hirelist_member.dart';
import 'package:maebanjumpen/screens/login.dart';

class ProfileMemberPage extends StatefulWidget {
  final Hirer user;
  final bool isEnglish;

  const ProfileMemberPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _ProfileMemberPageState createState() => _ProfileMemberPageState();
}

class _ProfileMemberPageState extends State<ProfileMemberPage> {
  bool _showFullAddress = false;
  final int _maxAddressLength = 30;

  final int _currentIndex = 3;

  late Hirer _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _navigateToEditProfile() async {
    final Hirer? updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileMemberPage(
          user: _currentUser,
          isEnglish: widget.isEnglish,
        ),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayedAddress = _currentUser.person?.address ?? 'N/A';
    bool showReadMore = false;
    String readMoreButtonText = widget.isEnglish ? 'Read More' : 'ดูเพิ่มเติม';

    if (!_showFullAddress && (displayedAddress.length > _maxAddressLength)) {
      displayedAddress = '${displayedAddress.substring(0, _maxAddressLength)}...';
      showReadMore = true;
      readMoreButtonText = widget.isEnglish ? 'Read More' : 'ดูเพิ่มเติม';
    } else if (_showFullAddress &&
        (_currentUser.person?.address?.length ?? 0) > _maxAddressLength) {
      displayedAddress = _currentUser.person?.address ?? 'N/A';
      showReadMore = true;
      readMoreButtonText = widget.isEnglish ? 'Show Less' : 'ดูน้อยลง';
    } else {
      showReadMore = false;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                user: widget.user,
                isEnglish: widget.isEnglish,
              ),
            ),
          ),
        ),
        title: Center(
          child: Text(
            widget.isEnglish ? 'Profile' : 'โปรไฟล์',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          // Re-added the Logout IconButton to AppBar actions
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout, // Call the logout function
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60.0,
                  backgroundImage: _currentUser.person != null &&
                          _currentUser.person?.pictureUrl != null
                      ? NetworkImage(_currentUser.person!.pictureUrl!)
                      : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              '${_currentUser.person?.firstName ?? ''} ${_currentUser.person?.lastName ?? ''}'
                  .trim(),
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '@${_currentUser.person?.email ?? (widget.isEnglish ? 'no_username' : 'ไม่มีชื่อผู้ใช้')}',
              style: const TextStyle(fontSize: 16.0, color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _navigateToEditProfile,
              icon: const Icon(Icons.edit, color: Colors.red),
              label: Text(
                widget.isEnglish ? 'Edit Profile' : 'แก้ไขโปรไฟล์',
                style: const TextStyle(color: Colors.red),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish ? 'Personal Information' : 'ข้อมูลส่วนตัว',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  _buildInfoRow(
                    Icons.person_outline,
                    widget.isEnglish ? 'Full Name' : 'ชื่อ-นามสกุล',
                    '${_currentUser.person?.firstName ?? ''} ${_currentUser.person?.lastName ?? ''}'
                        .trim(),
                  ),
                  const SizedBox(height: 8.0),
                  _buildInfoRow(
                    Icons.email_outlined,
                    widget.isEnglish ? 'Email' : 'อีเมล',
                    _currentUser.person?.email ?? 'N/A',
                  ),
                  const SizedBox(height: 8.0),
                  _buildInfoRow(
                    Icons.phone_outlined,
                    widget.isEnglish ? 'Phone' : 'เบอร์โทรศัพท์',
                    _currentUser.person?.phoneNumber ?? 'N/A',
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.red),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isEnglish ? 'Address' : 'ที่อยู่',
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              displayedAddress,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            if (showReadMore)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showFullAddress = !_showFullAddress;
                                  });
                                },
                                child: Text(
                                  readMoreButtonText,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEnglish ? 'Social Media' : 'โซเชียลมีเดีย',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  _buildSocialMediaRow(
                    'Facebook',
                    'facebook.com/johndoe',
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/800px-2021_Facebook_icon.svg.png',
                    widget.isEnglish,
                  ),
                  const SizedBox(height: 8.0),
                  _buildSocialMediaRow(
                    'Line',
                    '@johndoe',
                    'https://upload.wikimedia.org/wikipedia/commons/2/2e/LINE_New_App_Icon_%282020-12%29.png',
                    widget.isEnglish,
                    backgroundColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            // The ElevatedButton Logout button is still here
            ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                widget.isEnglish ? 'Logout' : 'ออกจากระบบ',
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
      
      );
    
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.red),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialMediaRow(
      String platform,
      String handle,
      String iconUrl,
      bool isEnglish, {
        Color? backgroundColor,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.network(
              iconUrl,
              width: 30.0,
              height: 30.0,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return Container(
                  width: 30.0,
                  height: 30.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  handle,
                  style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16.0),
          const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}
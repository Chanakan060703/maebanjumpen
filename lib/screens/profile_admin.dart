import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/screens/editprofile_admin.dart';
import 'package:maebanjumpen/screens/login.dart';

class ProfileAdminPage extends StatefulWidget {
  final Admin user;
  final bool isEnglish;

  const ProfileAdminPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _ProfileAdminPageState createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  bool _showFullAddress = false;
  final int _maxAddressLength = 30;

  late Admin _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  // Function to navigate to Admin edit profile page
  void _navigateToEditProfile() async {
    final Admin? updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileAdminPage(
          user: _currentUser,
          isEnglish: widget.isEnglish,
        ),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser; // Update user data if edited
      });
    }
  }

  // Function to handle logout - this will be called from HomeAdminPage now
  // Keep this function here if you want ProfileAdminPage to manage logout logic internally
  // But the button will be in HomeAdminPage.
  // Or you can pass a logout callback from HomeAdminPage to here.
  // For simplicity, we'll assume HomeAdminPage handles the direct logout action via its AppBar button.
  // If you still want a logout button directly on the profile page, you can add it at the bottom.
  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(), // Go back to Login page
      ),
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }


  // Helper function to create ImageProvider for profile picture
  ImageProvider _buildImageProvider(String? url) {
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https')) {
          return NetworkImage(url);
        } else {
          debugPrint('DEBUG(ProfileAdmin): Invalid URL scheme or not absolute for NetworkImage: $url');
        }
      } catch (e) {
        debugPrint('DEBUG(ProfileAdmin): Error parsing URL for NetworkImage: $url, Exception: $e');
      }
    }
    debugPrint('DEBUG(ProfileAdmin): Falling back to AssetImage because URL is invalid or empty/unparsable.');
    return const AssetImage('assets/images/default_profile.png');
  }

  @override
  Widget build(BuildContext context) {
    String displayedAddress = _currentUser.person?.address ?? 'N/A';
    bool showReadMore = false;
    String readMoreButtonText = widget.isEnglish ? 'Read More' : 'ดูเพิ่มเติม';

    // Logic for displaying truncated or full address
    if (!_showFullAddress && (displayedAddress.length > _maxAddressLength)) {
      displayedAddress = '${displayedAddress.substring(0, _maxAddressLength)}...';
      showReadMore = true;
      readMoreButtonText = widget.isEnglish ? 'Read More' : 'ดูเพิ่มเติม';
    } else if (_showFullAddress && (_currentUser.person?.address?.length ?? 0) > _maxAddressLength) {
      displayedAddress = _currentUser.person?.address ?? 'N/A';
      showReadMore = true;
      readMoreButtonText = widget.isEnglish ? 'Show Less' : 'ดูน้อยลง';
    } else {
      showReadMore = false;
    }

    return SingleChildScrollView( // Changed Scaffold to SingleChildScrollView
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60.0,
                backgroundImage: _buildImageProvider(_currentUser.person?.pictureUrl),
                backgroundColor: Colors.grey.shade300,
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('DEBUG(ProfileAdmin): onBackgroundImageError: Error loading profile image: $exception');
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            '${_currentUser.person?.firstName ?? ''} ${_currentUser.person?.lastName ?? ''}'.trim(),
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _currentUser.person?.email ?? (widget.isEnglish ? 'no_email' : 'ไม่มีอีเมล'),
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
                  '${_currentUser.person?.firstName ?? ''} ${_currentUser.person?.lastName ?? ''}'.trim(),
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
                _buildInfoRow(
                  Icons.credit_card,
                  widget.isEnglish ? 'ID Card Number' : 'เลขบัตรประชาชน',
                  _currentUser.person?.idCardNumber ?? 'N/A',
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
                const SizedBox(height: 8.0),
                _buildInfoRow(
                  Icons.verified_user,
                  widget.isEnglish ? 'Admin Status' : 'สถานะผู้ดูแล',
                  _currentUser.adminStatus ?? (widget.isEnglish ? 'Unknown' : 'ไม่ทราบ'),
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
                  widget.isEnglish ? 'Contact Information' : 'ข้อมูลติดต่อ',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildInfoRow(
                  Icons.business,
                  widget.isEnglish ? 'Department' : 'แผนก',
                  widget.isEnglish ? 'Administration' : 'ฝ่ายบริหาร',
                ),
                const SizedBox(height: 8.0),
                _buildInfoRow(
                  Icons.work,
                  widget.isEnglish ? 'Role' : 'บทบาท',
                  widget.isEnglish ? 'System Administrator' : 'ผู้ดูแลระบบ',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          // Moved the Logout button to the AppBar of HomeAdminPage.
          // If you still want a logout button here (e.g., at the bottom of the profile page)
          // you can uncomment the following block:
          ElevatedButton(
            onPressed: _handleLogout, // This logout function is still available here
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontSize: 16.0)),
            ],
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/account_manager.dart';
import 'package:maebanjumpen/screens/editprofile_accountmanager.dart'; 
import 'package:maebanjumpen/screens/home_accountmanager.dart';
import 'package:maebanjumpen/screens/list_withdraw_accountmanager.dart';
import 'package:maebanjumpen/screens/login.dart';

class ProfileAccountManagerPage extends StatefulWidget {
  final AccountManager user; 
  final bool isEnglish;

  const ProfileAccountManagerPage({
    super.key,
    required this.user,
    required this.isEnglish,
  });

  @override
  _ProfileAccountManagerPageState createState() => _ProfileAccountManagerPageState();
}

class _ProfileAccountManagerPageState extends State<ProfileAccountManagerPage> {
  late AccountManager _currentUser; 
  int _selectedIndex = 3; 

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  // Method to build the image provider for the profile picture
  ImageProvider _buildImageProvider(String? url) {
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    } else {
      return const AssetImage('assets/images/default_profile.png');
    }
  }

  void _navigateToEditProfile() async {
    print('Navigate to Edit Profile for Account Manager');
    final AccountManager? updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileAccountManagerPage( 
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
      // Home
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => AccountManagerPage(
                    user: widget.user, isEnglish: widget.isEnglish)));
        break;
      case 1:
        print('Navigating to History for Account Manager');
        break;
      case 2:
        print('Navigating to Withdrawal for Account Manager');
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ListWithdrawalRequestsScreen(
                    user: widget.user, isEnglish: widget.isEnglish)));
        break;
      case 3:
      // Profile (Current Page)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AccountManagerPage(
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
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
                  backgroundImage: _buildImageProvider(
                      _currentUser.person?.pictureUrl),
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
              _currentUser.person?.email ?? (widget.isEnglish ? 'no_email' : 'ไม่มีอีเมล'), // Changed from username to email as is typical
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
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    widget.isEnglish ? 'Address' : 'ที่อยู่',
                    _currentUser.person?.address ?? 'N/A',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                widget.isEnglish ? 'Logout' : 'ออกจากระบบ',
                style:
                    const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
}
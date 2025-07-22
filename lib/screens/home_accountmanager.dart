import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/account_manager.dart';
import 'package:maebanjumpen/screens/approvewithdrawhistory_accountmanager.dart';
import 'package:maebanjumpen/screens/list_withdraw_accountmanager.dart';
import 'package:maebanjumpen/screens/profile_accountmanager.dart'; // Import the new ProfileAccountManagerPage

class AccountManagerPage extends StatefulWidget {
  final AccountManager user;
  final bool isEnglish;

  const AccountManagerPage({
    super.key,
    required this.user,
    this.isEnglish = true,
  });

  @override
  State<AccountManagerPage> createState() => _AccountManagerPageState();
}

class _AccountManagerPageState extends State<AccountManagerPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildHomePageContent(), // Content for the Home page
      HistoryPageAccountManager(user: widget.user, isEnglish: widget.isEnglish), // History Page
      ListWithdrawalRequestsScreen(user: widget.user, isEnglish: widget.isEnglish), // Withdrawal Page
      ProfileAccountManagerPage(user: widget.user, isEnglish: widget.isEnglish), // Profile Page
    ];
  }

  ImageProvider _buildImageProvider(String? url) {
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    } else {
      return const AssetImage('assets/images/default_profile.png');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // This method builds the content specific to the Home page
  Widget _buildHomePageContent() {
    final String firstName = widget.user.person?.firstName ?? 'Account';
    final String lastName = widget.user.person?.lastName ?? 'Manager';
    final String fullName = '$firstName $lastName';
    final String? profilePictureUrl = widget.user.person?.pictureUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _buildImageProvider(profilePictureUrl),
                  backgroundColor: Colors.grey.shade300,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading image for Account Manager: $exception');
                  },
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Accept Withdraw Card
            GestureDetector(
              onTap: () {
                print('Accept Withdraw button pressed! Navigating to withdrawal requests.');
                // When navigating from a "home" section to another full screen page
                // you would use Navigator.push. If it's another tab, you'd just change _selectedIndex.
                // Here, we change the selected index to the withdrawal tab (index 2)
                _onItemTapped(2); // Directly switch to the withdrawal tab
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.red, size: 40),
                      SizedBox(height: 10),
                      Text(
                        widget.isEnglish ? 'Accept Withdraw' : 'อนุมัติการถอนเงิน',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: widget.isEnglish ? 'Home' : 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: widget.isEnglish ? 'History' : 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: widget.isEnglish ? 'Withdrawal' : 'ถอนเงิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: widget.isEnglish ? 'Profile' : 'โปรไฟล์',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
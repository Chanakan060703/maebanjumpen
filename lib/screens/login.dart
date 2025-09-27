import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:maebanjumpen/boxs/MemberProvider%20.dart';
import 'package:maebanjumpen/controller/loginController.dart';
import 'package:maebanjumpen/model/account_manager.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/penalty.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maebanjumpen/screens/home_accountmanager.dart';
import 'package:maebanjumpen/screens/home_admin.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/home_housekeeper.dart';
import 'package:maebanjumpen/screens/register.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/widgets/login_form.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool isEnglish = true;

  // เพิ่ม GlobalKey สำหรับ Form widget เพื่อใช้ในการตรวจสอบ
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LoginController _loginController = LoginController();

  @override
  void initState() {
    super.initState();
    _loadRememberMeCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('username') ?? '';
      }
    });
  }

  Future<void> _saveRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('username', _usernameController.text);
    } else {
      await prefs.setBool('rememberMe', false);
      await prefs.remove('username');
    }
  }

  void _showErrorDialog({String? title, String? desc}) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      customHeader: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        radius: 40,
        child: const Icon(Icons.close_rounded, color: Colors.red, size: 40),
      ),
      title: title ?? (isEnglish ? 'Oops!' : 'เกิดข้อผิดพลาด'),
      desc:
          desc ??
          (isEnglish
              ? 'Please enter both email and password.'
              : 'กรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน'),
      btnOkText: isEnglish ? 'OK' : 'ตกลง',
      btnOkOnPress: () {},
      btnOkColor: Colors.redAccent,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      descTextStyle: const TextStyle(fontSize: 16),
      buttonsTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ).show();
  }

  Future<void> _handleLogin() async {
    // เพิ่มการตรวจสอบความถูกต้องของฟอร์ม
    if (!_formKey.currentState!.validate()) {
      return; // ถ้าฟอร์มไม่ถูกต้อง ให้หยุดการทำงาน
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final partyRole = await _loginController.authenticate(username, password);

      if (!mounted) return;

      if (partyRole == null) {
        _showErrorDialog(
          title: isEnglish ? 'Login Failed' : 'เข้าสู่ระบบล้มเหลว',
          desc:
              isEnglish
                  ? 'Invalid username or password.'
                  : 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
        );
        return;
      }

      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );
      memberProvider.setUser(partyRole);

      await _saveRememberMeCredentials();

      // 💡 ปรับปรุง: ใช้ toLowerCase() เพื่อจัดการกับ "Active" และ "active"
      final accountStatus = partyRole.person?.accountStatus?.toLowerCase();

      if (partyRole is Member && accountStatus != 'active') {
        final penaltyType =
            partyRole.person?.accountStatus; // ⬅️ ใช้ค่าเดิมสำหรับแสดงผล
        String penaltyMessage = '';

        if (partyRole.person?.personId != null) {
          final Penalty? penalty = await _loginController.getPenaltyByPersonId(
            partyRole.person!.personId!,
          );

          if (!mounted) return;

          if (penalty != null && penalty.penaltyDate != null) {
            final dateFormat = DateFormat(
              'd MMMM y',
              isEnglish ? 'en_US' : 'th_TH',
            );
            final formattedDate = dateFormat.format(penalty.penaltyDate!);

            penaltyMessage =
                isEnglish
                    ? 'Your account is currently $penaltyType until $formattedDate.'
                    : 'บัญชีของคุณถูก $penaltyType ถึงวันที่ $formattedDate';
          } else {
            penaltyMessage =
                isEnglish
                    ? 'Your account is currently $penaltyType.'
                    : 'บัญชีของคุณถูก $penaltyType ';
          }
        } else {
          penaltyMessage =
              isEnglish
                  ? 'Your account is currently $penaltyType.'
                  : 'บัญชีของคุณถูก $penaltyType ';
        }

        _showErrorDialog(
          title: isEnglish ? 'Account Restricted' : 'บัญชีถูกจำกัดการเข้าถึง',
          desc: penaltyMessage,
        );
        return;
      }

      if (!mounted) return;

      if (partyRole is Housekeeper) {
        // 💡 ปรับปรุง: ใช้ Null-aware access และ toLowerCase() เพื่อความปลอดภัย
        final statusVerify =
            partyRole.statusVerify
                ?.toUpperCase(); // ใช้ toUpperCase() เพื่อเทียบกับ Enum ที่มักจะเป็นตัวใหญ่

        // 1. เงื่อนไขที่ถูกต้อง: อนุญาตให้เข้าสู่ระบบได้ ถ้าสถานะเป็น APPROVED หรือ VERIFIED
        if (statusVerify == 'APPROVED' || statusVerify == 'VERIFIED') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      HousekeeperPage(user: partyRole, isEnglish: isEnglish),
            ),
          );
        }
        // 2. เงื่อนไขที่ถูกต้อง: บัญชีกำลังรอ/ถูกปฏิเสธ (ไม่ให้เข้าสู่ระบบ)
        else if (statusVerify == 'PENDING' || statusVerify == 'REJECTED') {
          // ... (แสดง Dialog บัญชีกำลังตรวจสอบ/ถูกปฏิเสธ)
          _showErrorDialog(
            title: isEnglish ? 'Account Under Review' : 'บัญชีกำลังตรวจสอบ',
            desc:
                isEnglish
                    ? 'Your account status is $statusVerify. Please wait for verification.'
                    : 'บัญชีของคุณสถานะเป็น $statusVerify โปรดรอการยืนยัน',
          );
          return;
        } else {
          // ... (สถานะอื่นๆ หรือเป็น null)
          _showErrorDialog(
            title: isEnglish ? 'Verification Required' : 'ต้องมีการยืนยัน',
            desc:
                isEnglish
                    ? 'Your housekeeper account needs verification.'
                    : 'บัญชีแม่บ้านของคุณต้องได้รับการยืนยันก่อน',
          );
          return;
        }
      } else if (partyRole is Hirer) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomePage(user: partyRole, isEnglish: isEnglish),
          ),
        );
      } else if (partyRole is Admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomeAdminPage(
                  user:
                      partyRole, // 💡 ไม่จำเป็นต้อง as Admin เพราะมีการตรวจสอบ type แล้ว
                  isEnglish: isEnglish,
                ),
          ),
        );
      } else if (partyRole is AccountManager) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => AccountManagerPage(
                  user:
                      partyRole, // 💡 ไม่จำเป็นต้อง as AccountManager เพราะมีการตรวจสอบ type แล้ว
                  isEnglish: isEnglish,
                ),
          ),
        );
      } else {
        _showErrorDialog(
          title: isEnglish ? 'Unknown User Type' : 'ประเภทผู้ใช้ไม่รู้จัก',
          desc:
              isEnglish
                  ? 'Could not determine user role. Please try again.'
                  : 'ไม่สามารถระบุบทบาทผู้ใช้ได้ กรุณาลองใหม่',
        );
      }
    } catch (e) {
      print("Error during login: $e");
      if (mounted) {
        // ตรวจสอบข้อผิดพลาดที่มาจากเซิร์ฟเวอร์ (เช่น Invalid username/password)
        if (e.toString().contains('401')) {
          _showErrorDialog(
            title: isEnglish ? 'Login Failed' : 'เข้าสู่ระบบล้มเหลว',
            desc:
                isEnglish
                    ? 'Invalid username or password.'
                    : 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
          );
        } else {
          // สำหรับข้อผิดพลาดอื่น ๆ ที่ไม่เกี่ยวข้องกับการล็อกอิน
          _showErrorDialog(
            title: isEnglish ? 'Login Error' : 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ',
            desc:
                isEnglish
                    ? 'An unexpected error occurred. Please try again.'
                    : 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey, // <-- กำหนด key ให้กับ Form
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ToggleButtons(
                          isSelected: [isEnglish, !isEnglish],
                          onPressed: (index) {
                            setState(() {
                              isEnglish = index == 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          selectedColor: Colors.white,
                          fillColor: Colors.red,
                          color: Colors.black,
                          borderColor: Colors.transparent,
                          selectedBorderColor: Colors.transparent,
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text("ENG"),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text("ไทย"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Image.asset('assets/images/logo.png', height: 100),
                    const SizedBox(height: 20),
                    Text(
                      isEnglish ? "Maeban Jampen" : "แม่บ้านจำเป็น",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(isEnglish ? "Welcome" : "ยินดีต้อนรับ"),
                    const SizedBox(height: 30),
                    LoginFormFields(
                      isEnglish: isEnglish,
                      obscurePassword: _obscurePassword,
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: const Color(0xFFEB2525),
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                        ),
                        Text(isEnglish ? "Remember me" : "จดจำฉันไว้"),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            isEnglish ? "Forgot Password?" : "ลืมรหัสผ่าน?",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEnglish ? "Login" : "เข้าสู่ระบบ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isEnglish
                              ? "Don't have an account? "
                              : "ยังไม่มีบัญชี? ",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            isEnglish ? "Register" : "ลงทะเบียน",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

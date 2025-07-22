import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:maebanjumpen/controller/loginController.dart';
import 'package:maebanjumpen/model/account_manager.dart';
import 'package:maebanjumpen/model/admin.dart';
import 'package:maebanjumpen/model/hirer.dart';import 'package:maebanjumpen/model/housekeeper.dart';
import 'package:maebanjumpen/model/member.dart'; // สำคัญ: ต้องนำเข้า Member model
import 'package:maebanjumpen/model/penalty.dart'; // สำคัญ: ต้องนำเข้า Penalty model
import 'package:shared_preferences/shared_preferences.dart'; // สำหรับบันทึกข้อมูล
// เพิ่ม: นำเข้า Report model
import 'package:maebanjumpen/screens/home_accountmanager.dart';
import 'package:maebanjumpen/screens/home_admin.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/home_housekeeper.dart';
import 'package:maebanjumpen/screens/register.dart';
import 'package:intl/intl.dart';
import 'package:maebanjumpen/widgets/login_form.dart'; // เพิ่มสำหรับ format วันที่


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool isEnglish = true;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberMeCredentials(); // โหลดข้อมูลเมื่อเริ่มต้น
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // โหลดชื่อผู้ใช้และรหัสผ่านที่บันทึกไว้
  Future<void> _loadRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('username') ?? '';
        // ไม่โหลดรหัสผ่านอัตโนมัติเพื่อความปลอดภัย
        // _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  // บันทึกหรือลบชื่อผู้ใช้และรหัสผ่านตามสถานะ "Remember Me"
  Future<void> _saveRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('username', _usernameController.text);
      // ไม่บันทึกรหัสผ่านเพื่อความปลอดภัย
      // await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.setBool('rememberMe', false);
      await prefs.remove('username');
      // ลบเฉพาะ username หากไม่เลือก remember me
      // await prefs.remove('password'); // ไม่ต้องลบ password เพราะไม่ได้บันทึก
    }
  }

  // ปรับปรุงฟังก์ชันแสดง AwesomeDialog ให้ยืดหยุ่นขึ้น
  void _showErrorDialog({String? title, String? desc}) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader, // หรือ DialogType.error ถ้าต้องการไอคอน Error
      animType: AnimType.bottomSlide,
      customHeader: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        radius: 40,
        child: const Icon(Icons.close_rounded, color: Colors.red, size: 40),
      ),
      title: title ?? (isEnglish ? 'Oops!' : 'เกิดข้อผิดพลาด'),
      desc: desc ?? (isEnglish ? 'Please enter both email and password.' : 'กรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน'),
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

  final LoginController _loginController = LoginController();

  // 🔑 Handle Login
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog(
        title: isEnglish ? 'Missing Information' : 'ข้อมูลไม่ครบถ้วน',
        desc: isEnglish ? 'Please enter both username and password.' : 'กรุณากรอกชื่อผู้ใช้และรหัสผ่านให้ครบถ้วน',
      );
      return;
    }

    try {
      final partyRole = await _loginController.authenticate(username, password);

      if (partyRole == null) {
        _showErrorDialog(
          title: isEnglish ? 'Login Failed' : 'เข้าสู่ระบบล้มเหลว',
          desc: isEnglish ? 'Invalid username or password.' : 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
        );
        return; // ออกจากฟังก์ชันหลังจากแสดงข้อผิดพลาด
      }

      // บันทึกสถานะ "Remember Me" หลังจาก Login สำเร็จ
      await _saveRememberMeCredentials();

      // --- ตรวจสอบสถานะบัญชี (accountStatus) สำหรับ Member ทุกประเภท ---
      // ถ้า accountStatus ไม่ใช่ 'active' ให้แสดงข้อความแจ้งการจำกัดบัญชี
      if (partyRole is Member && partyRole.person?.accountStatus != 'active') {
        final penaltyType = partyRole.person?.accountStatus;
        String penaltyMessage = '';

        if (partyRole.person?.personId != null) {
          final Penalty? penalty = await _loginController.getPenaltyByPersonId(partyRole.person!.personId!);

          if (penalty != null && penalty.penaltyDate != null) {
            final dateFormat = DateFormat('d MMMM y', isEnglish ? 'en_US' : 'th_TH');
            final formattedDate = dateFormat.format(penalty.penaltyDate!);

            penaltyMessage = isEnglish
                ? 'Your account is currently $penaltyType until $formattedDate. Please contact support for more information.'
                : 'บัญชีของคุณถูก $penaltyType ถึงวันที่ $formattedDate โปรดติดต่อฝ่ายสนับสนุนสำหรับข้อมูลเพิ่มเติม';
          } else {
            penaltyMessage = isEnglish
                ? 'Your account is currently $penaltyType. Please contact support for more information.'
                : 'บัญชีของคุณถูก $penaltyType โปรดติดต่อฝ่ายสนับสนุนสำหรับข้อมูลเพิ่มเติม';
          }
        } else {
          penaltyMessage = isEnglish
              ? 'Your account is currently $penaltyType. Please contact support for more information.'
              : 'บัญชีของคุณถูก $penaltyType โปรดติดต่อฝ่ายสนับสนุนสำหรับข้อมูลเพิ่มเติม';
        }

        _showErrorDialog(
          title: isEnglish ? 'Account Restricted' : 'บัญชีถูกจำกัดการเข้าถึง',
          desc: penaltyMessage,
        );
        return; // ป้องกันการล็อกอินหากบัญชีถูกจำกัด
      }

      // --- ตรวจสอบสถานะการยืนยัน (statusVerify) เฉพาะสำหรับ Housekeeper ---
      if (partyRole is Housekeeper) {
        if (partyRole.statusVerify == 'verified') {
          // ถ้าเป็น Housekeeper และได้รับการยืนยันแล้ว ให้อนุญาตให้เข้าสู่ระบบ
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HousekeeperPage(user: partyRole, isEnglish: isEnglish),
            ),
          );
        } else if (partyRole.statusVerify == 'not verified') {
          // ถ้าเป็น Housekeeper แต่ยังไม่ได้รับการยืนยัน ให้แสดงข้อความแจ้ง
          _showErrorDialog(
            title: isEnglish ? 'Account Under Review' : 'บัญชีกำลังตรวจสอบ',
            desc: isEnglish ? 'Your account is currently under review. Please wait for verification.' : 'บัญชีของคุณกำลังตรวจสอบ โปรดรอการยืนยัน',
          );
          return; // หยุดการเข้าสู่ระบบ
        } else {
          // กรณีอื่นๆ ของ statusVerify สำหรับ Housekeeper (เช่น null หรือค่าอื่นๆ ที่ไม่รู้จัก)
          _showErrorDialog(
            title: isEnglish ? 'Verification Required' : 'ต้องมีการยืนยัน',
            desc: isEnglish ? 'Your housekeeper account needs verification. Please contact support.' : 'บัญชีแม่บ้านของคุณต้องได้รับการยืนยัน โปรดติดต่อฝ่ายสนับสนุน',
          );
          return; // หยุดการเข้าสู่ระบบ
        }
      }
      // --- สิ้นสุดการตรวจสอบ statusVerify สำหรับ Housekeeper ---
      
      // --- ส่วนการนำทางผู้ใช้ไปยังหน้าหลักสำหรับประเภทอื่นๆ (ถ้า accountStatus เป็น 'active') ---
      else if (partyRole is Hirer) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(user: partyRole, isEnglish: isEnglish),
          ),
        );
      } else if (partyRole is Admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeAdminPage(user: partyRole, isEnglish: isEnglish),
          ),
        );
      } else if (partyRole is AccountManager) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AccountManagerPage(user: partyRole, isEnglish: isEnglish),
          ),
        );
      } else {
        // กรณีที่ไม่รู้จักประเภทผู้ใช้ (ไม่ควรเกิดขึ้นหาก Backend ทำงานถูกต้อง)
        _showErrorDialog(
          title: isEnglish ? 'Unknown User Type' : 'ประเภทผู้ใช้ไม่รู้จัก',
          desc: isEnglish ? 'Could not determine user role. Please try again.' : 'ไม่สามารถระบุบทบาทผู้ใช้ได้ กรุณาลองใหม่',
        );
      }
    } catch (e) {
      print("Error during login: $e"); // แสดงข้อผิดพลาดในคอนโซลเพื่อการดีบัก
      _showErrorDialog(
        title: isEnglish ? 'Login Error' : 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ',
        desc: isEnglish
            ? 'An unexpected error occurred. Please try again. Error: ${e.toString()}'
            : 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่ ข้อผิดพลาด: ${e.toString()}',
      );
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
              child: Column(
                children: [
                  // 🔤 Language Switch
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

                  // 🖼 Logo
                  Image.asset('assets/images/logo.png', height: 100),
                  const SizedBox(height: 20),

                  // 🏷 Title
                  const Text(
                    "Maebaan Jampen",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(isEnglish ? "Welcome Back" : "ยินดีต้อนรับกลับ"),
                  const SizedBox(height: 30),

                  // 📋 Login Form
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

                  // ✅ Remember me
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

                  // 🔓 Login Button
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

                  // 📝 Register
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
    );
  }
}

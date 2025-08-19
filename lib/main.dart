import 'package:flutter/material.dart';
import 'package:maebanjumpen/boxs/MemberProvider%20.dart';
import 'package:maebanjumpen/boxs/notification_service.dart';
import 'package:maebanjumpen/screens/login.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:maebanjumpen/controller/notification_manager.dart';
import 'package:maebanjumpen/screens/home_member.dart';
import 'package:maebanjumpen/screens/home_housekeeper.dart'; // ต้อง import หน้า Home ของแม่บ้าน
import 'package:maebanjumpen/screens/home_admin.dart'; // ต้อง import หน้า Home ของ Admin
import 'package:maebanjumpen/screens/home_accountmanager.dart'; // ต้อง import หน้า Home ของ AccountManager
import 'package:maebanjumpen/model/hirer.dart';
import 'package:maebanjumpen/model/housekeeper.dart'; // Import Housekeeper model
import 'package:maebanjumpen/model/admin.dart'; // Import Admin model
import 'package:maebanjumpen/model/account_manager.dart'; // Import AccountManager model


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  await initializeDateFormatting('en', null);
  tz.initializeTimeZones();
  await NotificationService.initializeNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MemberProvider()),
        ChangeNotifierProvider(create: (context) => NotificationManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('th', ''),
      ],
      home: Consumer<MemberProvider>(
        builder: (context, memberProvider, child) {
          final currentUser = memberProvider.currentUser;

          if (currentUser == null) {
            // ถ้ายังไม่มีผู้ใช้ล็อกอิน ให้แสดงหน้า Login
            return HomePage(isEnglish: true);
          } else {
            // ตรวจสอบประเภทของผู้ใช้และนำทางไปยังหน้าจอที่ถูกต้อง
            if (currentUser is Hirer) {
              return HomePage(user: currentUser, isEnglish: true);
            } else if (currentUser is Housekeeper) {
              return HousekeeperPage(user: currentUser, isEnglish: true);
            } else if (currentUser is Admin) {
              return HomeAdminPage(user: currentUser as Admin, isEnglish: true);
            } else if (currentUser is AccountManager) {
              return AccountManagerPage(user: currentUser as AccountManager, isEnglish: true);
            } else {
              // กรณีที่ไม่รู้จักประเภทผู้ใช้ (ควรเป็นไปไม่ได้)
              return const LoginPage();
            }
          }
        },
      ),
    );
  }
}
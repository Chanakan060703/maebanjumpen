import 'package:flutter/material.dart';
import 'package:maebanjumpen/boxs/notification_service.dart';
import 'package:maebanjumpen/screens/login.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maebanjumpen/boxs/MemberProvider .dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:maebanjumpen/controller/notification_manager.dart'; // เพิ่ม import นี้

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  await initializeDateFormatting('en', null);

  tz.initializeTimeZones();

  await NotificationService.initializeNotifications();

  runApp(
    // *** แก้ไขตรงนี้: เพิ่ม MultiProvider เพื่อรวม MemberProvider และ NotificationManager ***
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MemberProvider()),
        ChangeNotifierProvider(create: (context) => NotificationManager()), // เพิ่ม NotificationManager
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''),
        Locale('th', ''),
      ],
      home: LoginPage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'controllers/auth_provider.dart';
import 'controllers/attendance_provider.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS)) {
      await Firebase.initializeApp();
      await FCMService.initialize();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing Firebase: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: const StaffTrackApp(),
    ),
  );
}

class StaffTrackApp extends StatelessWidget {
  const StaffTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        return MaterialApp(
          title: 'Staff Track',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

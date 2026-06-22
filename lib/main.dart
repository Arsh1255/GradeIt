import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/academic_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system overlay styling for dark mode compatibility
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const GradeItApp());
}

class GradeItApp extends StatelessWidget {
  const GradeItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AcademicProvider()),
      ],
      child: Consumer<AcademicProvider>(
        builder: (context, provider, child) {
          AppTheme.isDark = provider.isDarkMode;
          
          // Dynamically adjust status/nav overlay bars
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: provider.isDarkMode ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: AppTheme.bgColor,
              systemNavigationBarIconBrightness: provider.isDarkMode ? Brightness.light : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'Grade It',
            debugShowCheckedModeBanner: false,
            theme: provider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: provider.isLoading
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : provider.hasConfiguredSemester
                    ? const DashboardScreen()
                    : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}


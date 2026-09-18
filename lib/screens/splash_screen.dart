import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'student_login_screen.dart';
import 'student_dashboard_screen.dart';
import '../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.isLoggedIn 
                ? const StudentDashboardScreen() 
                : const StudentLoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'logo.png', // Or AssetImage if moved to assets. Wait, logo is in root.
                      width: 150.w,
                      height: 150.w,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.school, size: 100.sp, color: AppColors.primary);
                      },
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    SizedBox(height: 24.h),
                    Text(
                      'Attendance App',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Text(
                'Developed By Umang Markana',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fade(delay: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}

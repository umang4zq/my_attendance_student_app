import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../models/stream_model.dart';
import '../theme/app_colors.dart';
import 'student_dashboard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _rollNoController = TextEditingController();

  List<StreamModel> _streams = [];
  String? _selectedStream;
  bool _isLoadingStreams = true;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoadingStreams = true);
    final streams = await _firestoreService.getStreams();
    if (mounted) {
      setState(() {
        _streams = streams;
        if (streams.isNotEmpty) {
          _selectedStream = streams.first.id;
        }
        _isLoadingStreams = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a stream')));
      return;
    }

    setState(() => _isLoggingIn = true);
    
    final student = await _firestoreService.findStudentByRollNo(_selectedStream!, _rollNoController.text.trim());
    
    if (mounted) {
      if (student == null) {
        setState(() => _isLoggingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student not found. Check Roll Number and Stream.'), backgroundColor: AppColors.deleteRed),
        );
      } else {
        // Save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isStudentLoggedIn', true);
        await prefs.setString('studentId', student.docId);
        await prefs.setString('streamId', student.streamId);
        await prefs.setString('studentName', student.name);
        await prefs.setString('studentRollNo', student.rollno);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentDashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.school, size: 80.sp, color: AppColors.primary)
                      .animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  SizedBox(height: 24.h),
                  Text(
                    'Student Portal',
                    style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                  SizedBox(height: 8.h),
                  Text(
                    'Log in to view your attendance',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                  SizedBox(height: 40.h),
                  
                  // Stream Selection
                  Text('Select Class', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                      .animate().fade(delay: 300.ms),
                  SizedBox(height: 8.h),
                  _isLoadingStreams
                      ? const Center(child: CircularProgressIndicator())
                      : _streams.isEmpty
                          ? Center(
                              child: Text(
                                'No classes available.\nCheck database or Firestore rules.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red, fontSize: 14.sp),
                              ),
                            )
                          : Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedStream,
                              items: _streams.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                              onChanged: (val) => setState(() => _selectedStream = val),
                            ),
                          ),
                        ).animate().fade(delay: 350.ms),
                  
                  SizedBox(height: 24.h),
                  
                  // Roll No
                  Text('Roll Number', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                      .animate().fade(delay: 400.ms),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _rollNoController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.numbers),
                      hintText: 'Enter your roll number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ).animate().fade(delay: 450.ms),
                  
                  SizedBox(height: 40.h),
                  
                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: _isLoggingIn
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Login', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  ).animate().fade(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

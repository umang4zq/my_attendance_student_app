import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/firestore_service.dart';
import '../models/date_model.dart';
import '../theme/app_colors.dart';
import '../widgets/gauge_chart.dart';
import 'student_login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _studentId = '';
  String _streamId = '';
  String _studentName = '';
  String _studentRollNo = '';

  late DateTime _selectedMonth;
  bool _isLoading = true;

  int _presentCount = 0;
  int _absentCount = 0;
  int _holidayCount = 0;
  double _percentage = 0.0;
  List<DateModel> _calendarDays = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString('studentId') ?? '';
    _streamId = prefs.getString('streamId') ?? '';
    _studentName = prefs.getString('studentName') ?? '';
    _studentRollNo = prefs.getString('studentRollNo') ?? '';

    if (_studentId.isEmpty) {
      _logout();
      return;
    }
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);

    final data = await _firestoreService.fetchStudentMonthlyAttendance(
      streamId: _streamId,
      studentId: _studentId,
      yearMonth: monthStr,
    );

    if (mounted) {
      setState(() {
        _presentCount = data['presentCount'] ?? 0;
        _absentCount = data['absentCount'] ?? 0;
        _holidayCount = data['holidayCount'] ?? 0;
        _percentage = data['percentage'] ?? 0.0;
        _calendarDays =
            (data['calendarDays'] as List?)?.cast<DateModel>() ?? [];
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
      _loadMonthData();
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentLoginScreen()),
      );
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final days = <DateTime>[];
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final monthDays = _getDaysInMonth(_selectedMonth);
    final firstDayOffset =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading && _studentId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadMonthData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Card
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30.r,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 36.sp,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _studentName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Class: $_streamId  |  Roll No: $_studentRollNo',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideY(begin: -0.2),

                      SizedBox(height: 24.h),

                      // Month Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 32),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedMonth),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 32),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ).animate().fade(delay: 100.ms),

                      SizedBox(height: 16.h),

                      _isLoading
                          ? SizedBox(
                              height: 300.h,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Column(
                              children: [
                                // Chart & Stats
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child:
                                            AttendanceGaugeChart(
                                              percentage: _percentage,
                                            ).animate().scale(
                                              delay: 200.ms,
                                              curve: Curves.easeOutBack,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      flex: 1,
                                      child:
                                          Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildStatRow(
                                                    'Present',
                                                    _presentCount,
                                                    AppColors.present,
                                                  ),
                                                  SizedBox(height: 8.h),
                                                  _buildStatRow(
                                                    'Absent',
                                                    _absentCount,
                                                    AppColors.absent,
                                                  ),
                                                  SizedBox(height: 8.h),
                                                  _buildStatRow(
                                                    'Holiday',
                                                    _holidayCount,
                                                    AppColors.holiday,
                                                  ),
                                                ],
                                              )
                                              .animate()
                                              .fade(delay: 300.ms)
                                              .slideX(begin: 0.2),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32.h),

                                // Days of week header
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children:
                                        [
                                              'Sun',
                                              'Mon',
                                              'Tue',
                                              'Wed',
                                              'Thu',
                                              'Fri',
                                              'Sat',
                                            ]
                                            .map(
                                              (d) => Expanded(
                                                child: Center(
                                                  child: Text(
                                                    d,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 13.sp,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ).animate().fade(delay: 350.ms),

                                // Calendar Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                  itemCount: monthDays.length + firstDayOffset,
                                  itemBuilder: (context, index) {
                                    if (index < firstDayOffset) {
                                      return const SizedBox.shrink();
                                    }
                                    final day =
                                        monthDays[index - firstDayOffset];
                                    final dm = _calendarDays.firstWhere(
                                      (d) => d.date.day == day.day,
                                      orElse: () => DateModel(
                                        date: day,
                                        isPresent: false,
                                        isAbsent: false,
                                        isHoliday: false,
                                      ),
                                    );

                                    Color bgColor = Colors.grey.shade100;
                                    Color textColor = Colors.black54;

                                    if (day.weekday == DateTime.sunday) {
                                      bgColor = Colors.yellow.withOpacity(0.3);
                                      textColor = Colors.orange.shade800;
                                    } else if (dm.isPresent) {
                                      bgColor = AppColors.present.withOpacity(
                                        0.2,
                                      );
                                      textColor = AppColors.present;
                                    } else if (dm.isAbsent) {
                                      bgColor = AppColors.absent.withOpacity(
                                        0.2,
                                      );
                                      textColor = AppColors.absent;
                                    } else if (dm.isHoliday) {
                                      bgColor = AppColors.holiday.withOpacity(
                                        0.2,
                                      );
                                      textColor = AppColors.holiday;
                                    } else if (day.isAfter(DateTime.now())) {
                                      bgColor = Colors.grey.shade200;
                                      textColor = Colors.grey.shade400;
                                    }

                                    return Container(
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            border:
                                                dm.isPresent ||
                                                    dm.isAbsent ||
                                                    dm.isHoliday ||
                                                    day.weekday ==
                                                        DateTime.sunday
                                                ? Border.all(
                                                    color: textColor
                                                        .withOpacity(0.5),
                                                  )
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fade(
                                          delay: Duration(
                                            milliseconds: 400 + (index * 15),
                                          ),
                                        )
                                        .scale(curve: Curves.easeOutBack);
                                  },
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text('$label: ', style: TextStyle(fontSize: 14.sp)),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

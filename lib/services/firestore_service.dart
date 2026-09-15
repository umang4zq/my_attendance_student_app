import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stream_model.dart';
import '../models/student_model.dart';
import '../models/date_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch available streams for the login dropdown
  Future<List<StreamModel>> getStreams() async {
    try {
      final snap = await _firestore.collection('streams').get();
      return snap.docs.map((d) => StreamModel.fromDoc(d.id, d.data())).toList();
    } catch (e) {
      print('Error fetching streams: $e');
      return [];
    }
  }

  // Authenticate student by Stream and Roll No
  Future<StudentModel?> findStudentByRollNo(String streamId, String rollno) async {
    try {
      final query = await _firestore
          .collection('streams')
          .doc(streamId)
          .collection('students')
          .where('rollno', isEqualTo: rollno)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return StudentModel.fromMap(query.docs.first.data(), query.docs.first.id, streamId: streamId);
    } catch (e) {
      return null;
    }
  }

  // Fetch the specific student's monthly attendance
  Future<Map<String, dynamic>> fetchStudentMonthlyAttendance({
    required String streamId,
    required String studentId,
    required String yearMonth,
  }) async {
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalHoliday = 0;
    List<DateModel> calendarDays = [];

    try {
      final snap = await _firestore
          .collection('streams')
          .doc(streamId)
          .collection('students')
          .doc(studentId)
          .collection('attendance')
          .doc(yearMonth)
          .collection('days')
          .get();

      print('Fetched ${snap.docs.length} attendance records for month: $yearMonth');

      for (var doc in snap.docs) {
        final status = (doc.data()['status'] ?? '').toString().trim().toLowerCase();
        final dayStr = doc.id; // e.g. "2026-09-15" or "15" or "15-09-2026"
        DateTime? dt = DateTime.tryParse(dayStr);
        
        if (dt == null) {
          // Fallback 1: Just a day number (e.g., "1", "15")
          int? dayNum = int.tryParse(dayStr);
          if (dayNum != null) {
            final parts = yearMonth.split('-');
            if (parts.length == 2) {
              dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), dayNum);
            }
          }
          
          // Fallback 2: dd-MM-yyyy format
          if (dt == null && dayStr.split('-').length == 3) {
            final parts = dayStr.split('-');
            if (parts[0].length <= 2 && parts[2].length == 4) {
              dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            }
          }
        }
        
        if (dt == null) {
          print('Could not parse date from doc.id: $dayStr');
          continue;
        }

        bool p = false, a = false, h = false;
        if (status == 'present') {
          p = true;
          totalPresent++;
        } else if (status == 'absent') {
          a = true;
          totalAbsent++;
        } else if (status == 'holiday') {
          h = true;
          totalHoliday++;
        }

        calendarDays.add(DateModel(
          date: dt,
          isPresent: p,
          isAbsent: a,
          isHoliday: h,
        ));
      }

      final workingDays = totalPresent + totalAbsent;
      double pct = 0.0;
      if (workingDays > 0) {
        pct = (totalPresent / workingDays) * 100.0;
      }

      return {
        'presentCount': totalPresent,
        'absentCount': totalAbsent,
        'holidayCount': totalHoliday,
        'percentage': pct,
        'calendarDays': calendarDays,
      };
    } catch (e) {
      return {
        'presentCount': 0,
        'absentCount': 0,
        'holidayCount': 0,
        'percentage': 0.0,
        'calendarDays': <DateModel>[],
      };
    }
  }
}

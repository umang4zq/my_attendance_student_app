class DateModel {
  final DateTime date;
  final bool isPresent;
  final bool isAbsent;
  final bool isHoliday;

  DateModel({
    required this.date,
    this.isPresent = false,
    this.isAbsent = false,
    this.isHoliday = false,
  });
}

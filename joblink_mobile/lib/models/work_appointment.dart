class WorkAppointment {
  const WorkAppointment({
    required this.id,
    required this.appointmentDate,
    required this.location,
    required this.status,
    required this.jobTitle,
    required this.companyName,
    required this.workDays,
    required this.startTime,
    required this.endTime,
    this.instruction,
  });

  final String id;
  final DateTime appointmentDate;
  final String location;
  final String status;
  final String jobTitle;
  final String companyName;
  final List<String> workDays;
  final String? startTime;
  final String? endTime;
  final String? instruction;

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isUpcoming => appointmentDate.isAfter(DateTime.now());

  factory WorkAppointment.fromJson(Map<String, dynamic> json) {
    final application = _mapOf(json['application']);
    final job = _mapOf(application['job']);
    final employer = _mapOf(job['employer']);
    final appointmentDate =
        DateTime.tryParse(json['appointmentDate']?.toString() ?? '');
    if (appointmentDate == null) {
      throw const FormatException('Ngày nhận việc không hợp lệ');
    }

    return WorkAppointment(
      id: json['id']?.toString() ?? '',
      appointmentDate: appointmentDate.toLocal(),
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      jobTitle: job['title']?.toString() ?? 'Công việc',
      companyName: employer['companyName']?.toString() ?? 'Nhà tuyển dụng',
      workDays: (job['workDays'] as List?)
              ?.map((day) => day.toString())
              .toList() ??
          const [],
      startTime: _timeOfDay(job['startTime']),
      endTime: _timeOfDay(job['endTime']),
      instruction: json['instruction']?.toString(),
    );
  }

  static Map<String, dynamic> _mapOf(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  static String? _timeOfDay(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) {
      final utc = parsed.toUtc();
      return '${utc.hour.toString().padLeft(2, '0')}:'
          '${utc.minute.toString().padLeft(2, '0')}';
    }
    final text = value.toString();
    return text.length >= 5 ? text.substring(0, 5) : text;
  }
}

class Job {
  final String id;
  final String title;
  final String? description;

  final double? salary;
  final String? salaryType;

  final String? location;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  final String? shiftType;
  final String? startTime;
  final String? endTime;
  final List<String> workDays;

  final bool urgent;
  final DateTime? urgentUntil;

  final bool cvRequired;
  final DateTime? deadline;
  final String? status;

  final String? employerName;
  final String? employerLogoUrl;
  final String? categoryName;

  final bool employerVerified;
  final int applicationCount;

  final List<String> skills;

  const Job({
    required this.id,
    required this.title,
    this.description,
    this.salary,
    this.salaryType,
    this.location,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.shiftType,
    this.startTime,
    this.endTime,
    this.workDays = const [],
    this.urgent = false,
    this.urgentUntil,
    this.cvRequired = false,
    this.deadline,
    this.status,
    this.employerName,
    this.employerLogoUrl,
    this.categoryName,
    this.employerVerified = false,
    this.applicationCount = 0,
    this.skills = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    // =====================================================
    // EMPLOYER
    // =====================================================

    final employer = json['employer'];

    String? employerName;
    String? employerLogoUrl;

    if (employer is Map) {
      employerName = employer['companyName']?.toString();

      employerLogoUrl = employer['logoUrl']?.toString();
    }

    // =====================================================
    // CATEGORY
    // =====================================================

    final category = json['category'];

    String? categoryName;

    if (category is Map) {
      categoryName = category['name']?.toString();
    }

    // =====================================================
    // SKILLS
    // =====================================================

    final skills = <String>[];

    final jobSkills = json['jobSkills'];

    if (jobSkills is List) {
      for (final item in jobSkills) {
        if (item is! Map) {
          continue;
        }

        final skill = item['skill'];

        if (skill is! Map) {
          continue;
        }

        final name = skill['name']?.toString();

        if (name != null && name.isNotEmpty) {
          skills.add(name);
        }
      }
    }

    // =====================================================
    // WORK DAYS
    // =====================================================

    final workDays = <String>[];

    final rawWorkDays = json['workDays'];

    if (rawWorkDays is List) {
      for (final item in rawWorkDays) {
        final value = item.toString();

        if (value.isNotEmpty) {
          workDays.add(value);
        }
      }
    }

    // =====================================================
    // DATES
    // =====================================================

    final deadline = _parseDateTime(json['deadline']);

    final urgentUntil = _parseDateTime(json['urgentUntil']);

    // =====================================================
    // CREATE MODEL
    // =====================================================

    bool employerVerified = false;

    if (employer is Map) {
      employerVerified =
          employer['verificationStatus']
              ?.toString() ==
              'VERIFIED';
    }

    int applicationCount = 0;

    final rawCount = json['_count'];

    if (rawCount is Map) {
      applicationCount =
          _toInt(
            rawCount['applications'],
          ) ??
              0;
    } else {
      applicationCount =
          _toInt(
            json['applicationCount'],
          ) ??
              0;
    }
    return Job(
      id: json['id']?.toString() ?? '',

      title: json['title']?.toString() ?? 'Công việc',

      description: json['description']?.toString(),

      salary: _toDouble(json['salary']),

      salaryType: json['salaryType']?.toString(),

      location: json['location']?.toString(),

      latitude: _toDouble(json['latitude']),

      longitude: _toDouble(json['longitude']),

      distanceKm: _toDouble(json['distanceKm']),

      shiftType: json['shiftType']?.toString(),

      startTime: _parseClockTime(json['startTime']),

      endTime: _parseClockTime(json['endTime']),

      workDays: workDays,

      urgent: json['urgent'] == true,

      urgentUntil: urgentUntil,

      cvRequired: json['cvRequired'] == true,

      deadline: deadline,

      status: json['status']?.toString(),

      employerName:
          employerName ?? json['companyName']?.toString() ?? 'Nhà tuyển dụng',

      employerVerified:
      employerVerified,

      applicationCount:
      applicationCount,

      employerLogoUrl: employerLogoUrl,

      categoryName: categoryName,

      skills: skills,
    );
  }

  // =====================================================
  // URGENT
  // =====================================================

  bool get isUrgent {
    if (!urgent) {
      return false;
    }

    if (urgentUntil == null) {
      return true;
    }

    return urgentUntil!.isAfter(DateTime.now());
  }

  // =====================================================
  // SALARY
  // =====================================================

  String get salaryText {
    if (salary == null) {
      return 'Thỏa thuận';
    }

    final amount = '${_formatMoney(salary!)}đ';

    switch (salaryType) {
      case 'HOURLY':
        return '$amount/giờ';

      case 'DAILY':
        return '$amount/ngày';

      case 'SHIFT':
        return '$amount/ca';

      case 'MONTHLY':
        return '$amount/tháng';

      case 'FIXED':
        return '$amount/trọn việc';

      default:
        return amount;
    }
  }

  String get salaryTypeText {
    switch (salaryType) {
      case 'HOURLY':
        return 'Theo giờ';

      case 'DAILY':
        return 'Theo ngày';

      case 'SHIFT':
        return 'Theo ca';

      case 'MONTHLY':
        return 'Theo tháng';

      case 'FIXED':
        return 'Trọn công việc';

      default:
        return 'Chưa xác định';
    }
  }

  // =====================================================
  // SHIFT
  // =====================================================

  String get shiftTypeText {
    switch (shiftType) {
      case 'MORNING':
        return 'Ca sáng';

      case 'AFTERNOON':
        return 'Ca chiều';

      case 'EVENING':
        return 'Ca tối';

      case 'NIGHT':
        return 'Ca đêm';

      case 'FLEXIBLE':
        return 'Linh hoạt';

      default:
        return 'Chưa xác định';
    }
  }

  // =====================================================
  // WORK DAYS
  // =====================================================

  String get workDaysText {
    if (workDays.isEmpty) {
      return 'Chưa cập nhật ngày làm';
    }

    return workDays.map(_dayText).join(', ');
  }

  // =====================================================
  // SCHEDULE
  // =====================================================

  String get timeText {
    if (startTime != null && endTime != null) {
      return '$startTime - $endTime';
    }

    return shiftTypeText;
  }

  String get scheduleText {
    final parts = <String>[];

    if (workDays.isNotEmpty) {
      parts.add(workDaysText);
    }

    if (startTime != null && endTime != null) {
      parts.add('$startTime - $endTime');
    } else if (shiftType != null) {
      parts.add(shiftTypeText);
    }

    if (parts.isEmpty) {
      return 'Chưa cập nhật lịch làm';
    }

    return parts.join(' • ');
  }

  // =====================================================
  // DEADLINE
  // =====================================================

  String get deadlineText {
    if (deadline == null) {
      return 'Không giới hạn';
    }

    final local = deadline!.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // =====================================================
  // URGENT UNTIL
  // =====================================================

  String get urgentUntilText {
    if (urgentUntil == null) {
      return 'Không giới hạn';
    }

    final local = urgentUntil!.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  // =====================================================
  // DISTANCE
  // =====================================================

  String get distanceText {
    if (distanceKm == null) {
      return location ?? 'Chưa cập nhật địa điểm';
    }

    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  String get locationDistanceText {
    final cleanLocation =
    location?.trim();

    if (distanceKm != null) {
      final distance =
          '${distanceKm!.toStringAsFixed(1)} km';

      if (cleanLocation != null &&
          cleanLocation.isNotEmpty) {
        return '$cleanLocation • $distance';
      }

      return distance;
    }

    if (cleanLocation != null &&
        cleanLocation.isNotEmpty) {
      return cleanLocation;
    }

    return 'Chưa cập nhật địa điểm';
  }

  String get cvText {
    return cvRequired
        ? 'Yêu cầu CV'
        : 'Không bắt buộc CV';
  }

  String get applicationCountText {
    if (applicationCount == 0) {
      return 'Chưa có ứng viên';
    }

    return '$applicationCount ứng viên';
  }

  // =====================================================
  // MAP
  // =====================================================

  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  // =====================================================
  // HELPERS
  // =====================================================

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int? _toInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static String? _parseClockTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    // Prisma @db.Time có thể được serialize
    // thành dạng ISO:
    // 1970-01-01T08:30:00.000Z
    final parsed = DateTime.tryParse(text);

    if (parsed != null) {
      final utc = parsed.toUtc();

      final hour = utc.hour.toString().padLeft(2, '0');

      final minute = utc.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    }

    // Hoặc backend trả:
    // 08:30
    // 08:30:00
    final parts = text.split(':');

    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);

      final minute = int.tryParse(parts[1]);

      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        return '${hour.toString().padLeft(2, '0')}:'
            '${minute.toString().padLeft(2, '0')}';
      }
    }

    return null;
  }

  static String _dayText(String value) {
    switch (value) {
      case 'MONDAY':
        return 'T2';

      case 'TUESDAY':
        return 'T3';

      case 'WEDNESDAY':
        return 'T4';

      case 'THURSDAY':
        return 'T5';

      case 'FRIDAY':
        return 'T6';

      case 'SATURDAY':
        return 'T7';

      case 'SUNDAY':
        return 'CN';

      default:
        return value;
    }
  }

  static String _formatMoney(double value) {
    final text = value.round().toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}

// =======================================================
// AI RECOMMENDATION
// =======================================================

class JobRecommendation {
  final Job job;
  final double score;
  final List<String> reasons;

  const JobRecommendation({
    required this.job,
    required this.score,
    required this.reasons,
  });

  factory JobRecommendation.fromJson(Map<String, dynamic> json) {
    final rawJob = json['job'];

    final Map<String, dynamic> jobJson;

    if (rawJob is Map) {
      jobJson = Map<String, dynamic>.from(rawJob);
    } else {
      jobJson = Map<String, dynamic>.from(json);
    }

    final rawReasons = json['reasons'];

    final reasons = <String>[];

    if (rawReasons is List) {
      for (final reason in rawReasons) {
        reasons.add(reason.toString());
      }
    } else if (rawReasons != null) {
      reasons.add(rawReasons.toString());
    }

    return JobRecommendation(
      job: Job.fromJson(jobJson),

      score: Job._toDouble(json['score']) ?? 0,

      reasons: reasons,
    );
  }

  int get percentage {
    if (score <= 1) {
      return (score * 100).round();
    }

    return score.round();
  }
}

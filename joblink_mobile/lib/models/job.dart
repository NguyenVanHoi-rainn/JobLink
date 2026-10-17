class Job {
  final String id;
  final String title;
  final String? description;
  final double? salary;
  final String? location;
  final double? distanceKm;
  final bool cvRequired;
  final DateTime? deadline;
  final String? status;

  final String? employerName;
  final String? employerLogoUrl;
  final String? categoryName;

  final List<String> skills;

  const Job({
    required this.id,
    required this.title,
    this.description,
    this.salary,
    this.location,
    this.distanceKm,
    this.cvRequired = false,
    this.deadline,
    this.status,
    this.employerName,
    this.employerLogoUrl,
    this.categoryName,
    this.skills = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final employer = json['employer'];
    final category = json['category'];
    final jobSkills = json['jobSkills'];

    String? employerName;
    String? employerLogoUrl;

    if (employer is Map) {
      employerName = employer['companyName']?.toString();
      employerLogoUrl = employer['logoUrl']?.toString();
    }

    String? categoryName;

    if (category is Map) {
      categoryName = category['name']?.toString();
    }

    final skills = <String>[];

    if (jobSkills is List) {
      for (final item in jobSkills) {
        if (item is Map) {
          final skill = item['skill'];

          if (skill is Map) {
            final name = skill['name']?.toString();

            if (name != null && name.isNotEmpty) {
              skills.add(name);
            }
          }
        }
      }
    }

    DateTime? deadline;

    final rawDeadline = json['deadline'];

    if (rawDeadline != null) {
      deadline = DateTime.tryParse(
        rawDeadline.toString(),
      );
    }

    return Job(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Công việc',
      description: json['description']?.toString(),
      salary: _toDouble(json['salary']),
      location: json['location']?.toString(),
      distanceKm: _toDouble(json['distanceKm']),
      cvRequired: json['cvRequired'] == true,
      deadline: deadline,
      status: json['status']?.toString(),
      employerName:
      employerName ??
          json['companyName']?.toString() ??
          'Nhà tuyển dụng',
      employerLogoUrl: employerLogoUrl,
      categoryName: categoryName,
      skills: skills,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  String get salaryText {
    if (salary == null) {
      return 'Thỏa thuận';
    }

    return '${_formatMoney(salary!)}đ';
  }

  String get deadlineText {
    if (deadline == null) {
      return 'Không giới hạn';
    }

    final local = deadline!.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String get distanceText {
    if (distanceKm == null) {
      return location ?? 'Chưa cập nhật địa điểm';
    }

    return '${distanceKm!.toStringAsFixed(1)} km';
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

class JobRecommendation {
  final Job job;
  final double score;
  final List<String> reasons;

  const JobRecommendation({
    required this.job,
    required this.score,
    required this.reasons,
  });

  factory JobRecommendation.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawJob = json['job'];

    final Map<String, dynamic> jobJson;

    if (rawJob is Map) {
      jobJson = Map<String, dynamic>.from(
        rawJob,
      );
    } else {
      jobJson = Map<String, dynamic>.from(
        json,
      );
    }

    final rawReasons = json['reasons'];

    final reasons = <String>[];

    if (rawReasons is List) {
      for (final reason in rawReasons) {
        reasons.add(
          reason.toString(),
        );
      }
    } else if (rawReasons != null) {
      reasons.add(
        rawReasons.toString(),
      );
    }

    return JobRecommendation(
      job: Job.fromJson(jobJson),
      score: Job._toDouble(
        json['score'],
      ) ??
          0,
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
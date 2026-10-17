class Job {
  final String id;
  final String title;
  final String? description;
  final String? address;
  final double? salaryMin;
  final double? salaryMax;
  final bool cvRequired;
  final String? employerName;

  const Job({
    required this.id,
    required this.title,
    this.description,
    this.address,
    this.salaryMin,
    this.salaryMax,
    this.cvRequired = false,
    this.employerName,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final employer = json['employer'];

    String? employerName;

    if (employer is Map) {
      employerName =
          employer['companyName']?.toString() ??
              employer['name']?.toString();
    }

    employerName ??=
        json['companyName']?.toString() ??
            json['employerName']?.toString();

    return Job(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Công việc',
      description: json['description']?.toString(),
      address:
      json['address']?.toString() ??
          json['location']?.toString(),
      salaryMin: _toDouble(
        json['salaryMin'] ?? json['minSalary'],
      ),
      salaryMax: _toDouble(
        json['salaryMax'] ?? json['maxSalary'],
      ),
      cvRequired: json['cvRequired'] == true,
      employerName: employerName,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  String get salaryText {
    if (salaryMin == null && salaryMax == null) {
      return 'Thỏa thuận';
    }

    if (salaryMin != null &&
        salaryMax != null &&
        salaryMin != salaryMax) {
      return '${_formatMoney(salaryMin!)} - '
          '${_formatMoney(salaryMax!)}đ';
    }

    final salary = salaryMin ?? salaryMax!;

    return '${_formatMoney(salary)}đ';
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
    final jobData = json['job'];

    final Map<String, dynamic> jobJson;

    if (jobData is Map) {
      jobJson = Map<String, dynamic>.from(jobData);
    } else {
      // Phòng trường hợp backend trả thông tin job
      // cùng cấp với score.
      jobJson = Map<String, dynamic>.from(json);
    }

    final rawReasons = json['reasons'];

    List<String> reasons = [];

    if (rawReasons is List) {
      reasons = rawReasons
          .map((e) => e.toString())
          .toList();
    } else if (rawReasons != null) {
      reasons = [
        rawReasons.toString(),
      ];
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
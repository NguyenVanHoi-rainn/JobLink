import 'job.dart';

class JobApplication {
  final String id;
  final String jobId;
  final String status;
  final DateTime? createdAt;
  final double? matchingScore;
  final Job? job;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.status,
    this.createdAt,
    this.matchingScore,
    this.job,
  });

  factory JobApplication.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawJob = json['job'];

    Job? job;

    if (rawJob is Map) {
      job = Job.fromJson(
        Map<String, dynamic>.from(rawJob),
      );
    }

    return JobApplication(
      id: json['id']?.toString() ?? '',
      jobId:
      json['jobId']?.toString() ??
          job?.id ??
          '',
      status:
      json['status']?.toString() ??
          'APPLIED',
      createdAt: _parseDate(
        json['createdAt'],
      ),
      matchingScore: _toDouble(
        json['scoreMatching'] ??
            json['matchingScore'] ??
            json['candidateMatch']?['score'],
      ),
      job: job,
    );
  }

  static DateTime? _parseDate(
      dynamic value,
      ) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static double? _toDouble(
      dynamic value,
      ) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  String get statusText {
    switch (status) {
      case 'APPLIED':
        return 'Đã ứng tuyển';

      case 'REVIEWING':
        return 'Đang xem xét';

      case 'ACCEPTED':
        return 'Đã được nhận';

      case 'REJECTED':
        return 'Không phù hợp';

      case 'WITHDRAWN':
        return 'Đã rút đơn';

      default:
        return status;
    }
  }

  String get createdAtText {
    if (createdAt == null) {
      return '';
    }

    final date = createdAt!.toLocal();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  int? get matchPercentage {
    if (matchingScore == null) {
      return null;
    }

    if (matchingScore! <= 1) {
      return (matchingScore! * 100).round();
    }

    return matchingScore!.round();
  }
}
class WorkerOption {
  final String id;
  final String name;

  const WorkerOption({required this.id, required this.name});

  factory WorkerOption.fromJson(Map<String, dynamic> json) {
    return WorkerOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class WorkerAvailability {
  final String? id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  const WorkerAvailability({
    this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory WorkerAvailability.fromJson(Map<String, dynamic> json) {
    return WorkerAvailability(
      id: json['id']?.toString(),
      dayOfWeek: json['dayOfWeek']?.toString() ?? 'MONDAY',
      startTime: _normalizeTime(json['startTime']) ?? '08:00',
      endTime: _normalizeTime(json['endTime']) ?? '17:00',
    );
  }

  static String? _normalizeTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();

    final plain = RegExp(r'^(\d{2}):(\d{2})').firstMatch(text);

    if (plain != null) {
      return '${plain.group(1)}:${plain.group(2)}';
    }

    final iso = RegExp(r'T(\d{2}):(\d{2})').firstMatch(text);

    if (iso != null) {
      return '${iso.group(1)}:${iso.group(2)}';
    }

    return text;
  }
}

class WorkerCv {
  final String id;
  final String fileName;
  final String? fileUrl;
  final DateTime? uploadedAt;

  const WorkerCv({
    required this.id,
    required this.fileName,
    this.fileUrl,
    this.uploadedAt,
  });

  factory WorkerCv.fromJson(Map<String, dynamic> json) {
    return WorkerCv(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'CV',
      fileUrl: json['fileUrl']?.toString(),
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? ''),
    );
  }
}

class WorkerAiProfile {
  final bool ready;
  final int completionPercent;
  final List<String> missingFields;

  const WorkerAiProfile({
    required this.ready,
    required this.completionPercent,
    required this.missingFields,
  });

  factory WorkerAiProfile.fromJson(Map<String, dynamic> json) {
    final rawMissing = json['missingFields'];

    return WorkerAiProfile(
      ready: json['ready'] == true,
      completionPercent: _toInt(json['completionPercent']) ?? 0,
      missingFields: rawMissing is List
          ? rawMissing.map((item) => item.toString()).toList()
          : const [],
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}

class WorkerProfile {
  final String id;
  final String userId;
  final String email;

  final String? fullName;
  final String? phone;
  final String? bio;

  final String? searchArea;

  final double? latitude;
  final double? longitude;

  final double? preferredMinSalary;
  final String? preferredSalaryType;
  final int? maxDistanceKm;

  final List<WorkerOption> skills;
  final List<WorkerOption> categories;

  final List<WorkerAvailability> availabilities;
  final List<WorkerCv> cvs;

  final WorkerAiProfile aiProfile;

  const WorkerProfile({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    this.phone,
    this.bio,
    this.searchArea,
    this.latitude,
    this.longitude,
    this.preferredMinSalary,
    this.preferredSalaryType,
    this.maxDistanceKm,
    required this.skills,
    required this.categories,
    required this.availabilities,
    required this.cvs,
    required this.aiProfile,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',

      fullName: _nullableText(json['fullName']),

      phone: _nullableText(json['phone']),

      bio: _nullableText(json['bio']),

      searchArea: _nullableText(json['searchArea']),

      latitude: _toDouble(json['latitude']),

      longitude: _toDouble(json['longitude']),

      preferredMinSalary: _toDouble(json['preferredMinSalary']),

      preferredSalaryType: _nullableText(json['preferredSalaryType']),

      maxDistanceKm: _toInt(json['maxDistanceKm']),

      skills: _parseOptions(json['skills']),

      categories: _parseOptions(json['categories']),

      availabilities: _parseAvailabilities(json['availabilities']),

      cvs: _parseCvs(json['cvs']),

      aiProfile: json['aiProfile'] is Map
          ? WorkerAiProfile.fromJson(
              Map<String, dynamic>.from(json['aiProfile'] as Map),
            )
          : const WorkerAiProfile(
              ready: false,
              completionPercent: 0,
              missingFields: [],
            ),
    );
  }

  static String? _nullableText(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static List<WorkerOption> _parseOptions(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => WorkerOption.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static List<WorkerAvailability> _parseAvailabilities(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
              WorkerAvailability.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static List<WorkerCv> _parseCvs(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => WorkerCv.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }
}

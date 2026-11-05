import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/job.dart';

// =======================================================
// SEARCH RESULT
// =======================================================

class JobSearchResult {
  final List<Job> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const JobSearchResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

// =======================================================
// JOB SERVICE
// =======================================================

class JobService {
  final Dio _dio = ApiClient.dio;

  // =====================================================
  // GET JOBS
  //
  // Dùng cho Home:
  // final jobs = await service.getJobs();
  // =====================================================

  Future<List<Job>> getJobs({
    String? keyword,
    String? categoryId,
    double? minSalary,
    double? maxSalary,
    String? salaryType,
    String? location,
    String? shiftType,
    List<String>? workDays,
    List<String>? skillIds,
    bool? cvRequired,
    bool? urgent,
    double? latitude,
    double? longitude,
    double? maxDistanceKm,
    String sort = 'NEWEST',
    int page = 1,
    int limit = 20,
  }) async {
    final result = await searchJobs(
      keyword: keyword,
      categoryId: categoryId,
      minSalary: minSalary,
      maxSalary: maxSalary,
      salaryType: salaryType,
      location: location,
      shiftType: shiftType,
      workDays: workDays,
      skillIds: skillIds,
      cvRequired: cvRequired,
      urgent: urgent,
      latitude: latitude,
      longitude: longitude,
      maxDistanceKm: maxDistanceKm,
      sort: sort,
      page: page,
      limit: limit,
    );

    return result.items;
  }

  // =====================================================
  // SEARCH JOBS
  //
  // Dùng cho màn Search:
  //
  // final result = await service.searchJobs(...);
  //
  // result.items
  // result.total
  // result.page
  // result.totalPages
  // =====================================================

  Future<JobSearchResult> searchJobs({
    String? keyword,
    String? categoryId,
    double? minSalary,
    double? maxSalary,
    String? salaryType,
    String? location,
    String? shiftType,

    // Nullable để tương thích WorkerHome hiện tại.
    List<String>? workDays,
    List<String>? skillIds,

    bool? cvRequired,
    bool? urgent,

    double? latitude,
    double? longitude,
    double? maxDistanceKm,

    String sort = 'NEWEST',

    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit, 'sort': sort};

    // ===================================================
    // KEYWORD
    // ===================================================

    final cleanKeyword = keyword?.trim();

    if (cleanKeyword != null && cleanKeyword.isNotEmpty) {
      query['keyword'] = cleanKeyword;
    }

    // ===================================================
    // CATEGORY
    // ===================================================

    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }

    // ===================================================
    // SALARY
    // ===================================================

    if (minSalary != null) {
      query['minSalary'] = minSalary;
    }

    if (maxSalary != null) {
      query['maxSalary'] = maxSalary;
    }

    if (salaryType != null && salaryType.isNotEmpty) {
      query['salaryType'] = salaryType;
    }

    // ===================================================
    // LOCATION TEXT
    // ===================================================

    final cleanLocation = location?.trim();

    if (cleanLocation != null && cleanLocation.isNotEmpty) {
      query['location'] = cleanLocation;
    }

    // ===================================================
    // SHIFT
    // ===================================================

    if (shiftType != null && shiftType.isNotEmpty) {
      query['shiftType'] = shiftType;
    }

    // ===================================================
    // WORK DAYS
    // ===================================================

    final cleanWorkDays =
        workDays?.where((item) => item.trim().isNotEmpty).toList() ??
        <String>[];

    if (cleanWorkDays.isNotEmpty) {
      query['workDays'] = cleanWorkDays;
    }

    // ===================================================
    // SKILLS
    // ===================================================

    final cleanSkillIds =
        skillIds?.where((item) => item.trim().isNotEmpty).toList() ??
        <String>[];

    if (cleanSkillIds.isNotEmpty) {
      query['skillIds'] = cleanSkillIds;
    }

    // ===================================================
    // CV
    // ===================================================

    if (cvRequired != null) {
      query['cvRequired'] = cvRequired;
    }

    // ===================================================
    // URGENT
    // ===================================================

    if (urgent != null) {
      query['urgent'] = urgent;
    }

    // ===================================================
    // COORDINATES
    //
    // Chỉ gửi khi đủ cả 2.
    // ===================================================

    if (latitude != null && longitude != null) {
      query['latitude'] = latitude;

      query['longitude'] = longitude;
    }

    // ===================================================
    // DISTANCE
    // ===================================================

    if (maxDistanceKm != null) {
      query['maxDistanceKm'] = maxDistanceKm;
    }

    // ===================================================
    // REQUEST
    // ===================================================

    final response = await _dio.get(
      '/jobs',
      queryParameters: query,
      options: Options(listFormat: ListFormat.multi),
    );

    return _parseSearchResult(
      response.data,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  }

  // =====================================================
  // CATEGORIES
  // =====================================================

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _dio.get('/jobs/meta/categories');

    final list = _extractList(
      response.data,
      keys: ['items', 'data', 'categories', 'results'],
    );

    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // =====================================================
  // SKILLS
  // =====================================================

  Future<List<Map<String, dynamic>>> getSkills() async {
    final response = await _dio.get('/jobs/meta/skills');

    final list = _extractList(
      response.data,
      keys: ['items', 'data', 'skills', 'results'],
    );

    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // =====================================================
  // AI RECOMMENDATIONS
  // =====================================================

  Future<List<JobRecommendation>> getRecommendations() async {
    final response = await _dio.get('/workers/me/recommendations/jobs');

    final list = _extractList(
      response.data,
      keys: ['recommendations', 'data', 'items', 'results'],
    );

    return list
        .whereType<Map>()
        .map(
          (item) => JobRecommendation.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.job.id.isNotEmpty)
        .toList();
  }

  // =====================================================
  // SAVED JOB
  // =====================================================

  Future<List<Map<String, dynamic>>> getSavedJobs() async {
    final response = await _dio.get('/saved-jobs');

    final list = _extractList(
      response.data,
      keys: ['items', 'data', 'results'],
    );

    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<bool> isJobSaved(String jobId) async {
    final response = await _dio.get('/saved-jobs/$jobId/check');
    final data = response.data;

    if (data is Map) {
      final nested = data['data'];
      if (nested is Map) {
        return nested['isSaved'] == true;
      }
      return data['isSaved'] == true;
    }

    return false;
  }

  Future<void> saveJob(String jobId) async {
    await _dio.post('/saved-jobs/$jobId');
  }

  Future<void> unsaveJob(String jobId) async {
    await _dio.delete('/saved-jobs/$jobId');
  }

  // =====================================================
  // WORKER CV
  // =====================================================

  Future<List<Map<String, dynamic>>> getMyCvs() async {
    final response = await _dio.get('/workers/me/cvs');

    final list = _extractList(
      response.data,
      keys: ['items', 'data', 'cvs', 'results'],
    );

    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // =====================================================
  // APPLICATION CHECK
  // =====================================================

  Future<bool> hasApplied(String jobId) async {
    final response = await _dio.get('/applications/me');

    final list = _extractList(
      response.data,
      keys: ['items', 'data', 'applications', 'results'],
    );

    for (final item in list) {
      if (item is! Map) {
        continue;
      }

      final application = Map<String, dynamic>.from(item);

      final directJobId = application['jobId']?.toString();

      String? nestedJobId;

      final rawJob = application['job'];

      if (rawJob is Map) {
        nestedJobId = rawJob['id']?.toString();
      }

      final status = application['status']?.toString();

      final sameJob = directJobId == jobId || nestedJobId == jobId;

      if (sameJob && status != 'WITHDRAWN') {
        return true;
      }
    }

    return false;
  }

  // =====================================================
  // APPLY JOB
  // =====================================================

  Future<void> applyToJob({
    required String jobId,
    String? cvId,
    String? note,
  }) async {
    final data = <String, dynamic>{};

    if (cvId != null && cvId.isNotEmpty) {
      data['cvId'] = cvId;
    }

    final cleanNote = note?.trim();

    if (cleanNote != null && cleanNote.isNotEmpty) {
      data['note'] = cleanNote;
    }

    await _dio.post('/jobs/$jobId/apply', data: data);
  }



  // =====================================================
  // PARSE SEARCH RESULT
  // =====================================================

  JobSearchResult _parseSearchResult(
    dynamic raw, {
    required int fallbackPage,
    required int fallbackLimit,
  }) {
    // Backend bình thường trả:
    //
    // {
    //   page,
    //   limit,
    //   total,
    //   totalPages,
    //   items: [...]
    // }

    dynamic data = raw;

    // Hỗ trợ trường hợp:
    // {
    //   data: {
    //     page,
    //     items...
    //   }
    // }
    if (data is Map && data['data'] is Map) {
      final nested = data['data'] as Map;

      if (nested.containsKey('items') || nested.containsKey('jobs')) {
        data = nested;
      }
    }

    // ===================================================
    // MAP RESPONSE
    // ===================================================

    if (data is Map) {
      final list = _extractList(
        data,
        keys: ['items', 'jobs', 'results', 'data'],
      );

      final items = list
          .whereType<Map>()
          .map((item) => Job.fromJson(Map<String, dynamic>.from(item)))
          .where((job) => job.id.isNotEmpty)
          .toList();

      final page = _toInt(data['page']) ?? fallbackPage;

      final limit = _toInt(data['limit']) ?? fallbackLimit;

      final total = _toInt(data['total']) ?? items.length;

      final totalPages =
          _toInt(data['totalPages']) ??
          (total == 0 ? 0 : (total / limit).ceil());

      return JobSearchResult(
        items: items,
        page: page,
        limit: limit,
        total: total,
        totalPages: totalPages,
      );
    }

    // ===================================================
    // LIST RESPONSE FALLBACK
    // ===================================================

    if (data is List) {
      final items = data
          .whereType<Map>()
          .map((item) => Job.fromJson(Map<String, dynamic>.from(item)))
          .where((job) => job.id.isNotEmpty)
          .toList();

      return JobSearchResult(
        items: items,
        page: fallbackPage,
        limit: fallbackLimit,
        total: items.length,
        totalPages: items.isEmpty ? 0 : 1,
      );
    }

    return JobSearchResult(
      items: const [],
      page: fallbackPage,
      limit: fallbackLimit,
      total: 0,
      totalPages: 0,
    );
  }

  // =====================================================
  // EXTRACT LIST
  // =====================================================

  List<dynamic> _extractList(dynamic data, {required List<String> keys}) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is List) {
          return value;
        }

        if (value is Map) {
          for (final nestedKey in [
            'items',
            'data',
            'jobs',
            'applications',
            'recommendations',
            'results',
            'cvs',
            'categories',
            'skills',
          ]) {
            final nested = value[nestedKey];

            if (nested is List) {
              return nested;
            }
          }
        }
      }
    }

    return [];
  }

  // =====================================================
  // TO INT
  // =====================================================

  int? _toInt(dynamic value) {
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
}

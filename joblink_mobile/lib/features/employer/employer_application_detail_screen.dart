import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/employer_application_service.dart';

class EmployerApplicationDetailScreen
    extends StatefulWidget {
  const EmployerApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  final String applicationId;

  @override
  State<EmployerApplicationDetailScreen>
  createState() =>
      _EmployerApplicationDetailScreenState();
}

class _EmployerApplicationDetailScreenState
    extends State<EmployerApplicationDetailScreen> {
  final EmployerApplicationService
  _service =
  EmployerApplicationService();

  Map<String, dynamic>? _application;
  Map<String, dynamic>? _match;

  bool _loading = true;
  bool _changingStatus = false;
  bool _openingCv = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final application =
      await _service
          .getApplication(
        widget.applicationId,
      );

      Map<String, dynamic>?
      match;

      try {
        match =
        await _service
            .getCandidateMatch(
          widget.applicationId,
        );
      } catch (error) {
        debugPrint(
          'Candidate match unavailable: $error',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _application =
            application;
        _match = match;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Không thể tải hồ sơ ứng viên';
      });

      debugPrint(
        'Load employer application detail failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeStatus(
      String status,
      ) async {
    final message =
    status == 'REVIEWING'
        ? 'Chuyển hồ sơ sang trạng thái đang xem xét?'
        : status == 'ACCEPTED'
        ? 'Chấp nhận ứng viên này?'
        : 'Từ chối ứng viên này?';

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text(
              'Xác nhận',
            ),
            content: Text(
              message,
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      false,
                    ),
                child:
                const Text(
                  'Hủy',
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                      context,
                      true,
                    ),
                child:
                const Text(
                  'Đồng ý',
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _changingStatus = true;
    });

    try {
      await _service.updateStatus(
        widget.applicationId,
        status,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _statusSuccessText(
              status,
            ),
          ),
        ),
      );

      await _load();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final data =
          error.response?.data;

      String? message;

      if (data is Map) {
        final raw =
        data['message'];

        if (raw is List) {
          message =
              raw.join(', ');
        } else {
          message =
              raw?.toString();
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            message ??
                'Không thể cập nhật trạng thái',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể cập nhật trạng thái',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingStatus =
          false;
        });
      }
    }
  }

  Future<void> _openCv() async {
    setState(() {
      _openingCv = true;
    });

    try {
      final cv =
      await _service.getCv(
        widget.applicationId,
      );

      final fileUrl =
      _text(
        cv['fileUrl'],
      );

      if (fileUrl == null) {
        throw StateError(
          'CV không có đường dẫn file',
        );
      }

      final resolved =
      _service
          .resolveBackendFileUrl(
        fileUrl,
      );

      final uri =
      Uri.parse(resolved);

      final opened =
      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication,
      );

      if (!opened) {
        throw StateError(
          'Không thể mở CV',
        );
      }
    } on DioException catch (error) {
      if (!mounted) return;

      final data =
          error.response?.data;

      String? message;

      if (data is Map) {
        message =
            data['message']
                ?.toString();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            message ??
                'Không thể mở CV',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể mở CV',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingCv = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F7FB,
      ),
      appBar: AppBar(
        title:
        const Text(
          'Hồ sơ ứng viên',
        ),
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
      ),
      body:
      _buildBody(),
      bottomNavigationBar:
      _buildActions(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .cloud_off_rounded,
                size: 44,
                color:
                Colors.redAccent,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _error!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(
                height: 14,
              ),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(
                  Icons
                      .refresh_rounded,
                ),
                label:
                const Text(
                  'Thử lại',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final application =
        _application;

    if (application == null) {
      return const Center(
        child: Text(
          'Không tìm thấy hồ sơ',
        ),
      );
    }

    final worker =
    _asMap(
      application['worker'],
    );

    final user =
    _asMap(
      worker?['user'],
    );

    final job =
    _asMap(
      application['job'],
    );

    final cv =
    _asMap(
      application['cv'],
    );

    final status =
        _text(
          application['status'],
        ) ??
            'APPLIED';

    final name =
        _firstText([
          worker?['fullName'],
          worker?['name'],
          user?['email'],
        ]) ??
            'Ứng viên';

    final email =
    _text(
      user?['email'],
    );

    final phone =
    _text(
      worker?['phone'],
    );

    final address =
    _text(
      worker?['address'],
    );

    final note =
    _text(
      application['note'],
    );

    final jobTitle =
        _text(
          job?['title'],
        ) ??
            'Công việc';

    final skills =
    _extractSkillNames(
      worker?['workerSkills'],
    );

    final experiences =
    _extractExperiences(
      worker?['workExperiences'],
    );

    final reasons =
    _extractReasons(
      _match?['reasons'],
    );

    final score =
    _matchScore(
      _match,
    );

    final hasCv =
        cv != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          30,
        ),
        children: [
          _ProfileHeader(
            name: name,
            email: email,
            status: status,
          ),
          const SizedBox(
            height: 14,
          ),
          _CardSection(
            title:
            'Thông tin ứng tuyển',
            children: [
              _InfoRow(
                icon:
                Icons.work_outline,
                label: 'Công việc',
                value: jobTitle,
              ),
              if (phone !=
                  null)
                _InfoRow(
                  icon:
                  Icons
                      .phone_outlined,
                  label:
                  'Điện thoại',
                  value: phone,
                ),
              if (address !=
                  null)
                _InfoRow(
                  icon:
                  Icons
                      .location_on_outlined,
                  label:
                  'Địa chỉ',
                  value: address,
                ),
              if (note !=
                  null)
                _InfoRow(
                  icon:
                  Icons.notes_rounded,
                  label:
                  'Ghi chú',
                  value: note,
                ),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            _CardSection(
              title: 'Kỹ năng',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  skills
                      .map(
                        (skill) =>
                        Chip(
                          label:
                          Text(
                            skill,
                          ),
                          visualDensity:
                          VisualDensity
                              .compact,
                        ),
                  )
                      .toList(),
                ),
              ],
            ),
          ],
          if (experiences.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            _CardSection(
              title:
              'Kinh nghiệm',
              children:
              experiences
                  .map(
                    (item) =>
                    Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 10,
                      ),
                      child:
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Icon(
                            Icons
                                .business_center_outlined,
                            size: 18,
                            color:
                            Color(
                              0xFF64748B,
                            ),
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Expanded(
                            child:
                            Text(
                              item,
                            ),
                          ),
                        ],
                      ),
                    ),
              )
                  .toList(),
            ),
          ],
          if (_match != null) ...[
            const SizedBox(
              height: 14,
            ),
            _CardSection(
              title:
              'AI Matching',
              children: [
                if (score !=
                    null)
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .auto_awesome_rounded,
                        color:
                        Color(
                          0xFF7C3AED,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        '${score.toStringAsFixed(0)}% phù hợp',
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF7C3AED,
                          ),
                          fontSize: 18,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    ],
                  ),
                if (reasons.isNotEmpty) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  ...reasons.map(
                        (reason) =>
                        Padding(
                          padding:
                          const EdgeInsets
                              .only(
                            bottom: 7,
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const Icon(
                                Icons
                                    .check_circle_outline,
                                size: 17,
                                color:
                                Color(
                                  0xFF7C3AED,
                                ),
                              ),
                              const SizedBox(
                                width: 7,
                              ),
                              Expanded(
                                child:
                                Text(
                                  reason,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ],
              ],
            ),
          ],
          if (hasCv) ...[
            const SizedBox(
              height: 14,
            ),
            OutlinedButton.icon(
              onPressed:
              _openingCv
                  ? null
                  : _openCv,
              icon:
              _openingCv
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                ),
              )
                  : const Icon(
                Icons
                    .description_outlined,
              ),
              label:
              const Text(
                'Xem CV',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildActions() {
    final application =
        _application;

    if (_loading ||
        application == null) {
      return null;
    }

    final status =
        _text(
          application['status'],
        ) ??
            'APPLIED';

    if (status ==
        'APPLIED') {
      return _ActionBar(
        child: SizedBox(
          width:
          double.infinity,
          child:
          FilledButton.icon(
            onPressed:
            _changingStatus
                ? null
                : () =>
                _changeStatus(
                  'REVIEWING',
                ),
            icon:
            _changingStatus
                ? const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth:
                2,
              ),
            )
                : const Icon(
              Icons
                  .visibility_outlined,
            ),
            label:
            const Text(
              'Chuyển sang xem xét',
            ),
          ),
        ),
      );
    }

    if (status ==
        'REVIEWING') {
      return _ActionBar(
        child: Row(
          children: [
            Expanded(
              child:
              OutlinedButton.icon(
                onPressed:
                _changingStatus
                    ? null
                    : () =>
                    _changeStatus(
                      'REJECTED',
                    ),
                icon:
                const Icon(
                  Icons.close_rounded,
                ),
                label:
                const Text(
                  'Từ chối',
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child:
              FilledButton.icon(
                onPressed:
                _changingStatus
                    ? null
                    : () =>
                    _changeStatus(
                      'ACCEPTED',
                    ),
                icon:
                const Icon(
                  Icons
                      .check_rounded,
                ),
                label:
                const Text(
                  'Chấp nhận',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return null;
  }

  String _statusSuccessText(
      String status,
      ) {
    switch (status) {
      case 'REVIEWING':
        return 'Đã chuyển hồ sơ sang đang xem xét';
      case 'ACCEPTED':
        return 'Đã chấp nhận ứng viên';
      case 'REJECTED':
        return 'Đã từ chối ứng viên';
      default:
        return 'Đã cập nhật trạng thái';
    }
  }

  Map<String, dynamic>? _asMap(
      dynamic value,
      ) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }

  String? _text(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    return text.isEmpty
        ? null
        : text;
  }

  String? _firstText(
      List<dynamic> values,
      ) {
    for (final value
    in values) {
      final text =
      _text(value);

      if (text != null) {
        return text;
      }
    }

    return null;
  }

  List<String> _extractSkillNames(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    final result =
    <String>[];

    for (final item
    in value) {
      if (item is! Map) {
        continue;
      }

      final map =
      Map<String, dynamic>.from(
        item,
      );

      final skill =
      _asMap(
        map['skill'],
      );

      final name =
      _firstText([
        skill?['name'],
        map['name'],
      ]);

      if (name != null) {
        result.add(name);
      }
    }

    return result;
  }

  List<String> _extractExperiences(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    final result =
    <String>[];

    for (final item
    in value) {
      if (item is! Map) {
        continue;
      }

      final map =
      Map<String, dynamic>.from(
        item,
      );

      final title =
      _firstText([
        map['position'],
        map['title'],
        map['role'],
      ]);

      final company =
      _firstText([
        map['companyName'],
        map['company'],
      ]);

      if (title != null &&
          company != null) {
        result.add(
          '$title - $company',
        );
      } else if (title !=
          null) {
        result.add(title);
      } else if (company !=
          null) {
        result.add(company);
      }
    }

    return result;
  }

  List<String> _extractReasons(
      dynamic value,
      ) {
    if (value is List) {
      return value
          .map(
            (item) =>
            item
                .toString()
                .trim(),
      )
          .where(
            (item) =>
        item.isNotEmpty,
      )
          .toList();
    }

    final single =
    _text(value);

    return single == null
        ? []
        : [single];
  }

  double? _matchScore(
      Map<String, dynamic>?
      match,
      ) {
    if (match == null) {
      return null;
    }

    for (final key in [
      'score',
      'matchingScore',
      'scoreMatching',
      'percentage',
      'matchPercentage',
    ]) {
      final value =
      match[key];

      if (value is num) {
        final score =
        value.toDouble();

        return score <= 1
            ? score * 100
            : score;
      }

      final parsed =
      double.tryParse(
        value?.toString() ?? '',
      );

      if (parsed != null) {
        return parsed <= 1
            ? parsed * 100
            : parsed;
      }
    }

    return null;
  }
}

class _ProfileHeader
    extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.status,
  });

  final String name;
  final String? email;
  final String status;

  @override
  Widget build(
      BuildContext context,
      ) {
    final color =
    _statusColor(
      status,
    );

    return Container(
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
            const Color(
              0xFF2563EB,
            ).withValues(
              alpha: 0.10,
            ),
            child:
            const Icon(
              Icons.person_rounded,
              color:
              Color(
                0xFF2563EB,
              ),
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  name,
                  style:
                  const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
                if (email !=
                    null) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    email!,
                    style:
                    TextStyle(
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                ],
                const SizedBox(
                  height: 7,
                ),
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    color.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      9,
                    ),
                  ),
                  child: Text(
                    _statusText(
                      status,
                    ),
                    style:
                    TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _statusText(
      String status,
      ) {
    switch (status) {
      case 'REVIEWING':
        return 'Đang xem xét';
      case 'ACCEPTED':
        return 'Đã chấp nhận';
      case 'REJECTED':
        return 'Đã từ chối';
      case 'WITHDRAWN':
        return 'Đã rút đơn';
      default:
        return 'Mới ứng tuyển';
    }
  }

  static Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'REVIEWING':
        return const Color(
          0xFFF59E0B,
        );
      case 'ACCEPTED':
        return const Color(
          0xFF16A34A,
        );
      case 'REJECTED':
        return const Color(
          0xFFDC2626,
        );
      case 'WITHDRAWN':
        return Colors.grey;
      default:
        return const Color(
          0xFF2563EB,
        );
    }
  }
}

class _CardSection
    extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        17,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color:
            const Color(
              0xFF64748B,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                  TextStyle(
                    fontSize: 11.5,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar
    extends StatelessWidget {
  const _ActionBar({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
        const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          12,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withValues(
                alpha: 0.06,
              ),
              blurRadius: 14,
              offset:
              const Offset(
                0,
                -4,
              ),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

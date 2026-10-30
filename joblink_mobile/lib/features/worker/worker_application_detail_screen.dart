import 'package:flutter/material.dart';

import '../../services/application_service.dart';

class WorkerApplicationDetailScreen
    extends StatefulWidget {
  const WorkerApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  final String applicationId;

  @override
  State<WorkerApplicationDetailScreen>
  createState() =>
      _WorkerApplicationDetailScreenState();
}

class _WorkerApplicationDetailScreenState
    extends State<WorkerApplicationDetailScreen> {
  final ApplicationService _applicationService =
  ApplicationService();

  Map<String, dynamic>? _application;
  bool _loading = true;
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
      await _applicationService
          .getMyApplicationById(
        widget.applicationId,
      );

      if (!mounted) return;

      setState(() {
        _application = application;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error =
        'Không thể tải chi tiết đơn ứng tuyển';
      });

      debugPrint(
        'Load application detail failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Chi tiết ứng tuyển',
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Thử lại',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final application = _application;

    if (application == null) {
      return const Center(
        child: Text(
          'Không tìm thấy đơn ứng tuyển',
        ),
      );
    }

    final job = _asMap(
      application['job'],
    );

    final employer = _asMap(
      job?['employer'],
    );

    final category = _asMap(
      job?['category'],
    );

    final cv = _asMap(
      application['cv'],
    );

    final status =
        _text(application['status']) ??
            'APPLIED';

    final jobTitle =
        _text(job?['title']) ??
            'Công việc';

    final employerName =
        _text(employer?['companyName']) ??
            'Nhà tuyển dụng';

    final location =
        _text(job?['location']) ??
            _text(job?['address']) ??
            _text(employer?['address']);

    final categoryName =
    _text(category?['name']);

    final note =
    _text(application['note']);

    final appliedAt =
    _formatDate(
      application['appliedAt'] ??
          application['createdAt'],
    );

    final cvName =
        _text(cv?['fileName']) ??
            _text(cv?['name']) ??
            (cv == null
                ? null
                : 'CV đã đính kèm');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(20),
        children: [
          _StatusCard(
            status: status,
          ),
          const SizedBox(height: 14),
          _SectionCard(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFF2563EB,
                        ).withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color:
                        Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(
                      width: 13,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style:
                            const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            employerName,
                            style:
                            TextStyle(
                              color:
                              Colors.grey.shade700,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (location != null) ...[
                  const SizedBox(
                    height: 18,
                  ),
                  _DetailRow(
                    icon:
                    Icons.location_on_outlined,
                    label: 'Địa điểm',
                    value: location,
                  ),
                ],
                if (categoryName != null) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  _DetailRow(
                    icon:
                    Icons.category_outlined,
                    label: 'Danh mục',
                    value: categoryName,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Thông tin ứng tuyển',
            child: Column(
              children: [
                _DetailRow(
                  icon:
                  Icons.info_outline_rounded,
                  label: 'Trạng thái',
                  value:
                  _statusText(status),
                ),
                if (appliedAt != null) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  _DetailRow(
                    icon:
                    Icons.schedule_rounded,
                    label:
                    'Thời gian ứng tuyển',
                    value: appliedAt,
                  ),
                ],
                if (cvName != null) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  _DetailRow(
                    icon:
                    Icons.description_outlined,
                    label: 'CV',
                    value: cvName,
                  ),
                ],
                if (note != null) ...[
                  const SizedBox(
                    height: 12,
                  ),
                  _DetailRow(
                    icon:
                    Icons.notes_rounded,
                    label: 'Ghi chú',
                    value: note,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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

  String? _text(dynamic value) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    return text.isEmpty
        ? null
        : text;
  }

  String? _formatDate(dynamic value) {
    final raw = _text(value);

    if (raw == null) {
      return null;
    }

    final date =
    DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    final local = date.toLocal();

    String two(int number) =>
        number.toString().padLeft(
          2,
          '0',
        );

    return '${two(local.hour)}:${two(local.minute)} '
        '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  String _statusText(String status) {
    switch (status) {
      case 'APPLIED':
        return 'Đã ứng tuyển';
      case 'REVIEWING':
        return 'Đang xem xét';
      case 'ACCEPTED':
        return 'Đã chấp nhận';
      case 'REJECTED':
        return 'Không được chọn';
      case 'WITHDRAWN':
        return 'Đã rút đơn';
      default:
        return status;
    }
  }
}

class _StatusCard
    extends StatelessWidget {
  const _StatusCard({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final data =
    _statusData(status);

    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.color.withValues(
          alpha: 0.09,
        ),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: data.color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            data.icon,
            color: data.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.description,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusData _statusData(
      String status,
      ) {
    switch (status) {
      case 'REVIEWING':
        return const _StatusData(
          color: Color(0xFFF59E0B),
          icon:
          Icons.visibility_outlined,
          title:
          'Hồ sơ đang được xem xét',
          description:
          'Nhà tuyển dụng đang xem hồ sơ của bạn.',
        );

      case 'ACCEPTED':
        return const _StatusData(
          color: Color(0xFF16A34A),
          icon:
          Icons.check_circle_rounded,
          title:
          'Bạn đã được chấp nhận',
          description:
          'Nhà tuyển dụng đã chấp nhận đơn ứng tuyển.',
        );

      case 'REJECTED':
        return const _StatusData(
          color: Color(0xFFDC2626),
          icon:
          Icons.cancel_outlined,
          title:
          'Ứng tuyển chưa được chấp nhận',
          description:
          'Bạn có thể tiếp tục tìm các công việc phù hợp khác.',
        );

      case 'WITHDRAWN':
        return const _StatusData(
          color: Colors.grey,
          icon:
          Icons.remove_circle_outline,
          title: 'Đã rút đơn',
          description:
          'Bạn đã rút đơn ứng tuyển này.',
        );

      default:
        return const _StatusData(
          color: Color(0xFF2563EB),
          icon:
          Icons.send_rounded,
          title: 'Đã ứng tuyển',
          description:
          'Đơn ứng tuyển đã được gửi đến nhà tuyển dụng.',
        );
    }
  }
}

class _StatusData {
  const _StatusData({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;
}

class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
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
          ],
          child,
        ],
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color:
          const Color(0xFF64748B),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color:
                  Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                const TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

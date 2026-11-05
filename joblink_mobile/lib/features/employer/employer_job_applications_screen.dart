import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/employer_application_service.dart';
import 'employer_application_detail_screen.dart';

class EmployerJobApplicationsScreen extends StatefulWidget {
  const EmployerJobApplicationsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  final String jobId;
  final String jobTitle;

  @override
  State<EmployerJobApplicationsScreen> createState() =>
      _EmployerJobApplicationsScreenState();
}

class _EmployerJobApplicationsScreenState
    extends State<EmployerJobApplicationsScreen> {
  final EmployerApplicationService _service = EmployerApplicationService();

  List<Map<String, dynamic>> _applications = [];

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
      final applications = await _service.getJobApplications(
        widget.jobId,
      );

      if (!mounted) return;

      setState(() {
        _applications = applications;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Không thể tải danh sách ứng viên';
      });

      debugPrint('Load employer applications failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =====================================================
  // UC11: TẠO NHÓM CHAT (SELECTED GROUP)
  // =====================================================
  List<Map<String, dynamic>> get _acceptedApplications {
    return _applications.where((app) => app['status'] == 'ACCEPTED').toList();
  }

  Future<void> _createGroupChat() async {
    final acceptedWorkers = _acceptedApplications;
    if (acceptedWorkers.isEmpty) return;

    final nameController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo nhóm làm việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đang tạo nhóm chat cho ${acceptedWorkers.length} ứng viên đã được nhận.'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm (Không bắt buộc)',
                hintText: 'Ví dụ: Nhóm ca tối 18h',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: const Text('Tạo nhóm'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final workerIds = acceptedWorkers.map((app) {
      final worker = _asMap(app['worker']);
      final user = _asMap(worker?['user']);
      return user?['id']?.toString() ?? '';
    }).where((id) => id.isNotEmpty).toList();

    if (workerIds.isEmpty) return;

    try {
      await _service.createSelectedGroup(
        jobId: widget.jobId,
        groupName: nameController.text,
        workerUserIds: workerIds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo nhóm làm việc thành công. Hãy kiểm tra mục Tin nhắn.')),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map) ? data['message']?.toString() : null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Lỗi khi tạo nhóm')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tạo nhóm')),
      );
    }
  }

  // =====================================================
  // HÀM HELPER ASMAP TRONG STATE
  // =====================================================
  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Ứng viên'),
      ),
      floatingActionButton: _acceptedApplications.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _createGroupChat,
        backgroundColor: const Color(0xFF16A34A),
        icon: const Icon(Icons.group_add_rounded, color: Colors.white),
        label: Text(
          'Tạo nhóm (${_acceptedApplications.length})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_applications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có ứng viên',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các ứng viên của "${widget.jobTitle}" sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100), // Dành không gian cho nút FAB
      itemCount: _applications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final application = _applications[index];

        return _CandidateCard(
          application: application,
          onTap: () async {
            final id = application['id']?.toString();

            if (id == null || id.isEmpty) {
              return;
            }

            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployerApplicationDetailScreen(
                  applicationId: id,
                ),
              ),
            );

            if (mounted) {
              await _load();
            }
          },
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.application,
    required this.onTap,
  });

  final Map<String, dynamic> application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final worker = _asMap(application['worker']);
    final user = _asMap(worker?['user']);
    final match = _asMap(application['candidateMatch']);

    final name = _firstText([
      worker?['fullName'],
      worker?['name'],
      user?['email'],
    ]) ??
        'Ứng viên';

    final email = _text(user?['email']);
    final status = _text(application['status']) ?? 'APPLIED';
    final score = _matchScore(match);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.10),
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    if (score != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'AI phù hợp: ${score.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _text(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _text(value);
      if (text != null) {
        return text;
      }
    }
    return null;
  }

  static double? _matchScore(Map<String, dynamic>? match) {
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
      final value = match[key];
      if (value is num) {
        final score = value.toDouble();
        return score <= 1 ? score * 100 : score;
      }
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed <= 1 ? parsed * 100 : parsed;
      }
    }
    return null;
  }

  static String _initials(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        data.$1,
        style: TextStyle(
          color: data.$2,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, Color) _statusData(String status) {
    switch (status) {
      case 'REVIEWING':
        return ('Đang xem', const Color(0xFFF59E0B));
      case 'ACCEPTED':
        return ('Đã nhận', const Color(0xFF16A34A));
      case 'REJECTED':
        return ('Từ chối', const Color(0xFFDC2626));
      case 'WITHDRAWN':
        return ('Đã rút', Colors.grey);
      default:
        return ('Mới', const Color(0xFF2563EB));
    }
  }
}
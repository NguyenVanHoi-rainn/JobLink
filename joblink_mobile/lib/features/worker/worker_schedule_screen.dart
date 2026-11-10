import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/work_appointment.dart';
import '../../services/work_appointment_service.dart';

class WorkerScheduleScreen extends StatefulWidget {
  const WorkerScheduleScreen({super.key, this.refreshTrigger = 0});

  final int refreshTrigger;

  @override
  State<WorkerScheduleScreen> createState() => _WorkerScheduleScreenState();
}

class _WorkerScheduleScreenState extends State<WorkerScheduleScreen> {
  final WorkAppointmentService _service = WorkAppointmentService();

  List<WorkAppointment> _appointments = [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void didUpdateWidget(covariant WorkerScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appointments = await _service.getMyAppointments();
      appointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      if (!mounted) return;
      setState(() => _appointments = appointments);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Không thể tải lịch làm việc. Vui lòng thử lại.');
      debugPrint('Không thể tải lịch làm việc: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(WorkAppointment appointment, {bool ignoreConflict = false}) async {
    setState(() => _busyId = appointment.id);
    try {
      await _service.confirm(
        appointment.id,
        ignoreConflict: ignoreConflict,
      );
      await _loadAppointments();
      if (mounted) {
        _showMessage('Đã xác nhận lịch nhận việc.');
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 409 &&
          _conflictsFrom(error.response?.data).isNotEmpty) {
        if (!mounted) return;
        final conflicts = _conflictsFrom(error.response?.data);
        final proceed = await _showConflictDialog(conflicts);
        if (proceed && mounted) {
          await _confirm(appointment, ignoreConflict: true);
        }
      } else {
        if (mounted) {
          _showMessage(_apiErrorMessage(error, 'Không thể xác nhận lịch.'));
        }
      }
    } catch (error) {
      debugPrint('Không thể xác nhận lịch: $error');
      if (mounted) _showMessage('Không thể xác nhận lịch. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(WorkAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối lịch nhận việc?'),
        content: const Text('Nhà tuyển dụng sẽ nhận được thông báo từ chối lịch này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyId = appointment.id);
    try {
      await _service.decline(appointment.id);
      await _loadAppointments();
      if (mounted) _showMessage('Đã từ chối lịch nhận việc.');
    } on DioException catch (error) {
      if (mounted) _showMessage(_apiErrorMessage(error, 'Không thể từ chối lịch.'));
    } catch (error) {
      debugPrint('Không thể từ chối lịch: $error');
      if (mounted) _showMessage('Không thể từ chối lịch. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<bool> _showConflictDialog(List<Map<String, dynamic>> conflicts) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(child: Text('Lịch làm bị trùng')),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ca mới trùng với lịch bạn đã xác nhận:',
                    ),
                    const SizedBox(height: 12),
                    ...conflicts.map(
                      (conflict) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '• ${conflict['jobTitle'] ?? 'Công việc'}'
                          '${_nonEmpty(conflict['companyName']) ? ' - ${conflict['companyName']}' : ''}\n'
                          '  ${_dayLabel(conflict['day']?.toString())}, '
                          '${conflict['startTime'] ?? '--:--'} - ${conflict['endTime'] ?? '--:--'}',
                        ),
                      ),
                    ),
                    const Text(
                      'Bạn vẫn có thể xác nhận nếu muốn tiếp tục chịu trách nhiệm cho cả hai lịch.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Quay lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vẫn xác nhận'),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<Map<String, dynamic>> _conflictsFrom(dynamic data) {
    if (data is! Map || data['conflicts'] is! List) return const [];
    return (data['conflicts'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _apiErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }

  bool _nonEmpty(dynamic value) => value is String && value.isNotEmpty;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final active = _appointments
        .where((item) => item.isConfirmed || (item.isPending && item.isUpcoming))
        .toList();
    final history = _appointments
        .where((item) => !active.contains(item))
        .toList()
        .reversed
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 6),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Lịch làm việc',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Theo dõi lịch nhận việc, ca làm đã xác nhận và địa điểm làm việc.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
            if (_loading && _appointments.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _appointments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ScheduleMessage(
                  icon: Icons.cloud_off_outlined,
                  message: _error!,
                  actionLabel: 'Thử lại',
                  onAction: _loadAppointments,
                ),
              )
            else if (_appointments.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _ScheduleMessage(
                  icon: Icons.event_available_outlined,
                  message: 'Chưa có lịch nhận việc nào.',
                  detail: 'Khi nhà tuyển dụng gửi lịch, thông tin sẽ xuất hiện tại đây.',
                ),
              )
            else ...[
              _sectionTitle('LỊCH SẮP TỚI', active.length),
              if (active.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 22),
                    child: Text(
                      'Bạn chưa có lịch sắp tới.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: active.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _AppointmentCard(
                      appointment: active[index],
                      busy: _busyId == active[index].id,
                      onConfirm: () => _confirm(active[index]),
                      onDecline: () => _decline(active[index]),
                    ),
                  ),
                ),
              if (history.isNotEmpty) ...[
                _sectionTitle('LỊCH SỬ', history.length),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _AppointmentCard(
                      appointment: history[index],
                      compact: true,
                    ),
                  ),
                ),
              ],
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionTitle(String title, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 7),
            CircleAvatar(
              radius: 11,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    this.busy = false,
    this.compact = false,
    this.onConfirm,
    this.onDecline,
  });

  final WorkAppointment appointment;
  final bool busy;
  final bool compact;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final pending = appointment.isPending;
    final statusColor = pending
        ? const Color(0xFFB45309)
        : appointment.isConfirmed
            ? const Color(0xFF15803D)
            : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(date: appointment.appointmentDate),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.jobTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appointment.companyName,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(appointment.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _InfoLine(
            icon: Icons.repeat_rounded,
            text: _weeklySchedule(appointment),
          ),
          const SizedBox(height: 9),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: appointment.location.isEmpty ? 'Chưa cập nhật địa điểm' : appointment.location,
          ),
          if (appointment.instruction?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 9),
            _InfoLine(
              icon: Icons.notes_rounded,
              text: appointment.instruction!.trim(),
            ),
          ],
          if (pending && !compact) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onDecline,
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onConfirm,
                    child: busy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _weeklySchedule(WorkAppointment value) {
    final days = value.workDays.map(_dayLabel).join(', ');
    final time = value.startTime != null && value.endTime != null
        ? '${value.startTime} - ${value.endTime}'
        : 'Chưa cập nhật giờ ca';
    return '${days.isEmpty ? 'Chưa cập nhật ngày làm' : days} · $time';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'CHỜ XÁC NHẬN';
      case 'CONFIRMED':
        return 'ĐÃ XÁC NHẬN';
      case 'DECLINED':
        return 'ĐÃ TỪ CHỐI';
      case 'CANCELLED':
        return 'ĐÃ HỦY';
      default:
        return status;
    }
  }

  String _dayLabel(String value) {
    const labels = {
      'MONDAY': 'Thứ 2',
      'TUESDAY': 'Thứ 3',
      'WEDNESDAY': 'Thứ 4',
      'THURSDAY': 'Thứ 5',
      'FRIDAY': 'Thứ 6',
      'SATURDAY': 'Thứ 7',
      'SUNDAY': 'Chủ nhật',
    };
    return labels[value] ?? value;
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    const months = [
      'THG 1',
      'THG 2',
      'THG 3',
      'THG 4',
      'THG 5',
      'THG 6',
      'THG 7',
      'THG 8',
      'THG 9',
      'THG 10',
      'THG 11',
      'THG 12',
    ];

    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            months[date.month - 1],
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${date.day}',
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          Text(
            '${date.year}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF334155), height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _ScheduleMessage extends StatelessWidget {
  const _ScheduleMessage({
    required this.icon,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _dayLabel(String? value) {
  const labels = {
    'MONDAY': 'Thứ 2',
    'TUESDAY': 'Thứ 3',
    'WEDNESDAY': 'Thứ 4',
    'THURSDAY': 'Thứ 5',
    'FRIDAY': 'Thứ 6',
    'SATURDAY': 'Thứ 7',
    'SUNDAY': 'Chủ nhật',
  };
  return labels[value] ?? value ?? 'Ngày chưa rõ';
}

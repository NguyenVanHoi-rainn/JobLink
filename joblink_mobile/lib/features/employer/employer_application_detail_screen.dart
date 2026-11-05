import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/chat_conversation.dart';
import '../../services/employer_application_service.dart';
import '../worker/chat_screen.dart';

class EmployerApplicationDetailScreen extends StatefulWidget {
  const EmployerApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  final String applicationId;

  @override
  State<EmployerApplicationDetailScreen> createState() =>
      _EmployerApplicationDetailScreenState();
}

class _EmployerApplicationDetailScreenState
    extends State<EmployerApplicationDetailScreen> {
  static const Color _primary = Color(0xFF2563EB);
  static const Color _aiColor = Color(0xFF7C3AED);

  final EmployerApplicationService _service = EmployerApplicationService();

  Map<String, dynamic>? _application;
  bool _loading = true;
  bool _updatingStatus = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getApplicationDetail(widget.applicationId);
      if (!mounted) return;
      setState(() {
        _application = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải chi tiết đơn ứng tuyển';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_updatingStatus) return;
    setState(() => _updatingStatus = true);

    try {
      await _service.updateApplicationStatus(
        applicationId: widget.applicationId,
        status: newStatus,
      );
      if (!mounted) return;
      _showMessage(
        newStatus == 'REVIEWING'
            ? 'Đã chuyển sang xem xét'
            : newStatus == 'ACCEPTED'
            ? 'Đã chấp nhận ứng viên'
            : 'Đã từ chối ứng viên',
      );
      await _load();
    } on DioException catch (e) {
      _showMessage(_dioMessage(e) ?? 'Cập nhật trạng thái thất bại');
    } catch (_) {
      _showMessage('Lỗi cập nhật');
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _startChat(String targetUserId) async {
    try {
      final conversationData = await _service.createPrivateChat(targetUserId);
      if (!mounted) return;

      final conversation = ChatConversation.fromJson(conversationData);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } on DioException catch (e) {
      _showMessage(_dioMessage(e) ?? 'Không thể mở cuộc trò chuyện');
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is List) return msg.join(', ');
      return msg?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final app = _application;
    final worker = app?['worker'] as Map<String, dynamic>?;
    final user = worker?['user'] as Map<String, dynamic>?;

    final fullName = worker?['fullName']?.toString() ?? 'Ứng viên';
    final email = user?['email']?.toString() ?? '';
    final phone = worker?['phone']?.toString();
    final bio = worker?['bio']?.toString();
    final searchArea = worker?['searchArea']?.toString();
    final status = app?['status']?.toString() ?? 'APPLIED';
    final note = app?['note']?.toString();

    // CV
    final cv = app?['cv'] as Map<String, dynamic>?;
    final cvUrl = cv?['fileUrl']?.toString();
    final cvName = cv?['fileName']?.toString();

    // AI Match
    final match = app?['candidateMatch'] as Map<String, dynamic>?;
    final rawScore = match?['matchingScore'] ?? match?['score'];
    final score = rawScore is num ? rawScore.round() : null;
    final reasons = (match?['reasons'] as List<dynamic>?) ?? [];

    // Kỹ năng & Lịch rảnh
    final skills = (worker?['workerSkills'] as List<dynamic>?) ?? [];
    final availabilities = (worker?['availabilities'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Chi tiết ứng viên',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: [
          // Card thông tin ứng viên
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person_rounded,
                        color: _primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (phone != null && phone.isNotEmpty)
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statusBadge(status),
                    const Spacer(),
                    if (user?['id'] != null)
                      OutlinedButton.icon(
                        onPressed: () => _startChat(user!['id'].toString()),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Nhắn tin'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card AI Match
          if (score != null) ...[
            _card(
              borderColor: _aiColor.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: _aiColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Đánh giá AI Candidate Matching',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _aiColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _aiColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$score%',
                          style: const TextStyle(
                            color: _aiColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chi tiết phân tích:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (reasons.isEmpty)
                    const Text('Hồ sơ đáp ứng các tiêu chuẩn cơ bản.')
                  else
                    ...reasons.map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: _aiColor)),
                          Expanded(child: Text(r.toString(), style: const TextStyle(height: 1.35))),
                        ],
                      ),
                    )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lời nhắn & Vị trí
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin bổ sung',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (searchArea != null && searchArea.isNotEmpty) ...[
                  _infoRow(Icons.location_on_outlined, 'Khu vực mong muốn', searchArea),
                  const SizedBox(height: 10),
                ],
                if (bio != null && bio.isNotEmpty) ...[
                  _infoRow(Icons.info_outline, 'Giới thiệu bản thân', bio),
                  const SizedBox(height: 10),
                ],
                if (note != null && note.isNotEmpty)
                  _infoRow(Icons.chat_outlined, 'Lời nhắn ứng tuyển', note),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Kỹ năng
          if (skills.isNotEmpty) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kỹ năng của ứng viên',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((s) {
                      final skillMap = s['skill'] as Map<String, dynamic>?;
                      final name = skillMap?['name']?.toString() ?? 'Kỹ năng';
                      return Chip(label: Text(name));
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Ca làm rảnh
          if (availabilities.isNotEmpty) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian có thể làm việc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...availabilities.map((a) {
                    final day = _dayString(a['dayOfWeek']?.toString() ?? '');
                    final start = _formatTime(a['startTime']);
                    final end = _formatTime(a['endTime']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('$day: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('$start - $end'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // File CV đính kèm
          if (cvUrl != null)
            _card(
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cvName ?? 'CV Ứng viên',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text('Định dạng PDF đính kèm', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final fullUrl = _service.resolveFileUrl(cvUrl);
                      final uri = Uri.parse(fullUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        _showMessage('Không thể mở file CV');
                      }
                    },
                    child: const Text('Xem CV'),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: _buildActionButtons(status),
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (_updatingStatus) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (status == 'APPLIED') {
      return SizedBox(
        height: 48,
        child: FilledButton.tonal(
          onPressed: () => _changeStatus('REVIEWING'),
          child: const Text('Bắt đầu xem xét hồ sơ'),
        ),
      );
    }

    if (status == 'REVIEWING') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _changeStatus('REJECTED'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Từ chối'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => _changeStatus('ACCEPTED'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Chấp nhận'),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 44,
      alignment: Alignment.center,
      child: Text(
        status == 'ACCEPTED'
            ? 'Đã duyệt chấp nhận ứng viên này.'
            : 'Đơn ứng tuyển đã kết thúc xét duyệt.',
        style: TextStyle(
          color: status == 'ACCEPTED' ? const Color(0xFF16A34A) : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'REVIEWING' => ('Đang xem xét', const Color(0xFFF59E0B)),
      'ACCEPTED' => ('Đã nhận', const Color(0xFF16A34A)),
      'REJECTED' => ('Từ chối', const Color(0xFFDC2626)),
      'WITHDRAWN' => ('Đã rút đơn', Colors.grey),
      _ => ('Mới nộp', _primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  String _dayString(String day) {
    switch (day) {
      case 'MONDAY': return 'Thứ 2';
      case 'TUESDAY': return 'Thứ 3';
      case 'WEDNESDAY': return 'Thứ 4';
      case 'THURSDAY': return 'Thứ 5';
      case 'FRIDAY': return 'Thứ 6';
      case 'SATURDAY': return 'Thứ 7';
      case 'SUNDAY': return 'Chủ nhật';
      default: return day;
    }
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null) return '';
    final text = timeValue.toString();
    final match = RegExp(r'T?(\d{2}:\d{2})').firstMatch(text);
    return match != null ? match.group(1)! : text;
  }
}
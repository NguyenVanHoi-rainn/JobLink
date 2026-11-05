import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/application_service.dart';

class WorkerApplicationDetailScreen extends StatefulWidget {
  const WorkerApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  final String applicationId;

  @override
  State<WorkerApplicationDetailScreen> createState() =>
      _WorkerApplicationDetailScreenState();
}

class _WorkerApplicationDetailScreenState
    extends State<WorkerApplicationDetailScreen> {
  static const Color _primary = Color(0xFF2563EB);

  final ApplicationService _service = ApplicationService();

  Map<String, dynamic>? _application;
  bool _loading = true;
  bool _withdrawing = false;
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
      final data = await _service.getMyApplicationById(widget.applicationId);
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

  Future<void> _withdraw() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rút đơn ứng tuyển'),
        content: const Text(
            'Bạn có chắc muốn rút đơn không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rút đơn'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _withdrawing = true);

    try {
      await _service.withdrawApplication(widget.applicationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã rút đơn ứng tuyển thành công')),
      );
      await _load();
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? e.response?.data['message']?.toString()
          : null;
      _showMessage(msg ?? 'Lỗi khi rút đơn');
    } catch (_) {
      _showMessage('Không thể rút đơn');
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final app = _application;
    final job = app?['job'] as Map<String, dynamic>?;
    final employer = job?['employer'] as Map<String, dynamic>?;

    final jobTitle = job?['title']?.toString() ?? 'Chi tiết công việc';
    final companyName = employer?['companyName']?.toString() ?? 'Nhà tuyển dụng';
    final status = app?['status']?.toString() ?? 'APPLIED';
    final note = app?['note']?.toString();
    final applyDate = app?['createdAt']?.toString();

    final cv = app?['cv'] as Map<String, dynamic>?;
    final cvUrl = cv?['fileUrl']?.toString();
    final cvName = cv?['fileName']?.toString();

    final canWithdraw = status == 'APPLIED' || status == 'REVIEWING';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Chi tiết ứng tuyển', style: TextStyle(fontWeight: FontWeight.w700)),
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
            OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.work_rounded, color: _primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            companyName,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                    if (applyDate != null)
                      Text(
                        'Nộp ngày: ${_formatDate(applyDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lời nhắn
          if (note != null && note.isNotEmpty) ...[
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lời nhắn của bạn', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(note, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // CV
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
                          cvName ?? 'CV đính kèm',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text('Đã đính kèm khi ứng tuyển', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

          const SizedBox(height: 32),

          // Rút đơn button
          if (canWithdraw)
            _withdrawing
                ? const Center(child: CircularProgressIndicator())
                : OutlinedButton.icon(
              onPressed: _withdraw,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Rút đơn ứng tuyển'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'APPLIED' => ('Chờ duyệt', _primary),
      'REVIEWING' => ('Đang xem xét', const Color(0xFFF59E0B)),
      'ACCEPTED' => ('Đã nhận', const Color(0xFF16A34A)),
      'REJECTED' => ('Bị từ chối', const Color(0xFFDC2626)),
      'WITHDRAWN' => ('Đã rút đơn', Colors.grey),
      _ => ('Không xác định', Colors.grey),
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

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate);
    if (date == null) return rawDate;
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
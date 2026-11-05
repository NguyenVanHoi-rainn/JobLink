import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/job_service.dart';
import 'job_detail_screen.dart';
import '../../models/job.dart';

class WorkerSavedJobsScreen extends StatefulWidget {
  const WorkerSavedJobsScreen({super.key});

  @override
  State<WorkerSavedJobsScreen> createState() => _WorkerSavedJobsScreenState();
}

class _WorkerSavedJobsScreenState extends State<WorkerSavedJobsScreen> {
  static const Color _primary = Color(0xFF2563EB);

  final JobService _service = JobService();

  List<Map<String, dynamic>> _savedRecords = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
  }

  Future<void> _loadSavedJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final records = await _service.getSavedJobs();
      if (!mounted) return;
      setState(() {
        _savedRecords = records;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _dioMessage(e) ?? 'Không thể tải danh sách việc làm đã lưu';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Đã xảy ra lỗi khi tải dữ liệu';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unsaveJob(String jobId, int index) async {
    try {
      await _service.unsaveJob(jobId);

      if (!mounted) return;
      setState(() {
        _savedRecords.removeAt(index);
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Đã bỏ lưu công việc')));
    } on DioException catch (e) {
      _showMessage(_dioMessage(e) ?? 'Không thể bỏ lưu lúc này');
    } catch (_) {
      _showMessage('Lỗi khi bỏ lưu công việc');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Việc làm đã lưu', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadSavedJobs,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_savedRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_border_rounded, size: 40, color: Colors.red),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chưa lưu việc làm nào',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Các công việc bạn quan tâm và lưu lại sẽ được hiển thị tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavedJobs,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _savedRecords.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final record = _savedRecords[index];
          final job = record['job'] as Map<String, dynamic>? ?? record;

          final id = job['id']?.toString() ?? '';
          if (id.isEmpty) return const SizedBox.shrink();

          final title = job['title']?.toString() ?? 'Tên công việc';
          final company = job['employer']?['companyName']?.toString() ?? 'Nhà tuyển dụng';
          final location = job['location']?.toString();

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JobDetailScreen(job: Job.fromJson(job))),
                );
                if (mounted) _loadSavedJobs();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work_rounded, color: _primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (location != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                      onPressed: () => _unsaveJob(id, index),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
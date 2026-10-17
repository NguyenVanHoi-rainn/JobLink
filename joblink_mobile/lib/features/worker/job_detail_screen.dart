import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/job.dart';
import '../../services/job_service.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.job,
  });

  final Job job;

  @override
  State<JobDetailScreen> createState() =>
      _JobDetailScreenState();
}

class _JobDetailScreenState
    extends State<JobDetailScreen> {
  static const primaryColor =
  Color(0xFF2563EB);

  final JobService _jobService =
  JobService();

  bool _loadingState = true;
  bool _applying = false;
  bool _saving = false;

  bool _isSaved = false;
  bool _alreadyApplied = false;

  List<Map<String, dynamic>> _cvs = [];

  Job get job => widget.job;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final saved =
      await _jobService.isJobSaved(
        job.id,
      );

      final applied =
      await _jobService.hasApplied(
        job.id,
      );

      List<Map<String, dynamic>> cvs =
      [];

      if (job.cvRequired) {
        cvs =
        await _jobService.getMyCvs();
      }

      if (!mounted) return;

      setState(() {
        _isSaved = saved;
        _alreadyApplied = applied;
        _cvs = cvs;
      });
    } catch (_) {
      // Không chặn việc xem chi tiết nếu
      // kiểm tra trạng thái phụ bị lỗi.
    } finally {
      if (mounted) {
        setState(() {
          _loadingState = false;
        });
      }
    }
  }

  Future<void> _toggleSaved() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      if (_isSaved) {
        await _jobService.unsaveJob(
          job.id,
        );
      } else {
        await _jobService.saveJob(
          job.id,
        );
      }

      if (!mounted) return;

      setState(() {
        _isSaved = !_isSaved;
      });

      _showMessage(
        _isSaved
            ? 'Đã lưu công việc'
            : 'Đã bỏ lưu công việc',
      );
    } on DioException catch (e) {
      _showMessage(
        _dioMessage(
          e,
          'Không thể cập nhật việc đã lưu',
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<String?> _selectCv() async {
    if (_cvs.isEmpty) {
      return null;
    }

    if (_cvs.length == 1) {
      return _cvs.first['id']?.toString();
    }

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn CV ứng tuyển',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ..._cvs.map(
                      (cv) {
                    final id =
                    cv['id']?.toString();

                    final name =
                        cv['fileName']
                            ?.toString() ??
                            'CV';

                    return ListTile(
                      contentPadding:
                      EdgeInsets.zero,
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration:
                        BoxDecoration(
                          color: primaryColor
                              .withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .picture_as_pdf_outlined,
                          color:
                          primaryColor,
                        ),
                      ),
                      title: Text(name),
                      trailing: const Icon(
                        Icons
                            .chevron_right_rounded,
                      ),
                      onTap: id == null
                          ? null
                          : () {
                        Navigator.pop(
                          context,
                          id,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _apply() async {
    if (_applying ||
        _alreadyApplied) {
      return;
    }

    String? cvId;

    if (job.cvRequired) {
      if (_cvs.isEmpty) {
        _showMessage(
          'Công việc này yêu cầu CV. '
              'Hãy tải CV trong Hồ sơ trước khi ứng tuyển.',
          error: true,
        );

        return;
      }

      cvId = await _selectCv();

      if (!mounted) {
        return;
      }

      if (cvId == null) {
        return;
      }
    }

    final noteController =
    TextEditingController();

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Xác nhận ứng tuyển',
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                job.employerName ??
                    'Nhà tuyển dụng',
              ),
              const SizedBox(height: 18),
              TextField(
                controller:
                noteController,
                maxLines: 3,
                decoration:
                const InputDecoration(
                  labelText:
                  'Lời nhắn (không bắt buộc)',
                  hintText:
                  'Giới thiệu ngắn với nhà tuyển dụng...',
                  border:
                  OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Ứng tuyển',
              ),
            ),
          ],
        );
      },
    );

    final note =
        noteController.text;

    noteController.dispose();

    if (confirmed != true) {
      return;
    }

    setState(() {
      _applying = true;
    });

    try {
      await _jobService.applyToJob(
        jobId: job.id,
        cvId: cvId,
        note: note,
      );

      if (!mounted) return;

      setState(() {
        _alreadyApplied = true;
      });

      _showMessage(
        'Ứng tuyển thành công!',
      );
    } on DioException catch (e) {
      _showMessage(
        _dioMessage(
          e,
          'Ứng tuyển thất bại',
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _applying = false;
        });
      }
    }
  }

  String _dioMessage(
      DioException e,
      String fallback,
      ) {
    final data = e.response?.data;

    if (data is Map) {
      final raw = data['message'];

      if (raw is List) {
        return raw.join('\n');
      }

      if (raw != null) {
        return raw.toString();
      }
    }

    return fallback;
  }

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor: error
              ? Colors.red.shade700
              : null,
        ),
      );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFFF5F7FB),
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
            _saving ? null : _toggleSaved,
            icon: _saving
                ? const SizedBox(
              width: 21,
              height: 21,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : Icon(
              _isSaved
                  ? Icons
                  .bookmark_rounded
                  : Icons
                  .bookmark_border_rounded,
              color: _isSaved
                  ? primaryColor
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          120,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _HeaderCard(job: job),
            const SizedBox(height: 18),

            _SectionCard(
              title: 'Thông tin công việc',
              child: Column(
                children: [
                  _DetailRow(
                    icon:
                    Icons.payments_outlined,
                    label: 'Mức lương',
                    value: job.salaryText,
                  ),
                  _DetailRow(
                    icon: Icons
                        .location_on_outlined,
                    label: 'Địa điểm',
                    value: job.location ??
                        'Chưa cập nhật',
                  ),
                  _DetailRow(
                    icon: Icons
                        .calendar_month_outlined,
                    label:
                    'Hạn ứng tuyển',
                    value:
                    job.deadlineText,
                  ),
                  _DetailRow(
                    icon: Icons
                        .description_outlined,
                    label: 'CV',
                    value: job.cvRequired
                        ? 'Bắt buộc'
                        : 'Không bắt buộc',
                    last: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _SectionCard(
              title: 'Mô tả công việc',
              child: Text(
                job.description
                    ?.trim()
                    .isNotEmpty ==
                    true
                    ? job.description!
                    : 'Nhà tuyển dụng chưa cập nhật mô tả.',
                style: TextStyle(
                  color:
                  Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ),

            if (job.skills.isNotEmpty) ...[
              const SizedBox(height: 18),
              _SectionCard(
                title:
                'Kỹ năng yêu cầu',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.skills
                      .map(
                        (skill) =>
                        _SkillChip(
                          text: skill,
                        ),
                  )
                      .toList(),
                ),
              ),
            ],

            if (job.categoryName !=
                null) ...[
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Danh mục',
                child: _SkillChip(
                  text:
                  job.categoryName!,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.06,
                ),
                blurRadius: 18,
                offset:
                const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
              _loadingState ||
                  _applying ||
                  _alreadyApplied
                  ? null
                  : _apply,
              style:
              FilledButton.styleFrom(
                backgroundColor:
                primaryColor,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              icon: _applying
                  ? const SizedBox(
                width: 21,
                height: 21,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                _alreadyApplied
                    ? Icons
                    .check_circle_outline_rounded
                    : Icons
                    .send_rounded,
              ),
              label: Text(
                _alreadyApplied
                    ? 'Đã ứng tuyển'
                    : job.cvRequired
                    ? 'Ứng tuyển bằng CV'
                    : 'Ứng tuyển ngay',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard
    extends StatelessWidget {
  const _HeaderCard({
    required this.job,
  });

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFF2563EB)
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons
                      .business_center_rounded,
                  color:
                  Color(0xFF2563EB),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.employerName ??
                          'Nhà tuyển dụng',
                      style: TextStyle(
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons
                    .location_on_outlined,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job.location ??
                      'Chưa cập nhật địa điểm',
                  style: TextStyle(
                    color:
                    Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.salaryText,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
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
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: last ? 0 : 15,
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color:
              const Color(0xFF2563EB)
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
              const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w600,
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

class _SkillChip
    extends StatelessWidget {
  const _SkillChip({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB)
            .withValues(
          alpha: 0.07,
        ),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
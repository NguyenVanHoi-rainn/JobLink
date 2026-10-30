import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/employer_job_service.dart';

import 'employer_edit_job_screen.dart';
import 'employer_job_applications_screen.dart';

class EmployerJobDetailScreen
    extends StatefulWidget {
  const EmployerJobDetailScreen({
    super.key,
    required this.jobId,
  });

  final String jobId;

  @override
  State<EmployerJobDetailScreen>
  createState() =>
      _EmployerJobDetailScreenState();
}

class _EmployerJobDetailScreenState
    extends State<EmployerJobDetailScreen> {
  static const Color _primary =
  Color(0xFF2563EB);

  final EmployerJobService _service =
  EmployerJobService();

  Map<String, dynamic>? _job;

  bool _loading = true;
  bool _processing = false;

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
      final job =
      await _service
          .getMyJobById(
        widget.jobId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _job = job;
      });
    } catch (error) {
      debugPrint(
        'Load employer job detail failed: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Không thể tải chi tiết tin tuyển dụng';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _edit() async {
    final changed =
    await Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EmployerEditJobScreen(
              jobId:
              widget.jobId,
            ),
      ),
    );

    if (changed == true &&
        mounted) {
      await _load();
    }
  }

  Future<void>
  _openApplications() async {
    final job =
        _job;

    if (job == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EmployerJobApplicationsScreen(
              jobId:
              widget.jobId,
              jobTitle:
              job['title']
                  ?.toString() ??
                  'Tin tuyển dụng',
            ),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  Future<void>
  _runStatusAction() async {
    final job =
        _job;

    if (job == null ||
        _processing) {
      return;
    }

    final status =
        job['status']
            ?.toString() ??
            '';

    String message;

    switch (status) {
      case 'DRAFT':
        message =
        'Bạn muốn đăng tin tuyển dụng này?';
        break;

      case 'PUBLISHED':
        message =
        'Bạn muốn đóng tin tuyển dụng này?';
        break;

      case 'CLOSED':
        message =
        'Bạn muốn đăng lại tin tuyển dụng này?';
        break;

      default:
        return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder:
          (context) =>
          AlertDialog(
            title:
            const Text(
              'Xác nhận',
            ),
            content:
            Text(
              message,
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
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
                onPressed:
                    () =>
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
      _processing = true;
    });

    try {
      if (status ==
          'DRAFT') {
        await _service.publishJob(
          widget.jobId,
        );

        _showMessage(
          'Đăng tin thành công',
        );
      } else if (status ==
          'PUBLISHED') {
        await _service.closeJob(
          widget.jobId,
        );

        _showMessage(
          'Đã đóng tin tuyển dụng',
        );
      } else if (status ==
          'CLOSED') {
        await _service.republishJob(
          widget.jobId,
        );

        _showMessage(
          'Đăng lại tin thành công',
        );
      }

      await _load();
    } on DioException catch (error) {
      _showMessage(
        _dioMessage(
          error,
        ) ??
            'Không thể cập nhật trạng thái tin',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String? _dioMessage(
      DioException error,
      ) {
    final data =
        error.response?.data;

    if (data is Map) {
      final message =
      data['message'];

      if (message is List) {
        return message.join(
          ', ',
        );
      }

      return message?.toString();
    }

    return null;
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          content:
          Text(
            message,
          ),
        ),
      );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final job =
        _job;

    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F7FB,
      ),
      appBar:
      AppBar(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        title:
        const Text(
          'Chi tiết tin',
          style:
          TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        actions: [
          if (job != null &&
              job['status']
                  ?.toString() !=
                  'HIDDEN')
            IconButton(
              tooltip:
              'Sửa tin',
              onPressed:
              _edit,
              icon:
              const Icon(
                Icons.edit_outlined,
              ),
            ),
        ],
      ),
      body:
      _buildBody(),
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
                size: 48,
                color:
                Colors.redAccent,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _error!,
              ),
              const SizedBox(
                height: 14,
              ),
              OutlinedButton.icon(
                onPressed:
                _load,
                icon:
                const Icon(
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

    final job =
        _job;

    if (job == null) {
      return const Center(
        child:
        Text(
          'Không tìm thấy tin tuyển dụng',
        ),
      );
    }

    final status =
        job['status']
            ?.toString() ??
            'DRAFT';

    final category =
    _asMap(
      job['category'],
    );

    final count =
    _asMap(
      job['_count'],
    );

    final applicantCount =
        int.tryParse(
          count?['applications']
              ?.toString() ??
              '0',
        ) ??
            0;

    final jobSkills =
    job['jobSkills'];

    final skills =
    <String>[];

    if (jobSkills is List) {
      for (final item
      in jobSkills) {
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
        skill?['name']
            ?.toString();

        if (name != null &&
            name.isNotEmpty) {
          skills.add(
            name,
          );
        }
      }
    }

    final deadline =
    _formatDateTime(
      job['deadline'],
    );

    final statusData =
    _statusData(
      status,
    );

    return RefreshIndicator(
      onRefresh:
      _load,
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
          Container(
            padding:
            const EdgeInsets.all(
              18,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration:
                      BoxDecoration(
                        color:
                        _primary
                            .withValues(
                          alpha:
                          0.09,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                      ),
                      child:
                      const Icon(
                        Icons
                            .work_rounded,
                        color:
                        _primary,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            job['title']
                                ?.toString() ??
                                'Tin tuyển dụng',
                            style:
                            const TextStyle(
                              fontSize:
                              20,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            category?['name']
                                ?.toString() ??
                                'Chưa có danh mục',
                            style:
                            TextStyle(
                              color:
                              Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 15,
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    10,
                    vertical:
                    6,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    statusData.$2
                        .withValues(
                      alpha:
                      0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child:
                  Text(
                    statusData.$1,
                    style:
                    TextStyle(
                      color:
                      statusData.$2,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _section(
            title:
            'Thông tin',
            children: [
              _infoRow(
                Icons
                    .payments_outlined,
                'Mức lương',
                '${_formatMoney(job['salary'])} VNĐ',
              ),

              _infoRow(
                Icons
                    .location_on_outlined,
                'Địa điểm',
                job['location']
                    ?.toString() ??
                    'Chưa cập nhật',
              ),

              _infoRow(
                Icons
                    .description_outlined,
                'Mô tả',
                job['description']
                    ?.toString() ??
                    '',
              ),

              _infoRow(
                Icons
                    .description_rounded,
                'CV',
                job['cvRequired'] ==
                    true
                    ? 'Bắt buộc'
                    : 'Không bắt buộc',
              ),

              _infoRow(
                Icons
                    .event_outlined,
                'Hạn ứng tuyển',
                deadline ??
                    'Không đặt hạn',
              ),
            ],
          ),

          if (skills.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),

            _section(
              title:
              'Kỹ năng yêu cầu',
              children: [
                Wrap(
                  spacing:
                  8,
                  runSpacing:
                  8,
                  children:
                  skills
                      .map(
                        (skill) =>
                        Chip(
                          label:
                          Text(
                            skill,
                          ),
                        ),
                  )
                      .toList(),
                ),
              ],
            ),
          ],

          const SizedBox(
            height: 14,
          ),

          Container(
            padding:
            const EdgeInsets.all(
              17,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .groups_outlined,
                  color:
                  _primary,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                  Text(
                    '$applicantCount ứng viên đã ứng tuyển',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed:
                  _openApplications,
                  child:
                  const Text(
                    'Xem',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          if (status ==
              'DRAFT' ||
              status ==
                  'PUBLISHED' ||
              status ==
                  'CLOSED')
            FilledButton.icon(
              onPressed:
              _processing
                  ? null
                  : _runStatusAction,
              style:
              FilledButton.styleFrom(
                minimumSize:
                const Size(
                  0,
                  54,
                ),
                backgroundColor:
                status ==
                    'PUBLISHED'
                    ? const Color(
                  0xFFDC2626,
                )
                    : _primary,
              ),
              icon:
              _processing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  Colors.white,
                ),
              )
                  : Icon(
                status ==
                    'DRAFT'
                    ? Icons
                    .publish_rounded
                    : status ==
                    'PUBLISHED'
                    ? Icons
                    .stop_circle_outlined
                    : Icons
                    .replay_rounded,
              ),
              label:
              Text(
                status ==
                    'DRAFT'
                    ? 'Đăng tin'
                    : status ==
                    'PUBLISHED'
                    ? 'Đóng tin'
                    : 'Đăng lại',
              ),
            ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        17,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
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

  Widget _infoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
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
                    color:
                    Colors
                        .grey
                        .shade600,
                    fontSize:
                    11.5,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                    height:
                    1.4,
                  ),
                ),
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

  String? _formatDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final date =
    DateTime.tryParse(
      value.toString(),
    )?.toLocal();

    if (date == null) {
      return null;
    }

    String two(
        int value,
        ) {
      return value
          .toString()
          .padLeft(
        2,
        '0',
      );
    }

    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _formatMoney(
      dynamic value,
      ) {
    final number =
    double.tryParse(
      value?.toString() ?? '',
    );

    if (number == null) {
      return value?.toString() ??
          '0';
    }

    final text =
    number
        .round()
        .toString();

    final buffer =
    StringBuffer();

    for (var i = 0;
    i < text.length;
    i++) {
      final remaining =
          text.length - i;

      buffer.write(
        text[i],
      );

      if (remaining > 1 &&
          remaining % 3 == 1) {
        buffer.write(
          '.',
        );
      }
    }

    return buffer.toString();
  }

  (String, Color) _statusData(
      String status,
      ) {
    switch (status) {
      case 'PUBLISHED':
        return (
        'Đang đăng',
        const Color(
          0xFF16A34A,
        ),
        );

      case 'CLOSED':
        return (
        'Đã đóng',
        Colors.grey,
        );

      case 'HIDDEN':
        return (
        'Admin đã ẩn',
        const Color(
          0xFFDC2626,
        ),
        );

      default:
        return (
        'Bản nháp',
        const Color(
          0xFFF59E0B,
        ),
        );
    }
  }
}
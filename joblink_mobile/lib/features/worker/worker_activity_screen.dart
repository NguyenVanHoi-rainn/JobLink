import 'package:flutter/material.dart';

import '../../models/application.dart';
import '../../services/application_service.dart';

class WorkerActivityScreen
    extends StatefulWidget {
  const WorkerActivityScreen({
    super.key,
  });

  @override
  State<WorkerActivityScreen>
  createState() =>
      _WorkerActivityScreenState();
}

class _WorkerActivityScreenState
    extends State<WorkerActivityScreen> {
  final ApplicationService
  _applicationService =
  ApplicationService();

  List<JobApplication> _applications =
  [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final applications =
      await _applicationService
          .getMyApplications();

      if (!mounted) return;

      setState(() {
        _applications = applications;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
        'Không thể tải danh sách ứng tuyển';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadApplications,
        child: CustomScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverPadding(
              padding:
              EdgeInsets.fromLTRB(
                20,
                20,
                20,
                6,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Hoạt động',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                18,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Theo dõi các công việc bạn đã ứng tuyển.',
                  style: TextStyle(
                    color:
                    Colors.grey.shade600,
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorView(
                  message: _error!,
                  onRetry:
                  _loadApplications,
                ),
              )
            else if (_applications.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(),
                )
              else
                SliverPadding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    28,
                  ),
                  sliver: SliverList.separated(
                    itemCount:
                    _applications.length,
                    separatorBuilder:
                        (_, _) =>
                    const SizedBox(
                      height: 12,
                    ),
                    itemBuilder:
                        (context, index) {
                      return _ApplicationCard(
                        application:
                        _applications[
                        index],
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard
    extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
  });

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final job = application.job;

    final statusColor =
    _statusColor(
      application.status,
    );

    return Container(
      padding: const EdgeInsets.all(17),
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
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFF2563EB)
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color:
                  Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      job?.title ??
                          'Công việc',
                      style:
                      const TextStyle(
                        fontSize: 15.5,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      job?.employerName ??
                          'Nhà tuyển dụng',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    9,
                  ),
                ),
                child: Text(
                  application.statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (job?.location != null)
            _InfoRow(
              icon:
              Icons.location_on_outlined,
              text: job!.location!,
            ),

          if (job?.location != null)
            const SizedBox(height: 6),

          if (job != null)
            _InfoRow(
              icon:
              Icons.payments_outlined,
              text: job.salaryText,
            ),

          if (application
              .createdAtText.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon:
              Icons.schedule_rounded,
              text:
              'Ứng tuyển ${application.createdAtText}',
            ),
          ],

          if (application
              .matchPercentage !=
              null) ...[
            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(
                  Icons
                      .auto_awesome_rounded,
                  size: 17,
                  color:
                  Color(0xFF7C3AED),
                ),
                const SizedBox(width: 6),
                Text(
                  'AI đánh giá độ phù hợp: '
                      '${application.matchPercentage}%',
                  style: const TextStyle(
                    color:
                    Color(0xFF7C3AED),
                    fontSize: 12.5,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          if (application.status ==
              'ACCEPTED') ...[
            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color:
                const Color(0xFF16A34A)
                    .withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                    Color(0xFF16A34A),
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn đã được nhà tuyển dụng chấp nhận.',
                      style: TextStyle(
                        color:
                        Color(0xFF15803D),
                        fontSize: 12.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'APPLIED':
        return const Color(
          0xFF2563EB,
        );

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
        return Colors.grey;
    }
  }
}

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color:
              Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyView
    extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color:
                const Color(0xFF2563EB)
                    .withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .work_history_outlined,
                size: 40,
                color:
                Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có hoạt động',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các công việc bạn ứng tuyển sẽ xuất hiện tại đây.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView
    extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 45,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
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
}
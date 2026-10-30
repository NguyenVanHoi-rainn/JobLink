import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/employer_job_service.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';

import '../auth/login_screen.dart';
import '../worker/worker_messages_screen.dart';

import 'employer_create_job_screen.dart';
import 'employer_job_applications_screen.dart';
import 'employer_job_detail_screen.dart';
import 'employer_notifications_screen.dart';
import 'employer_profile_screen.dart';
import '../../services/employer_profile_service.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({
    super.key,
  });

  @override
  State<EmployerHomeScreen> createState() =>
      _EmployerHomeScreenState();
}

class _EmployerHomeScreenState
    extends State<EmployerHomeScreen> {
  static const Color _primary =
  Color(0xFF2563EB);

  static const Color _background =
  Color(0xFFF5F7FB);

  final EmployerJobService _jobService =
  EmployerJobService();

  final ChatService _chatService =
  ChatService();

  final EmployerProfileService _profileService =
  EmployerProfileService();

  final NotificationService
  _notificationService =
  NotificationService();

  int _selectedIndex = 0;

  int _unreadMessages = 0;
  int _unreadNotifications = 0;

  List<Map<String, dynamic>> _jobs = [];

  bool _loadingJobs = true;
  String? _jobsError;

  StreamSubscription<void>?
  _notificationSubscription;

  @override
  void initState() {
    super.initState();

    _loadJobs();
    _loadUnreadMessages();
    _loadUnreadNotifications();

    _notificationSubscription =
        PushNotificationService
            .instance
            .onNotificationReceived
            .listen(
              (_) {
            _loadUnreadNotifications();
          },
        );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();

    super.dispose();
  }

  // =====================================================
  // JOBS
  // =====================================================

  Future<void> _loadJobs() async {
    if (mounted) {
      setState(() {
        _loadingJobs = true;
        _jobsError = null;
      });
    }

    try {
      final jobs =
      await _jobService.getMyJobs();

      if (!mounted) {
        return;
      }

      setState(() {
        _jobs = jobs;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _jobsError =
        'Không thể tải tin tuyển dụng';
      });

      debugPrint(
        'Load employer jobs failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingJobs = false;
        });
      }
    }
  }

  // =====================================================
  // MESSAGE BADGE
  // =====================================================

  Future<void>
  _loadUnreadMessages() async {
    try {
      final count =
      await _chatService
          .getTotalUnreadCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadMessages = count;
      });
    } catch (error) {
      debugPrint(
        'Không thể tải số tin nhắn chưa đọc: $error',
      );
    }
  }

  void _updateUnreadMessages(
      int count,
      ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _unreadMessages = count;
    });
  }

  // =====================================================
  // NOTIFICATION BADGE
  // =====================================================

  Future<void>
  _loadUnreadNotifications() async {
    try {
      final count =
      await _notificationService
          .getUnreadCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotifications = count;
      });
    } catch (error) {
      debugPrint(
        'Không thể tải số thông báo Employer: $error',
      );
    }
  }

  Future<void>
  _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const EmployerNotificationsScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadUnreadNotifications();
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> _logout() async {
    await AuthService().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
          (_) => false,
    );
  }

  // =====================================================
  // CREATE JOB
  // =====================================================

  Future<void> _openCreateJob() async {
    try {
      final profile =
      await _profileService.getProfile();

      if (!mounted) {
        return;
      }

      final status =
          profile['verificationStatus']
              ?.toString() ??
              'UNVERIFIED';

      // Chỉ Employer VERIFIED mới được vào form đăng tin.
      if (status != 'VERIFIED') {
        String title;
        String message;
        IconData icon;
        Color color;

        switch (status) {
          case 'PENDING':
            title = 'Đang chờ xác minh';
            message =
            'Hồ sơ Employer của bạn đang được Admin xem xét. '
                'Bạn chỉ có thể đăng tin tuyển dụng sau khi được xác minh.';
            icon = Icons.hourglass_top_rounded;
            color = const Color(0xFFF59E0B);
            break;

          case 'REJECTED':
            title = 'Xác minh bị từ chối';
            message =
            'Hồ sơ Employer của bạn chưa được chấp nhận. '
                'Vui lòng vào Hồ sơ để kiểm tra lý do, cập nhật thông tin '
                'và gửi yêu cầu xác minh lại.';
            icon = Icons.cancel_outlined;
            color = const Color(0xFFDC2626);
            break;

          default:
            title = 'Cần xác minh Employer';
            message =
            'Bạn cần hoàn tất thông tin doanh nghiệp và được Admin '
                'xác minh trước khi có thể đăng tin tuyển dụng.';
            icon = Icons.verified_user_outlined;
            color = const Color(0xFF2563EB);
        }

        final goToProfile =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              icon: Icon(
                icon,
                size: 40,
                color: color,
              ),
              title: Text(
                title,
                textAlign: TextAlign.center,
              ),
              content: Text(
                message,
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child: const Text(
                    'Đóng',
                  ),
                ),
                if (status != 'PENDING')
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        true,
                      );
                    },
                    icon: const Icon(
                      Icons.person_outline_rounded,
                    ),
                    label: const Text(
                      'Đi tới hồ sơ',
                    ),
                  ),
              ],
            );
          },
        );

        if (!mounted) {
          return;
        }

        if (goToProfile == true) {
          setState(() {
            _selectedIndex = 4;
          });
        }

        return;
      }

      // ===================================================
      // VERIFIED → MỞ FORM ĐĂNG TIN
      // ===================================================

      final created =
      await Navigator.of(context)
          .push<bool>(
        MaterialPageRoute(
          builder: (_) =>
          const EmployerCreateJobScreen(),
        ),
      );

      if (created == true &&
          mounted) {
        await _loadJobs();

        if (!mounted) {
          return;
        }

        setState(() {
          _selectedIndex = 1;
        });
      }
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _dioMessage(error) ??
            'Không thể kiểm tra trạng thái xác minh Employer',
      );
    } catch (error) {
      debugPrint(
        'Check employer verification failed: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể kiểm tra trạng thái xác minh Employer',
      );
    }
  }

  // =====================================================
  // JOB DETAIL
  // =====================================================

  Future<void> _openJobDetail(
      Map<String, dynamic> job,
      ) async {
    final id =
    job['id']?.toString();

    if (id == null ||
        id.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EmployerJobDetailScreen(
              jobId: id,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadJobs();
  }

  // =====================================================
  // APPLICATIONS
  // =====================================================

  Future<void> _openApplications(
      Map<String, dynamic> job,
      ) async {
    final id =
    job['id']?.toString();

    if (id == null ||
        id.isEmpty) {
      return;
    }

    final title =
        job['title']?.toString() ??
            'Tin tuyển dụng';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EmployerJobApplicationsScreen(
              jobId: id,
              jobTitle: title,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadJobs();
    await _loadUnreadNotifications();
  }

  // =====================================================
  // PUBLISH / CLOSE / REPUBLISH
  // =====================================================

  Future<void> _runJobAction(
      Map<String, dynamic> job,
      ) async {
    final id =
    job['id']?.toString();

    final status =
    job['status']?.toString();

    if (id == null ||
        id.isEmpty ||
        status == null) {
      return;
    }

    try {
      if (status == 'DRAFT') {
        await _jobService.publishJob(
          id,
        );

        _showMessage(
          'Đăng tin thành công',
        );
      } else if (status ==
          'PUBLISHED') {
        await _jobService.closeJob(
          id,
        );

        _showMessage(
          'Đã đóng tin tuyển dụng',
        );
      } else if (status ==
          'CLOSED') {
        await _jobService.republishJob(
          id,
        );

        _showMessage(
          'Đăng lại tin thành công',
        );
      }

      await _loadJobs();
    } on DioException catch (error) {
      _showMessage(
        _dioMessage(error) ??
            'Không thể cập nhật tin tuyển dụng',
      );
    } catch (error) {
      debugPrint(
        'Job action failed: $error',
      );

      _showMessage(
        'Không thể cập nhật tin tuyển dụng',
      );
    }
  }

  // =====================================================
  // ERROR
  // =====================================================

  String? _dioMessage(
      DioException error,
      ) {
    final data =
        error.response?.data;

    if (data is Map) {
      final raw =
      data['message'];

      if (raw is List) {
        return raw.join(', ');
      }

      return raw?.toString();
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
          Text(message),
        ),
      );
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  void _onNavigationSelected(
      int index,
      ) {
    // Nút + ở giữa chỉ dùng mở form đăng tin.
    if (index == 2) {
      _openCreateJob();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0 ||
        index == 1) {
      _loadJobs();
    }

    if (index == 3) {
      _loadUnreadMessages();
    }

    if (index == 4) {
      _loadUnreadNotifications();
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    /*
      Bottom Navigation:

      0 = Trang chủ
      1 = Tin đăng
      2 = + Đăng tin
      3 = Tin nhắn
      4 = Hồ sơ

      IndexedStack chỉ có 4 page vì index 2
      mở màn hình đăng tin riêng.
    */

    final pageIndex =
    switch (_selectedIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
    };

    final pages = <Widget>[
      _EmployerDashboard(
        jobs: _jobs,
        loading: _loadingJobs,
        error: _jobsError,
        onRefresh: _loadJobs,
        onCreateJob: _openCreateJob,
        onOpenDetail:
        _openJobDetail,
        onViewApplicants:
        _openApplications,
      ),

      _EmployerJobsTab(
        jobs: _jobs,
        loading: _loadingJobs,
        error: _jobsError,
        onRefresh: _loadJobs,
        onCreateJob: _openCreateJob,
        onOpenDetail:
        _openJobDetail,
        onViewApplicants:
        _openApplications,
        onJobAction:
        _runJobAction,
      ),

      WorkerMessagesScreen(
        onUnreadChanged:
        _updateUnreadMessages,
      ),

      _EmployerProfileTab(
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor:
      _background,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        elevation: 0,

        title: Text(
          _appBarTitle(),
          style:
          const TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          if (_selectedIndex == 0 ||
              _selectedIndex == 1)
            IconButton(
              tooltip: 'Làm mới',
              onPressed:
              _loadingJobs
                  ? null
                  : _loadJobs,
              icon:
              const Icon(
                Icons.refresh_rounded,
              ),
            ),

          _EmployerNotificationButton(
            count:
            _unreadNotifications,
            onPressed:
            _openNotifications,
          ),

          IconButton(
            tooltip: 'Đăng xuất',
            onPressed:
            _logout,
            icon:
            const Icon(
              Icons.logout_rounded,
            ),
          ),

          const SizedBox(
            width: 4,
          ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: IndexedStack(
        index: pageIndex,
        children: pages,
      ),

      // =================================================
      // NAVIGATION
      // =================================================

      bottomNavigationBar:
      NavigationBar(
        height: 72,
        selectedIndex:
        _selectedIndex,
        backgroundColor:
        Colors.white,
        indicatorColor:
        _primary.withValues(
          alpha: 0.12,
        ),
        onDestinationSelected:
        _onNavigationSelected,

        destinations: [
          const NavigationDestination(
            icon:
            Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
            Icon(
              Icons.home_rounded,
              color:
              _primary,
            ),
            label:
            'Trang chủ',
          ),

          const NavigationDestination(
            icon:
            Icon(
              Icons
                  .work_outline_rounded,
            ),
            selectedIcon:
            Icon(
              Icons.work_rounded,
              color:
              _primary,
            ),
            label:
            'Tin đăng',
          ),

          NavigationDestination(
            icon: Container(
              width: 44,
              height: 44,
              decoration:
              BoxDecoration(
                color:
                _primary,
                shape:
                BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                    _primary
                        .withValues(
                      alpha: 0.25,
                    ),
                    blurRadius: 10,
                    offset:
                    const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),
              child:
              const Icon(
                Icons.add_rounded,
                color:
                Colors.white,
                size: 29,
              ),
            ),
            label:
            'Đăng tin',
          ),

          NavigationDestination(
            icon:
            _MessageNavIcon(
              count:
              _unreadMessages,
            ),
            selectedIcon:
            _MessageNavIcon(
              count:
              _unreadMessages,
              selected:
              true,
            ),
            label:
            'Tin nhắn',
          ),

          const NavigationDestination(
            icon:
            Icon(
              Icons
                  .person_outline_rounded,
            ),
            selectedIcon:
            Icon(
              Icons.person_rounded,
              color:
              _primary,
            ),
            label:
            'Hồ sơ',
          ),
        ],
      ),
    );
  }

  String _appBarTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Tin tuyển dụng';

      case 3:
        return 'Tin nhắn';

      case 4:
        return 'Hồ sơ Employer';

      default:
        return 'JobLink Employer';
    }
  }
}

// =========================================================
// EMPLOYER DASHBOARD
// =========================================================

class _EmployerDashboard
    extends StatelessWidget {
  const _EmployerDashboard({
    required this.jobs,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onCreateJob,
    required this.onOpenDetail,
    required this.onViewApplicants,
  });

  final List<Map<String, dynamic>>
  jobs;

  final bool loading;
  final String? error;

  final Future<void> Function()
  onRefresh;

  final VoidCallback onCreateJob;

  final Future<void> Function(
      Map<String, dynamic> job,
      ) onOpenDetail;

  final Future<void> Function(
      Map<String, dynamic> job,
      ) onViewApplicants;

  @override
  Widget build(
      BuildContext context,
      ) {
    final published =
        jobs.where(
              (job) =>
          job['status'] ==
              'PUBLISHED',
        ).length;

    final draft =
        jobs.where(
              (job) =>
          job['status'] ==
              'DRAFT',
        ).length;

    final applicants =
    jobs.fold<int>(
      0,
          (
          sum,
          job,
          ) {
        final count =
        _asMap(
          job['_count'],
        );

        final value =
            int.tryParse(
              count?[
              'applications']
                  ?.toString() ??
                  '0',
            ) ??
                0;

        return sum + value;
      },
    );

    return RefreshIndicator(
      onRefresh:
      onRefresh,
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
          // ===============================================
          // BANNER
          // ===============================================

          Container(
            padding:
            const EdgeInsets.all(
              20,
            ),
            decoration:
            BoxDecoration(
              gradient:
              const LinearGradient(
                colors: [
                  Color(
                    0xFF2563EB,
                  ),
                  Color(
                    0xFF4F7FF0,
                  ),
                ],
                begin:
                Alignment.topLeft,
                end:
                Alignment.bottomRight,
              ),
              borderRadius:
              BorderRadius.circular(
                22,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  const Color(
                    0xFF2563EB,
                  ).withValues(
                    alpha: 0.16,
                  ),
                  blurRadius: 22,
                  offset:
                  const Offset(
                    0,
                    9,
                  ),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        'Quản lý tuyển dụng',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize: 22,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      Text(
                        'Đăng tin, theo dõi ứng viên và quản lý quá trình tuyển dụng trên JobLink.',
                        style:
                        TextStyle(
                          color:
                          Colors.white70,
                          fontSize:
                          12.5,
                          height:
                          1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Container(
                  width: 68,
                  height: 68,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white
                        .withValues(
                      alpha: 0.16,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child:
                  const Icon(
                    Icons
                        .business_center_rounded,
                    color:
                    Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ===============================================
          // CREATE JOB
          // ===============================================

          SizedBox(
            width:
            double.infinity,
            child:
            FilledButton.icon(
              onPressed:
              onCreateJob,
              style:
              FilledButton
                  .styleFrom(
                minimumSize:
                const Size(
                  0,
                  52,
                ),
                backgroundColor:
                const Color(
                  0xFF2563EB,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              icon:
              const Icon(
                Icons
                    .add_circle_outline_rounded,
              ),
              label:
              const Text(
                'Đăng tin tuyển dụng mới',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ===============================================
          // STATS
          // ===============================================

          Row(
            children: [
              Expanded(
                child:
                _StatCard(
                  label:
                  'Tổng tin',
                  value:
                  '${jobs.length}',
                  icon:
                  Icons
                      .work_outline_rounded,
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child:
                _StatCard(
                  label:
                  'Đang đăng',
                  value:
                  '$published',
                  icon:
                  Icons
                      .campaign_outlined,
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child:
                _StatCard(
                  label:
                  'Ứng viên',
                  value:
                  '$applicants',
                  icon:
                  Icons
                      .groups_outlined,
                ),
              ),
            ],
          ),

          if (draft > 0) ...[
            const SizedBox(
              height: 12,
            ),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF59E0B,
                ).withValues(
                  alpha: 0.09,
                ),
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .edit_note_rounded,
                    color:
                    Color(
                      0xFFF59E0B,
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Expanded(
                    child: Text(
                      'Bạn đang có $draft tin bản nháp.',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(
            height: 25,
          ),

          // ===============================================
          // RECENT JOBS
          // ===============================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tin tuyển dụng gần đây',
                  style:
                  TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),

              Text(
                '${jobs.length} tin',
                style:
                TextStyle(
                  color: Colors
                      .grey
                      .shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          if (loading)
            const Center(
              child: Padding(
                padding:
                EdgeInsets.all(
                  30,
                ),
                child:
                CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            _SimpleMessage(
              icon:
              Icons
                  .cloud_off_rounded,
              title:
              error!,
            )
          else if (jobs.isEmpty)
              const _SimpleMessage(
                icon:
                Icons
                    .work_outline_rounded,
                title:
                'Chưa có tin tuyển dụng',
                subtitle:
                'Bấm "Đăng tin tuyển dụng mới" để tạo tin đầu tiên.',
              )
            else
              ...jobs.take(3).map(
                    (job) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child:
                    _EmployerJobCard(
                      job: job,
                      compact:
                      true,

                      onOpenDetail:
                          () {
                        onOpenDetail(
                          job,
                        );
                      },

                      onViewApplicants:
                          () {
                        onViewApplicants(
                          job,
                        );
                      },
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}

// =========================================================
// JOBS TAB
// =========================================================

class _EmployerJobsTab
    extends StatelessWidget {
  const _EmployerJobsTab({
    required this.jobs,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onCreateJob,
    required this.onOpenDetail,
    required this.onViewApplicants,
    required this.onJobAction,
  });

  final List<Map<String, dynamic>>
  jobs;

  final bool loading;
  final String? error;

  final Future<void> Function()
  onRefresh;

  final VoidCallback onCreateJob;

  final Future<void> Function(
      Map<String, dynamic> job,
      ) onOpenDetail;

  final Future<void> Function(
      Map<String, dynamic> job,
      ) onViewApplicants;

  final Future<void> Function(
      Map<String, dynamic> job,
      ) onJobAction;

  @override
  Widget build(
      BuildContext context,
      ) {
    return RefreshIndicator(
      onRefresh:
      onRefresh,
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tin tuyển dụng của bạn',
                  style:
                  TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),

              FilledButton.icon(
                onPressed:
                onCreateJob,
                icon:
                const Icon(
                  Icons.add_rounded,
                ),
                label:
                const Text(
                  'Đăng tin',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          if (loading)
            const Center(
              child: Padding(
                padding:
                EdgeInsets.all(
                  40,
                ),
                child:
                CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            _SimpleMessage(
              icon:
              Icons
                  .cloud_off_rounded,
              title:
              error!,
            )
          else if (jobs.isEmpty)
              const _SimpleMessage(
                icon:
                Icons
                    .work_outline_rounded,
                title:
                'Chưa có tin tuyển dụng',
                subtitle:
                'Tạo tin mới để bắt đầu tuyển ứng viên.',
              )
            else
              ...jobs.map(
                    (job) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                    _EmployerJobCard(
                      job: job,

                      onOpenDetail:
                          () {
                        onOpenDetail(
                          job,
                        );
                      },

                      onViewApplicants:
                          () {
                        onViewApplicants(
                          job,
                        );
                      },

                      onJobAction:
                          () {
                        onJobAction(
                          job,
                        );
                      },
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}

// =========================================================
// JOB CARD
// =========================================================

class _EmployerJobCard
    extends StatelessWidget {
  const _EmployerJobCard({
    required this.job,
    required this.onOpenDetail,
    required this.onViewApplicants,
    this.onJobAction,
    this.compact = false,
  });

  final Map<String, dynamic>
  job;

  final VoidCallback
  onOpenDetail;

  final VoidCallback
  onViewApplicants;

  final VoidCallback?
  onJobAction;

  final bool compact;

  @override
  Widget build(
      BuildContext context,
      ) {
    final title =
        job['title']?.toString() ??
            'Tin tuyển dụng';

    final status =
        job['status']?.toString() ??
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

    final location =
    job['location']
        ?.toString();

    final salary =
    job['salary'];

    final statusData =
    _jobStatus(
      status,
    );

    return Material(
      color:
      Colors.white,
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap:
        onOpenDetail,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Container(
          padding:
          const EdgeInsets.all(
            16,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border:
            Border.all(
              color:
              Colors.grey.shade200,
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
                    width: 46,
                    height: 46,
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
                        13,
                      ),
                    ),
                    child:
                    const Icon(
                      Icons.work_rounded,
                      color:
                      Color(
                        0xFF2563EB,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines:
                          2,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize:
                            15.5,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          category?['name']
                              ?.toString() ??
                              'Chưa có danh mục',
                          style:
                          TextStyle(
                            color: Colors
                                .grey
                                .shade600,
                            fontSize:
                            12.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal:
                      8,
                      vertical:
                      5,
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
                        9,
                      ),
                    ),
                    child:
                    Text(
                      statusData.$1,
                      style:
                      TextStyle(
                        color:
                        statusData.$2,
                        fontSize:
                        10.5,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // ===========================================
              // LOCATION
              // ===========================================

              if (location != null &&
                  location.isNotEmpty) ...[
                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on_outlined,
                      size: 17,
                      color:
                      Color(
                        0xFF64748B,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        TextStyle(
                          color: Colors
                              .grey
                              .shade700,
                          fontSize:
                          12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ===========================================
              // SALARY
              // ===========================================

              if (salary != null) ...[
                const SizedBox(
                  height: 8,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .payments_outlined,
                      size: 17,
                      color:
                      Color(
                        0xFF64748B,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      '${_formatMoney(salary)} VNĐ',
                      style:
                      const TextStyle(
                        fontSize:
                        12.5,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(
                height: 12,
              ),

              // ===========================================
              // APPLICATION COUNT
              // ===========================================

              Row(
                children: [
                  const Icon(
                    Icons
                        .groups_outlined,
                    size: 17,
                    color:
                    Color(
                      0xFF64748B,
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Text(
                    '$applicantCount ứng viên',
                    style:
                    TextStyle(
                      color: Colors
                          .grey
                          .shade700,
                      fontSize:
                      12.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 6,
              ),

              // ===========================================
              // DETAIL + APPLICANTS
              // ===========================================

              Row(
                children: [
                  Expanded(
                    child:
                    OutlinedButton.icon(
                      onPressed:
                      onOpenDetail,
                      icon:
                      const Icon(
                        Icons
                            .visibility_outlined,
                        size: 18,
                      ),
                      label:
                      const Text(
                        'Chi tiết',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    FilledButton.icon(
                      onPressed:
                      onViewApplicants,
                      icon:
                      const Icon(
                        Icons
                            .people_alt_outlined,
                        size: 18,
                      ),
                      label:
                      const Text(
                        'Ứng viên',
                      ),
                    ),
                  ),
                ],
              ),

              // ===========================================
              // JOB STATUS ACTION
              // ===========================================

              if (!compact &&
                  onJobAction != null &&
                  (status ==
                      'DRAFT' ||
                      status ==
                          'PUBLISHED' ||
                      status ==
                          'CLOSED')) ...[
                const Divider(
                  height: 24,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    onJobAction,

                    icon: Icon(
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

                    label: Text(
                      status ==
                          'DRAFT'
                          ? 'Đăng tin'
                          : status ==
                          'PUBLISHED'
                          ? 'Đóng tin'
                          : 'Đăng lại',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// PROFILE
// =========================================================

class _EmployerProfileTab extends StatelessWidget {
  const _EmployerProfileTab({
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return EmployerProfileScreen(
      onLogout: onLogout,
    );
  }
}
// =========================================================
// MESSAGE BADGE
// =========================================================

class _MessageNavIcon
    extends StatelessWidget {
  const _MessageNavIcon({
    required this.count,
    this.selected = false,
  });

  final int count;
  final bool selected;

  @override
  Widget build(
      BuildContext context,
      ) {
    return SizedBox(
      width: 34,
      height: 30,
      child: Stack(
        clipBehavior:
        Clip.none,
        children: [
          Center(
            child:
            Icon(
              selected
                  ? Icons
                  .chat_bubble_rounded
                  : Icons
                  .chat_bubble_outline_rounded,
              color:
              selected
                  ? const Color(
                0xFF2563EB,
              )
                  : null,
            ),
          ),

          if (count > 0)
            Positioned(
              right: -5,
              top: -5,
              child:
              Container(
                constraints:
                const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                decoration:
                const BoxDecoration(
                  color:
                  Color(
                    0xFFEF4444,
                  ),
                  borderRadius:
                  BorderRadius.all(
                    Radius.circular(
                      20,
                    ),
                  ),
                ),
                alignment:
                Alignment.center,
                child: Text(
                  count > 99
                      ? '99+'
                      : count
                      .toString(),
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =========================================================
// NOTIFICATION BADGE
// =========================================================

class _EmployerNotificationButton
    extends StatelessWidget {
  const _EmployerNotificationButton({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(
      BuildContext context,
      ) {
    return IconButton(
      tooltip:
      'Thông báo',
      onPressed:
      onPressed,
      icon: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          clipBehavior:
          Clip.none,
          children: [
            const Center(
              child:
              Icon(
                Icons
                    .notifications_none_rounded,
              ),
            ),

            if (count > 0)
              Positioned(
                right: -3,
                top: -3,
                child:
                Container(
                  constraints:
                  const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration:
                  const BoxDecoration(
                    color:
                    Color(
                      0xFFEF4444,
                    ),
                    borderRadius:
                    BorderRadius.all(
                      Radius.circular(
                        20,
                      ),
                    ),
                  ),
                  alignment:
                  Alignment.center,
                  child: Text(
                    count > 99
                        ? '99+'
                        : count
                        .toString(),
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// STAT CARD
// =========================================================

class _StatCard
    extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        13,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
            const Color(
              0xFF2563EB,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            value,
            style:
            const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            label,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// EMPTY / ERROR
// =========================================================

class _SimpleMessage
    extends StatelessWidget {
  const _SimpleMessage({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        24,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color:
            Colors.grey.shade400,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(
              height: 6,
            ),

            Text(
              subtitle!,
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =========================================================
// HELPERS
// =========================================================

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

(String, Color) _jobStatus(
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
      'Đã ẩn',
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
      buffer.write('.');
    }
  }

  return buffer.toString();
}
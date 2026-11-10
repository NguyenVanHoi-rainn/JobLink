import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/job.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/job_service.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';

import '../auth/login_screen.dart';

import 'job_detail_screen.dart';
import 'worker_activity_screen.dart';
import 'worker_messages_screen.dart';
import 'worker_notifications_screen.dart';
import 'worker_profile_screen.dart';
import 'worker_schedule_screen.dart';

// =======================================================
// WORKER HOME SCREEN
// =======================================================

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  static const Color primaryColor = Color(0xFF2563EB);

  static const Color backgroundColor = Color(0xFFF5F7FB);

  final ChatService _chatService = ChatService();

  int _currentIndex = 0;
  int _unreadMessageCount = 0;
  int _scheduleRefreshTrigger = 0;

  @override
  void initState() {
    super.initState();

    _loadUnreadMessageCount();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final count = await _chatService.getTotalUnreadCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadMessageCount = count;
      });
    } catch (e) {
      debugPrint('Không thể tải unread message count: $e');
    }
  }

  void _updateUnreadMessageCount(int count) {
    if (!mounted) {
      return;
    }

    setState(() {
      _unreadMessageCount = count;
    });
  }

  void _openProfileTab() {
    setState(() {
      _currentIndex = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _WorkerHomePage(onOpenProfile: _openProfileTab),

      const WorkerActivityScreen(),

      WorkerScheduleScreen(refreshTrigger: _scheduleRefreshTrigger),

      WorkerMessagesScreen(onUnreadChanged: _updateUnreadMessageCount),

      const WorkerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,

      body: IndexedStack(index: _currentIndex, children: pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        backgroundColor: Colors.white,

        indicatorColor: primaryColor.withValues(alpha: 0.12),

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 2) {
              _scheduleRefreshTrigger++;
            }
          });

          if (index == 3) {
            _loadUnreadMessageCount();
          }
        },

        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: primaryColor),
            label: 'Trang chủ',
          ),

          const NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded, color: primaryColor),
            label: 'Hoạt động',
          ),

          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(
              Icons.calendar_month_rounded,
              color: primaryColor,
            ),
            label: 'Lịch',
          ),

          NavigationDestination(
            icon: _MessageNavIcon(count: _unreadMessageCount),

            selectedIcon: _MessageNavIcon(
              count: _unreadMessageCount,
              selected: true,
            ),

            label: 'Tin nhắn',
          ),

          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: primaryColor),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

// =======================================================
// MESSAGE NAV BADGE
// =======================================================

class _MessageNavIcon extends StatelessWidget {
  const _MessageNavIcon({required this.count, this.selected = false});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 30,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          Center(
            child: Icon(
              selected
                  ? Icons.chat_bubble_rounded
                  : Icons.chat_bubble_outline_rounded,

              color: selected ? const Color(0xFF2563EB) : null,
            ),
          ),

          if (count > 0)
            Positioned(
              right: -5,
              top: -5,

              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),

                padding: const EdgeInsets.symmetric(horizontal: 5),

                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),

                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),

                alignment: Alignment.center,

                child: Text(
                  count > 99 ? '99+' : count.toString(),

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =======================================================
// HOME PAGE
// =======================================================

class _WorkerHomePage extends StatefulWidget {
  const _WorkerHomePage({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  State<_WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<_WorkerHomePage> {
  static const Color primaryColor = Color(0xFF2563EB);

  static const Color aiColor = Color(0xFF7C3AED);

  final JobService _jobService = JobService();

  final NotificationService _notificationService = NotificationService();

  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<void>? _notificationSubscription;

  Timer? _searchDebounce;

  int _requestSerial = 0;

  // =====================================================
  // DATA
  // =====================================================

  List<Job> _jobs = [];

  List<JobRecommendation> _recommendations = [];

  List<Map<String, dynamic>> _categories = [];

  List<Map<String, dynamic>> _skills = [];

  int _unreadNotificationCount = 0;

  int _totalJobs = 0;

  bool _loading = true;
  bool _aiLoading = false;
  bool _aiEnabled = false;

  String? _error;

  // =====================================================
  // FILTER STATE
  // =====================================================

  String? _categoryId;

  double? _minSalary;
  double? _maxSalary;

  String? _salaryType;

  String? _shiftType;

  final Set<String> _workDays = {};

  final Set<String> _skillIds = {};

  bool? _cvRequired;

  bool? _urgent;

  double? _maxDistanceKm;

  bool _nearMeOnly = false;

  String _sort = 'NEWEST';

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    _loadInitialData();

    _notificationSubscription = PushNotificationService
        .instance
        .onNotificationReceived
        .listen((_) {
          _loadUnreadNotificationCount();
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.handlePendingNavigation();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _notificationSubscription?.cancel();

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadJobs(),
      _loadMeta(),
      _loadUnreadNotificationCount(),
    ]);

    // AI chạy riêng.
    //
    // Nếu Worker đã có đủ dữ liệu:
    // → tự động bật AI.
    //
    // Nếu chưa có Profile:
    // → bỏ qua, Home vẫn hoạt động.
    await _tryEnableAiSilently();
  }

  // =====================================================
  // LOAD JOB
  // =====================================================

  Future<Object?> _loadJobs({bool showLoader = true}) async {
    final requestId = ++_requestSerial;

    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() {
        _error = null;
      });
    }

    try {
      final distance = _nearMeOnly ? 5.0 : _maxDistanceKm;

      final result = await _jobService.searchJobs(
        keyword: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),

        categoryId: _categoryId,

        minSalary: _minSalary,

        maxSalary: _maxSalary,

        salaryType: _salaryType,

        shiftType: _shiftType,

        workDays: _workDays.isEmpty ? null : _workDays.toList(),

        skillIds: _skillIds.isEmpty ? null : _skillIds.toList(),

        cvRequired: _cvRequired,

        urgent: _urgent,

        maxDistanceKm: distance,

        sort: _sort,

        page: 1,

        limit: 50,
      );

      if (!mounted || requestId != _requestSerial) {
        return null;
      }

      setState(() {
        _jobs = result.items;

        _totalJobs = result.total;

        _error = null;
      });

      return null;
    } catch (e) {
      if (!mounted || requestId != _requestSerial) {
        return e;
      }

      setState(() {
        _error = _friendlyError(e);
      });

      return e;
    } finally {
      if (mounted && requestId == _requestSerial) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =====================================================
  // META
  // =====================================================

  Future<void> _loadMeta() async {
    try {
      final results = await Future.wait([
        _jobService.getCategories(),

        _jobService.getSkills(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = results[0];

        _skills = results[1];
      });
    } catch (e) {
      debugPrint('Không thể tải categories/skills: $e');
    }
  }

  // =====================================================
  // AI
  // =====================================================

  Future<void> _tryEnableAiSilently() async {
    try {
      final recommendations = await _jobService.getRecommendations();

      if (!mounted) {
        return;
      }

      if (recommendations.isEmpty) {
        return;
      }

      setState(() {
        _recommendations = recommendations;

        _aiEnabled = true;
      });
    } catch (e) {
      // Cố ý bỏ qua.
      //
      // Worker chưa hoàn thiện Profile
      // vẫn sử dụng Home bình thường.
      debugPrint('AI chưa sẵn sàng: $e');
    }
  }

  Future<void> _toggleAi() async {
    if (_aiLoading) {
      return;
    }

    if (_aiEnabled) {
      setState(() {
        _aiEnabled = false;
      });

      return;
    }

    setState(() {
      _aiLoading = true;
    });

    try {
      final recommendations = await _jobService.getRecommendations();

      if (!mounted) {
        return;
      }

      if (recommendations.isEmpty) {
        await _showAiProfileDialog();

        return;
      }

      setState(() {
        _recommendations = recommendations;

        _aiEnabled = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      if (_isProfileAiError(e)) {
        await _showAiProfileDialog();

        return;
      }

      _showSnackBar('Không thể tải gợi ý AI lúc này.');
    } finally {
      if (mounted) {
        setState(() {
          _aiLoading = false;
        });
      }
    }
  }

  bool _isProfileAiError(Object error) {
    final message = _friendlyError(error).toLowerCase();

    if (error is DioException) {
      final status = error.response?.statusCode;

      if (status == 400 || status == 404) {
        return true;
      }
    }

    return message.contains('hồ sơ') ||
        message.contains('profile') ||
        message.contains('kỹ năng') ||
        message.contains('worker');
  }

  Future<void> _showAiProfileDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.auto_awesome_rounded,
            color: aiColor,
            size: 34,
          ),

          title: const Text('Hoàn thiện hồ sơ AI'),

          content: const Text(
            'AI cần bạn hoàn thiện một số thông tin bắt buộc:\n\n'
            '• Kỹ năng\n'
            '• Lĩnh vực quan tâm\n'
            '• Ca làm và ngày rảnh\n\n'
            'Khu vực muốn làm và mức lương mong muốn là tùy chọn, '
            'nhưng sẽ giúp AI gợi ý chính xác hơn.\n\n'
            'Bạn vẫn có thể tìm việc bình thường mà không cần dùng AI.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Để sau'),
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                widget.onOpenProfile();
              },

              icon: const Icon(Icons.person_rounded),

              label: const Text('Đi tới hồ sơ'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // RECOMMENDATION ORDER
  // =====================================================

  List<Job> get _displayJobs {
    if (!_aiEnabled || _recommendations.isEmpty) {
      return _jobs;
    }

    final jobsById = <String, Job>{for (final job in _jobs) job.id: job};

    final result = <Job>[];

    final added = <String>{};

    // Job AI đưa lên trước.
    for (final recommendation in _recommendations) {
      final job = jobsById[recommendation.job.id];

      if (job == null) {
        continue;
      }

      if (added.add(job.id)) {
        result.add(job);
      }
    }

    // Không ẩn những Job AI
    // đánh giá thấp / chưa đánh giá.
    for (final job in _jobs) {
      if (added.add(job.id)) {
        result.add(job);
      }
    }

    return result;
  }

  List<JobRecommendation> get _visibleRecommendations {
    final currentIds = _jobs.map((job) => job.id).toSet();

    return _recommendations
        .where((item) => currentIds.contains(item.job.id))
        .toList();
  }

  // =====================================================
  // NOTIFICATION
  // =====================================================

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (e) {
      debugPrint('Không thể tải notification count: $e');
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkerNotificationsScreen()),
    );

    if (!mounted) {
      return;
    }

    await _loadUnreadNotificationCount();
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> _logout() async {
    await AuthService().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // =====================================================
  // SEARCH
  // =====================================================

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadJobs(showLoader: false);
    });
  }

  void _clearSearch() {
    _searchController.clear();

    _loadJobs(showLoader: false);
  }

  // =====================================================
  // QUICK CATEGORY
  // =====================================================

  Future<void> _selectCategory(String? id) async {
    setState(() {
      _categoryId = id;
    });

    await _loadJobs();
  }

  // =====================================================
  // NEAR ME
  // =====================================================

  Future<void> _toggleNearMe() async {
    final newValue = !_nearMeOnly;

    setState(() {
      _nearMeOnly = newValue;
    });

    final error = await _loadJobs();

    if (!mounted || error == null) {
      return;
    }

    final message = _friendlyError(error);

    if (newValue && message.toLowerCase().contains('vị trí')) {
      setState(() {
        _nearMeOnly = false;
      });

      _showSnackBar(
        'Bạn chưa có vị trí trong hồ sơ. Hãy cập nhật vị trí để dùng "Gần tôi".',
      );

      await _loadJobs(showLoader: false);
    }
  }

  // =====================================================
  // SALARY QUICK SHEET
  // =====================================================

  Future<void> _showSalaryFilter() async {
    String? salaryType = _salaryType;

    final minController = TextEditingController(
      text: _minSalary == null ? '' : _minSalary!.round().toString(),
    );

    final maxController = TextEditingController(
      text: _maxSalary == null ? '' : _maxSalary!.round().toString(),
    );

    final applied = await showModalBottomSheet<bool>(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.white,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _buildSheetHandle(),

                      const SizedBox(height: 14),

                      const Text(
                        'Lọc theo mức lương',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const _FilterSectionTitle(title: 'Đơn vị lương'),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,

                        children: [
                          _choice(
                            label: 'Theo giờ',
                            value: 'HOURLY',
                            current: salaryType,
                            onSelected: (value) {
                              setSheetState(() {
                                salaryType = value;
                              });
                            },
                          ),

                          _choice(
                            label: 'Theo ngày',
                            value: 'DAILY',
                            current: salaryType,
                            onSelected: (value) {
                              setSheetState(() {
                                salaryType = value;
                              });
                            },
                          ),

                          _choice(
                            label: 'Theo ca',
                            value: 'SHIFT',
                            current: salaryType,
                            onSelected: (value) {
                              setSheetState(() {
                                salaryType = value;
                              });
                            },
                          ),

                          _choice(
                            label: 'Theo tháng',
                            value: 'MONTHLY',
                            current: salaryType,
                            onSelected: (value) {
                              setSheetState(() {
                                salaryType = value;
                              });
                            },
                          ),

                          _choice(
                            label: 'Trọn việc',
                            value: 'FIXED',
                            current: salaryType,
                            onSelected: (value) {
                              setSheetState(() {
                                salaryType = value;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const _FilterSectionTitle(title: 'Khoảng lương'),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,

                              keyboardType: TextInputType.number,

                              decoration: const InputDecoration(
                                labelText: 'Từ',

                                hintText: '30000',

                                prefixIcon: Icon(Icons.payments_outlined),

                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: TextField(
                              controller: maxController,

                              keyboardType: TextInputType.number,

                              decoration: const InputDecoration(
                                labelText: 'Đến',

                                hintText: '50000',

                                prefixIcon: Icon(Icons.payments_outlined),

                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                minController.clear();

                                maxController.clear();

                                setSheetState(() {
                                  salaryType = null;
                                });
                              },

                              child: const Text('Đặt lại'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            flex: 2,

                            child: FilledButton(
                              onPressed: () {
                                var min = _parseMoney(minController.text);

                                var max = _parseMoney(maxController.text);

                                // Có nhập mức lương
                                // nhưng chưa chọn đơn vị
                                // → mặc định theo giờ.
                                if ((min != null || max != null) &&
                                    salaryType == null) {
                                  salaryType = 'HOURLY';
                                }

                                if (min != null && max != null && min > max) {
                                  final temp = min;

                                  min = max;

                                  max = temp;
                                }

                                setState(() {
                                  _salaryType = salaryType;

                                  _minSalary = min;

                                  _maxSalary = max;
                                });

                                Navigator.pop(sheetContext, true);
                              },

                              child: const Text('Áp dụng'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    minController.dispose();

    maxController.dispose();

    if (applied == true) {
      await _loadJobs();
    }
  }

  // =====================================================
  // ADVANCED FILTER
  // =====================================================

  Future<void> _showAdvancedFilter() async {
    String? categoryId = _categoryId;

    String? salaryType = _salaryType;

    String? shiftType = _shiftType;

    bool? cvRequired = _cvRequired;

    bool? urgent = _urgent;

    double? distance = _maxDistanceKm;

    final workDays = Set<String>.from(_workDays);

    final skillIds = Set<String>.from(_skillIds);

    String skillSearch = '';

    final minController = TextEditingController(
      text: _minSalary == null ? '' : _minSalary!.round().toString(),
    );

    final maxController = TextEditingController(
      text: _maxSalary == null ? '' : _maxSalary!.round().toString(),
    );

    final result = await showModalBottomSheet<bool>(
      context: context,

      isScrollControlled: true,

      useSafeArea: true,

      backgroundColor: Colors.white,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final visibleSkills = _skills.where((skill) {
              final name = _mapText(skill, 'name').toLowerCase();

              return name.contains(skillSearch.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.92,

              minChildSize: 0.65,

              maxChildSize: 0.96,

              expand: false,

              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 10),

                    _buildSheetHandle(),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),

                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Bộ lọc việc làm',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              minController.clear();

                              maxController.clear();

                              setSheetState(() {
                                categoryId = null;

                                salaryType = null;

                                shiftType = null;

                                cvRequired = null;

                                urgent = null;

                                distance = null;

                                workDays.clear();

                                skillIds.clear();

                                skillSearch = '';
                              });
                            },

                            child: const Text('Đặt lại'),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: ListView(
                        controller: scrollController,

                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),

                        children: [
                          // =============================
                          // CATEGORY
                          // =============================
                          const _FilterSectionTitle(title: 'Lĩnh vực'),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),

                                selected: categoryId == null,

                                onSelected: (_) {
                                  setSheetState(() {
                                    categoryId = null;
                                  });
                                },
                              ),

                              ..._categories.map((category) {
                                final id = _mapText(category, 'id');

                                final name = _mapText(category, 'name');

                                return ChoiceChip(
                                  label: Text(name),

                                  selected: categoryId == id,

                                  onSelected: (_) {
                                    setSheetState(() {
                                      categoryId = id;
                                    });
                                  },
                                );
                              }),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // SHIFT
                          // =============================
                          const _FilterSectionTitle(
                            title: 'Ca làm',
                            subtitle:
                                'Ca chỉ là nhóm lọc; giờ cụ thể vẫn hiển thị trên từng công việc.',
                          ),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: [
                              _choice(
                                label: '🌅 Sáng',
                                value: 'MORNING',
                                current: shiftType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    shiftType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '☀️ Chiều',
                                value: 'AFTERNOON',
                                current: shiftType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    shiftType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '🌆 Tối',
                                value: 'EVENING',
                                current: shiftType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    shiftType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '🌙 Đêm',
                                value: 'NIGHT',
                                current: shiftType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    shiftType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '🔄 Linh hoạt',
                                value: 'FLEXIBLE',
                                current: shiftType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    shiftType = value;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // WORK DAYS
                          // =============================
                          const _FilterSectionTitle(title: 'Ngày làm'),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: _dayOptions.entries.map((entry) {
                              return FilterChip(
                                label: Text(entry.value),

                                selected: workDays.contains(entry.key),

                                onSelected: (selected) {
                                  setSheetState(() {
                                    if (selected) {
                                      workDays.add(entry.key);
                                    } else {
                                      workDays.remove(entry.key);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // SALARY
                          // =============================
                          const _FilterSectionTitle(title: 'Mức lương'),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: [
                              _choice(
                                label: '/ giờ',
                                value: 'HOURLY',
                                current: salaryType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    salaryType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '/ ngày',
                                value: 'DAILY',
                                current: salaryType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    salaryType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '/ ca',
                                value: 'SHIFT',
                                current: salaryType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    salaryType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '/ tháng',
                                value: 'MONTHLY',
                                current: salaryType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    salaryType = value;
                                  });
                                },
                              ),

                              _choice(
                                label: '/ công việc',
                                value: 'FIXED',
                                current: salaryType,
                                onSelected: (value) {
                                  setSheetState(() {
                                    salaryType = value;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minController,

                                  keyboardType: TextInputType.number,

                                  decoration: const InputDecoration(
                                    labelText: 'Từ',
                                    hintText: '30000',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: TextField(
                                  controller: maxController,

                                  keyboardType: TextInputType.number,

                                  decoration: const InputDecoration(
                                    labelText: 'Đến',
                                    hintText: '50000',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // DISTANCE
                          // =============================
                          const _FilterSectionTitle(
                            title: 'Khoảng cách',
                            subtitle: 'Cần vị trí trong hồ sơ Worker.',
                          ),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: [
                              for (final km in const [
                                1.0,
                                3.0,
                                5.0,
                                10.0,
                                20.0,
                              ])
                                ChoiceChip(
                                  label: Text('< ${km.toInt()} km'),

                                  selected: distance == km,

                                  onSelected: (selected) {
                                    setSheetState(() {
                                      distance = selected ? km : null;
                                    });
                                  },
                                ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // CV
                          // =============================
                          const _FilterSectionTitle(title: 'CV'),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),

                                selected: cvRequired == null,

                                onSelected: (_) {
                                  setSheetState(() {
                                    cvRequired = null;
                                  });
                                },
                              ),

                              ChoiceChip(
                                label: const Text('Không cần CV'),

                                selected: cvRequired == false,

                                onSelected: (_) {
                                  setSheetState(() {
                                    cvRequired = false;
                                  });
                                },
                              ),

                              ChoiceChip(
                                label: const Text('Yêu cầu CV'),

                                selected: cvRequired == true,

                                onSelected: (_) {
                                  setSheetState(() {
                                    cvRequired = true;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // URGENT
                          // =============================
                          const _FilterSectionTitle(title: 'Tuyển dụng'),

                          FilterChip(
                            avatar: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                            ),

                            label: const Text('Chỉ hiện việc tuyển gấp'),

                            selected: urgent == true,

                            onSelected: (selected) {
                              setSheetState(() {
                                urgent = selected ? true : null;
                              });
                            },
                          ),

                          const SizedBox(height: 28),

                          // =============================
                          // SKILLS
                          // =============================
                          _FilterSectionTitle(
                            title: 'Kỹ năng',
                            subtitle: skillIds.isEmpty
                                ? 'Không bắt buộc chọn kỹ năng.'
                                : 'Đã chọn ${skillIds.length} kỹ năng.',
                          ),

                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Tìm kỹ năng...',

                              prefixIcon: Icon(Icons.search_rounded),

                              border: OutlineInputBorder(),
                            ),

                            onChanged: (value) {
                              setSheetState(() {
                                skillSearch = value;
                              });
                            },
                          ),

                          const SizedBox(height: 12),

                          if (visibleSkills.isEmpty)
                            Text(
                              'Không tìm thấy kỹ năng.',
                              style: TextStyle(color: Colors.grey.shade600),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,

                              children: visibleSkills.map((skill) {
                                final id = _mapText(skill, 'id');

                                final name = _mapText(skill, 'name');

                                return FilterChip(
                                  label: Text(name),

                                  selected: skillIds.contains(id),

                                  onSelected: (selected) {
                                    setSheetState(() {
                                      if (selected) {
                                        skillIds.add(id);
                                      } else {
                                        skillIds.remove(id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),

                            blurRadius: 16,

                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),

                      child: SizedBox(
                        width: double.infinity,

                        height: 50,

                        child: FilledButton(
                          onPressed: () {
                            var min = _parseMoney(minController.text);

                            var max = _parseMoney(maxController.text);

                            if ((min != null || max != null) &&
                                salaryType == null) {
                              salaryType = 'HOURLY';
                            }

                            if (min != null && max != null && min > max) {
                              final temp = min;

                              min = max;

                              max = temp;
                            }

                            setState(() {
                              _categoryId = categoryId;

                              _salaryType = salaryType;

                              _minSalary = min;

                              _maxSalary = max;

                              _shiftType = shiftType;

                              _workDays
                                ..clear()
                                ..addAll(workDays);

                              _skillIds
                                ..clear()
                                ..addAll(skillIds);

                              _cvRequired = cvRequired;

                              _urgent = urgent;

                              _maxDistanceKm = distance;

                              if (distance != null) {
                                _nearMeOnly = false;
                              }
                            });

                            Navigator.pop(sheetContext, true);
                          },

                          child: const Text('Xem kết quả'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    minController.dispose();

    maxController.dispose();

    if (result == true) {
      await _loadJobs();
    }
  }

  // =====================================================
  // RESET FILTER
  // =====================================================

  Future<void> _resetFilters() async {
    setState(() {
      _categoryId = null;

      _minSalary = null;

      _maxSalary = null;

      _salaryType = null;

      _shiftType = null;

      _workDays.clear();

      _skillIds.clear();

      _cvRequired = null;

      _urgent = null;

      _maxDistanceKm = null;

      _nearMeOnly = false;

      _sort = 'NEWEST';
    });

    await _loadJobs();
  }

  // =====================================================
  // FILTER COUNT
  // =====================================================

  int get _activeFilterCount {
    var count = 0;

    if (_categoryId != null) {
      count++;
    }

    if (_minSalary != null || _maxSalary != null || _salaryType != null) {
      count++;
    }

    if (_shiftType != null) {
      count++;
    }

    if (_workDays.isNotEmpty) {
      count++;
    }

    if (_skillIds.isNotEmpty) {
      count++;
    }

    if (_cvRequired != null) {
      count++;
    }

    if (_urgent == true) {
      count++;
    }

    if (_maxDistanceKm != null) {
      count++;
    }

    return count;
  }

  // =====================================================
  // SORT
  // =====================================================

  Future<void> _changeSort(String value) async {
    setState(() {
      _sort = value;
    });

    await _loadJobs();
  }

  String get _sortText {
    switch (_sort) {
      case 'SALARY_ASC':
        return 'Lương thấp → cao';

      case 'SALARY_DESC':
        return 'Lương cao nhất';

      case 'DISTANCE':
        return 'Gần nhất';

      case 'NEWEST':
      default:
        return 'Mới nhất';
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final displayJobs = _displayJobs;

    final urgentJobs = displayJobs
        .where((job) => job.isUrgent)
        .take(5)
        .toList();

    final aiItems = _visibleRecommendations.take(5).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadJobs(showLoader: false),
            _loadMeta(),
            _loadUnreadNotificationCount(),
          ]);

          if (_aiEnabled) {
            try {
              final result = await _jobService.getRecommendations();

              if (mounted) {
                setState(() {
                  _recommendations = result;
                });
              }
            } catch (_) {}
          }
        },

        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),

              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),

                  const SizedBox(height: 18),

                  _buildSearchBox(),

                  const SizedBox(height: 14),

                  _buildQuickFilters(),

                  if (_categories.isNotEmpty) ...[
                    const SizedBox(height: 22),

                    _buildCategoryQuickList(),
                  ],

                  // ===============================
                  // AI
                  // ===============================
                  if (_aiEnabled && aiItems.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const _SectionTitle(
                      title: '✨ Dành cho bạn',
                      subtitle:
                          'AI ưu tiên những việc phù hợp với hồ sơ của bạn.',
                    ),

                    const SizedBox(height: 12),

                    ...aiItems.map((recommendation) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),

                        child: _AiJobCard(
                          recommendation: recommendation,

                          onTap: () {
                            _openJob(recommendation.job);
                          },
                        ),
                      );
                    }),
                  ],

                  // ===============================
                  // URGENT
                  // ===============================
                  if (urgentJobs.isNotEmpty) ...[
                    const SizedBox(height: 28),

                    const _SectionTitle(
                      title: '🔥 Tuyển gấp',
                      subtitle: 'Những công việc đang cần người sớm.',
                    ),

                    const SizedBox(height: 12),

                    ...urgentJobs.map((job) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),

                        child: _JobCard(
                          job: job,

                          onTap: () {
                            _openJob(job);
                          },
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 28),

                  // ===============================
                  // ALL JOBS HEADER
                  // ===============================
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Tất cả việc làm',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              '$_totalJobs công việc đang phù hợp với bộ lọc',
                              style: TextStyle(
                                color: Colors.grey.shade600,

                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      PopupMenuButton<String>(
                        tooltip: 'Sắp xếp',

                        initialValue: _sort,

                        onSelected: _changeSort,

                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'NEWEST',
                            child: Text('Mới nhất'),
                          ),

                          PopupMenuItem(
                            value: 'DISTANCE',
                            child: Text('Gần nhất'),
                          ),

                          PopupMenuItem(
                            value: 'SALARY_DESC',
                            child: Text('Lương cao nhất'),
                          ),

                          PopupMenuItem(
                            value: 'SALARY_ASC',
                            child: Text('Lương thấp → cao'),
                          ),
                        ],

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(color: Colors.grey.shade200),
                          ),

                          child: Row(
                            children: [
                              Text(
                                _sortText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(width: 4),

                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ===============================
                  // RESULTS
                  // ===============================
                  if (_loading)
                    const _LoadingBox()
                  else if (_error != null)
                    _ErrorBox(
                      message: _error!,

                      onRetry: () {
                        _loadJobs();
                      },
                    )
                  else if (displayJobs.isEmpty)
                    _EmptyBox(
                      icon: Icons.search_off_rounded,

                      title: 'Không tìm thấy việc làm',

                      description:
                          'Thử thay đổi từ khóa hoặc bỏ bớt một số bộ lọc.',

                      actionText: _activeFilterCount > 0 || _nearMeOnly
                          ? 'Xóa bộ lọc'
                          : null,

                      onAction: _activeFilterCount > 0 || _nearMeOnly
                          ? _resetFilters
                          : null,
                    )
                  else
                    ...displayJobs.map((job) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),

                        child: _JobCard(
                          job: job,

                          aiPercentage: _aiPercentageFor(job.id),

                          onTap: () {
                            _openJob(job);
                          },
                        ),
                      );
                    }),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,

          height: 48,

          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.09),

            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.person_rounded,
            color: primaryColor,
            size: 27,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Xin chào 👋',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 2),

              const Text(
                'Tìm việc phù hợp hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),

        _NotificationButton(
          count: _unreadNotificationCount,

          onTap: _openNotifications,
        ),

        const SizedBox(width: 7),

        IconButton(
          tooltip: 'Đăng xuất',

          onPressed: _logout,

          icon: const Icon(Icons.logout_rounded),

          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),

            backgroundColor: const Color(0xFFFEE2E2),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // SEARCH
  // =====================================================

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,

      textInputAction: TextInputAction.search,

      onChanged: _onSearchChanged,

      onSubmitted: (_) {
        _searchDebounce?.cancel();

        _loadJobs();
      },

      decoration: InputDecoration(
        hintText: 'Tìm công việc, địa điểm, lĩnh vực...',

        prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),

        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa',

                onPressed: _clearSearch,

                icon: const Icon(Icons.close_rounded),
              ),

        filled: true,

        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),

          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),

          borderSide: const BorderSide(color: primaryColor, width: 1.4),
        ),
      ),
    );
  }

  // =====================================================
  // QUICK FILTERS
  // =====================================================

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 42,

      child: ListView(
        scrollDirection: Axis.horizontal,

        children: [
          _QuickFilterButton(
            icon: Icons.auto_awesome_rounded,

            label: 'AI',

            selected: _aiEnabled,

            loading: _aiLoading,

            selectedColor: aiColor,

            onTap: _toggleAi,
          ),

          const SizedBox(width: 8),

          _QuickFilterButton(
            icon: Icons.near_me_outlined,

            label: 'Gần tôi',

            selected: _nearMeOnly,

            onTap: _toggleNearMe,
          ),

          const SizedBox(width: 8),

          _QuickFilterButton(
            icon: Icons.payments_outlined,

            label: _salaryQuickText,

            selected:
                _minSalary != null || _maxSalary != null || _salaryType != null,

            onTap: _showSalaryFilter,
          ),

          const SizedBox(width: 8),

          _QuickFilterButton(
            icon: Icons.tune_rounded,

            label: _activeFilterCount == 0
                ? 'Bộ lọc'
                : 'Bộ lọc ($_activeFilterCount)',

            selected: _activeFilterCount > 0,

            onTap: _showAdvancedFilter,
          ),
        ],
      ),
    );
  }

  String get _salaryQuickText {
    if (_minSalary == null && _maxSalary == null && _salaryType == null) {
      return 'Lương';
    }

    if (_minSalary != null && _maxSalary == null) {
      return '≥ ${_compactMoney(_minSalary!)}';
    }

    if (_minSalary == null && _maxSalary != null) {
      return '≤ ${_compactMoney(_maxSalary!)}';
    }

    if (_minSalary != null && _maxSalary != null) {
      return '${_compactMoney(_minSalary!)}-${_compactMoney(_maxSalary!)}';
    }

    return 'Lương';
  }

  // =====================================================
  // CATEGORY QUICK
  // =====================================================

  Widget _buildCategoryQuickList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Lĩnh vực',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 38,

          child: ListView(
            scrollDirection: Axis.horizontal,

            children: [
              ChoiceChip(
                label: const Text('Tất cả'),

                selected: _categoryId == null,

                onSelected: (_) {
                  _selectCategory(null);
                },
              ),

              const SizedBox(width: 8),

              ..._categories.map((category) {
                final id = _mapText(category, 'id');

                final name = _mapText(category, 'name');

                return Padding(
                  padding: const EdgeInsets.only(right: 8),

                  child: ChoiceChip(
                    label: Text(name),

                    selected: _categoryId == id,

                    onSelected: (_) {
                      _selectCategory(id);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // JOB NAVIGATION
  // =====================================================

  void _openJob(Job job) {
    Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
    );
  }

  // =====================================================
  // AI SCORE
  // =====================================================

  int? _aiPercentageFor(String jobId) {
    if (!_aiEnabled) {
      return null;
    }

    for (final recommendation in _recommendations) {
      if (recommendation.job.id == jobId) {
        return recommendation.percentage;
      }
    }

    return null;
  }

  // =====================================================
  // HELPERS
  // =====================================================

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        final message = data['message'];

        if (message is List) {
          return message.join('\n');
        }

        if (message != null) {
          return message.toString();
        }
      }

      if (data is String && data.isNotEmpty) {
        return data;
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối tới máy chủ.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối tới máy chủ quá thời gian.';
      }
    }

    return 'Không thể tải dữ liệu việc làm.';
  }

  double? _parseMoney(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      return null;
    }

    return double.tryParse(cleaned);
  }

  String _compactMoney(double value) {
    if (value >= 1000000) {
      final number = value / 1000000;

      return '${number.toStringAsFixed(number % 1 == 0 ? 0 : 1)}tr';
    }

    if (value >= 1000) {
      final number = value / 1000;

      return '${number.toStringAsFixed(number % 1 == 0 ? 0 : 1)}k';
    }

    return value.round().toString();
  }

  static String _mapText(Map<String, dynamic> map, String key) {
    return map[key]?.toString() ?? '';
  }

  static Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 42,

        height: 5,

        decoration: BoxDecoration(
          color: Colors.grey.shade300,

          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  static ChoiceChip _choice({
    required String label,
    required String value,
    required String? current,
    required ValueChanged<String?> onSelected,
  }) {
    final selected = current == value;

    return ChoiceChip(
      label: Text(label),

      selected: selected,

      onSelected: (_) {
        onSelected(selected ? null : value);
      },
    );
  }
}

// =======================================================
// CONSTANTS
// =======================================================

const Map<String, String> _dayOptions = {
  'MONDAY': 'T2',
  'TUESDAY': 'T3',
  'WEDNESDAY': 'T4',
  'THURSDAY': 'T5',
  'FRIDAY': 'T6',
  'SATURDAY': 'T7',
  'SUNDAY': 'CN',
};

// =======================================================
// QUICK FILTER BUTTON
// =======================================================

class _QuickFilterButton extends StatelessWidget {
  const _QuickFilterButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.loading = false,
    this.selectedColor = const Color(0xFF2563EB),
  });

  final IconData icon;
  final String label;

  final bool selected;
  final bool loading;

  final Color selectedColor;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor.withValues(alpha: 0.09) : Colors.white,

      borderRadius: BorderRadius.circular(12),

      child: InkWell(
        onTap: loading ? null : onTap,

        borderRadius: BorderRadius.circular(12),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: selected ? selectedColor : Colors.grey.shade200,
            ),
          ),

          child: Row(
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,

                  child: CircularProgressIndicator(
                    strokeWidth: 2,

                    color: selectedColor,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,

                  color: selected ? selectedColor : Colors.grey.shade700,
                ),

              const SizedBox(width: 6),

              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,

                  fontWeight: FontWeight.w700,

                  color: selected ? selectedColor : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// SECTION TITLE
// =======================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 4),

          Text(
            subtitle!,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}

// =======================================================
// FILTER TITLE
// =======================================================

class _FilterSectionTitle extends StatelessWidget {
  const _FilterSectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 3),

            Text(
              subtitle!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

// =======================================================
// JOB CARD
// =======================================================

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap, this.aiPercentage});

  final Job job;
  final VoidCallback onTap;

  final int? aiPercentage;

  @override
  Widget build(BuildContext context) {
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

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _CompanyLogo(
                    imageUrl: job.employerLogoUrl,

                    icon: _categoryIcon(job.categoryName),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          job.title,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 15.5,

                            fontWeight: FontWeight.w800,

                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.employerName ?? 'Nhà tuyển dụng',

                                maxLines: 1,

                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  color: Colors.grey.shade600,

                                  fontSize: 12.5,
                                ),
                              ),
                            ),

                            if (job.employerVerified) ...[
                              const SizedBox(width: 4),

                              const Icon(
                                Icons.verified_rounded,

                                color: Color(0xFF2563EB),

                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (aiPercentage != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.09),

                        borderRadius: BorderRadius.circular(9),
                      ),

                      child: Text(
                        '✨ $aiPercentage%',

                        style: const TextStyle(
                          color: Color(0xFF7C3AED),

                          fontSize: 11,

                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              _JobInfoRow(
                icon: Icons.payments_outlined,

                text: job.salaryText,

                highlighted: true,
              ),

              const SizedBox(height: 7),

              _JobInfoRow(
                icon: Icons.location_on_outlined,

                text: job.locationDistanceText,
              ),

              const SizedBox(height: 7),

              _JobInfoRow(icon: Icons.schedule_rounded, text: job.scheduleText),

              const SizedBox(height: 13),

              Wrap(
                spacing: 7,

                runSpacing: 7,

                children: [
                  if (job.categoryName != null)
                    _JobTag(text: job.categoryName!),

                  _JobTag(text: job.cvText, green: !job.cvRequired),

                  if (job.isUrgent)
                    const _JobTag(text: '🔥 Tuyển gấp', urgent: true),

                  ...job.skills.take(2).map((skill) => _JobTag(text: skill)),
                ],
              ),

              if (job.applicationCount > 0) ...[
                const SizedBox(height: 11),

                Text(
                  '${job.applicationCount} người đã ứng tuyển',

                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String? category) {
    final value = category?.toLowerCase() ?? '';

    if (value.contains('ăn') ||
        value.contains('phục vụ') ||
        value.contains('f&b')) {
      return Icons.restaurant_rounded;
    }

    if (value.contains('bán')) {
      return Icons.storefront_rounded;
    }

    if (value.contains('giáo') || value.contains('gia sư')) {
      return Icons.school_rounded;
    }

    if (value.contains('giao') || value.contains('vận chuyển')) {
      return Icons.delivery_dining_rounded;
    }

    if (value.contains('sự kiện')) {
      return Icons.celebration_rounded;
    }

    if (value.contains('it') || value.contains('công nghệ')) {
      return Icons.computer_rounded;
    }

    return Icons.work_rounded;
  }
}

// =======================================================
// AI CARD
// =======================================================

class _AiJobCard extends StatelessWidget {
  const _AiJobCard({required this.recommendation, required this.onTap});

  final JobRecommendation recommendation;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final job = recommendation.job;

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

            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
            ),

            gradient: LinearGradient(
              colors: [
                Colors.white,

                const Color(0xFF7C3AED).withValues(alpha: 0.025),
              ],

              begin: Alignment.topLeft,

              end: Alignment.bottomRight,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: 45,

                    height: 45,

                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.09),

                      borderRadius: BorderRadius.circular(13),
                    ),

                    child: const Icon(
                      Icons.auto_awesome_rounded,

                      color: Color(0xFF7C3AED),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          job.title,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 15,

                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          job.employerName ?? 'Nhà tuyển dụng',

                          style: TextStyle(
                            color: Colors.grey.shade600,

                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.09),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      '${recommendation.percentage}%',

                      style: const TextStyle(
                        color: Color(0xFF7C3AED),

                        fontWeight: FontWeight.w800,

                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              _JobInfoRow(
                icon: Icons.payments_outlined,

                text: job.salaryText,

                highlighted: true,
              ),

              const SizedBox(height: 6),

              _JobInfoRow(
                icon: Icons.location_on_outlined,

                text: job.locationDistanceText,
              ),

              if (recommendation.reasons.isNotEmpty) ...[
                const SizedBox(height: 12),

                Wrap(
                  spacing: 7,

                  runSpacing: 7,

                  children: recommendation.reasons
                      .take(3)
                      .map((reason) => _JobTag(text: reason, ai: true))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// COMPANY LOGO
// =======================================================

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.icon, this.imageUrl});

  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),

        child: Image.network(
          imageUrl!,

          width: 49,

          height: 49,

          fit: BoxFit.cover,

          errorBuilder: (context, error, stackTrace) {
            return _fallback();
          },
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 49,

      height: 49,

      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Icon(icon, color: const Color(0xFF2563EB), size: 25),
    );
  }
}

// =======================================================
// INFO ROW
// =======================================================

class _JobInfoRow extends StatelessWidget {
  const _JobInfoRow({
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  final IconData icon;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,

          size: 16,

          color: highlighted ? const Color(0xFF16A34A) : Colors.grey.shade500,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            text,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: highlighted
                  ? const Color(0xFF15803D)
                  : Colors.grey.shade600,

              fontSize: 12.5,

              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// =======================================================
// TAG
// =======================================================

class _JobTag extends StatelessWidget {
  const _JobTag({
    required this.text,
    this.ai = false,
    this.green = false,
    this.urgent = false,
  });

  final String text;

  final bool ai;
  final bool green;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFF2563EB);

    if (ai) {
      color = const Color(0xFF7C3AED);
    }

    if (green) {
      color = const Color(0xFF16A34A);
    }

    if (urgent) {
      color = const Color(0xFFEA580C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: color,

          fontSize: 10.8,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =======================================================
// NOTIFICATION BUTTON
// =======================================================

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,

      shape: const CircleBorder(),

      child: InkWell(
        onTap: onTap,

        customBorder: const CircleBorder(),

        child: SizedBox(
          width: 45,

          height: 45,

          child: Stack(
            clipBehavior: Clip.none,

            children: [
              const Center(
                child: Icon(Icons.notifications_none_rounded, size: 23),
              ),

              if (count > 0)
                Positioned(
                  right: -2,
                  top: -3,

                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),

                    padding: const EdgeInsets.symmetric(horizontal: 5),

                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),

                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),

                    alignment: Alignment.center,

                    child: Text(
                      count > 99 ? '99+' : count.toString(),

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 9,

                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// LOADING
// =======================================================

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(35),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
      ),

      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// =======================================================
// EMPTY
// =======================================================

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;

  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),

          const SizedBox(height: 12),

          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),

          const SizedBox(height: 6),

          Text(
            description,

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.grey.shade600,

              fontSize: 13,

              height: 1.4,
            ),
          ),

          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 14),

            OutlinedButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

// =======================================================
// ERROR
// =======================================================

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,

            size: 40,

            color: Colors.redAccent,
          ),

          const SizedBox(height: 10),

          Text(message, textAlign: TextAlign.center),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: onRetry,

            icon: const Icon(Icons.refresh_rounded),

            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

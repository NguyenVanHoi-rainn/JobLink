import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';
import 'job_detail_screen.dart';
import 'worker_activity_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _currentIndex = 0;

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _WorkerHomePage(),
      const WorkerActivityScreen(),
      const _MessagesPage(),
      const _ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: primaryColor,
            ),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(
              Icons.work_rounded,
              color: primaryColor,
            ),
            label: 'Hoạt động',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(
              Icons.chat_bubble_rounded,
              color: primaryColor,
            ),
            label: 'Tin nhắn',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: primaryColor,
            ),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

class _WorkerHomePage extends StatefulWidget {
  const _WorkerHomePage();

  @override
  State<_WorkerHomePage> createState() =>
      _WorkerHomePageState();
}

class _WorkerHomePageState
    extends State<_WorkerHomePage> {
  static const Color primaryColor =
  Color(0xFF2563EB);

  final JobService _jobService = JobService();

  List<Job> _jobs = [];
  List<JobRecommendation> _recommendations = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _jobService.getJobs(),
        _jobService.getRecommendations(),
      ]);

      if (!mounted) return;

      setState(() {
        _jobs = results[0] as List<Job>;
        _recommendations =
        results[1] as List<JobRecommendation>;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Không thể tải dữ liệu việc làm';
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildSearchBox(),
                  const SizedBox(height: 22),
                  _buildBanner(),
                  const SizedBox(height: 28),

                  _SectionHeader(
                    title: 'Danh mục việc làm',
                    actionText: 'Xem tất cả',
                    onTap: () {},
                  ),

                  const SizedBox(height: 14),

                  const _CategoryList(),

                  const SizedBox(height: 28),

                  _SectionHeader(
                    title: 'Gợi ý cho bạn',
                    subtitle: 'Được đề xuất bởi AI',
                    actionText: 'Xem thêm',
                    onTap: () {},
                  ),

                  const SizedBox(height: 14),

                  if (_loading)
                    const _LoadingBox()
                  else if (_recommendations.isEmpty)
                    const _EmptyBox(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Chưa có gợi ý phù hợp',
                      description:
                      'Hoàn thiện kỹ năng và hồ sơ để AI gợi ý công việc tốt hơn.',
                    )
                  else
                    ..._recommendations.take(5).map(
                          (recommendation) {
                        final job = recommendation.job;

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        JobDetailScreen(
                                          job: job,
                                        ),
                                  ),
                                );
                              },
                              child: _AiJobCard(
                                title: job.title,
                                company:
                                job.employerName ??
                                    'Nhà tuyển dụng',
                                location:
                                job.location ??
                                    'Chưa cập nhật địa điểm',
                                salary: job.salaryText,
                                match:
                                recommendation.percentage,
                                tags: [
                                  if (job.cvRequired)
                                    'Yêu cầu CV',
                                  if (recommendation
                                      .reasons.isNotEmpty)
                                    recommendation
                                        .reasons.first,
                                ],
                              ),
                            ),
                        );
                      },
                    ),

                  const SizedBox(height: 28),

                  const SizedBox(height: 28),

                  _SectionHeader(
                    title: 'Việc làm gần bạn',
                    actionText: 'Xem tất cả',
                    onTap: () {},
                  ),

                  const SizedBox(height: 14),

                  if (_loading)
                    const _LoadingBox()
                  else if (_error != null)
                    _ErrorBox(
                      message: _error!,
                      onRetry: _loadData,
                    )
                  else if (_jobs.isEmpty)
                      const _EmptyBox(
                        icon: Icons.work_outline_rounded,
                        title: 'Chưa có việc làm',
                        description:
                        'Hiện chưa có công việc phù hợp để hiển thị.',
                      )
                    else
                      ..._jobs.take(10).map(
                            (job) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        JobDetailScreen(
                                          job: job,
                                        ),
                                  ),
                                );
                              },
                              child: _JobCard(
                                title: job.title,
                                company:
                                job.employerName ??
                                    'Nhà tuyển dụng',
                                location:
                                job.location ??
                                    'Chưa cập nhật địa điểm',
                                salary: job.salaryText,
                                time: job.cvRequired
                                    ? 'Yêu cầu CV'
                                    : 'Không bắt buộc CV',
                              ),
                            ),
                          );
                        },
                      ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào 👋',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Người tìm việc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tìm công việc, kỹ năng...',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: primaryColor,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF4F7FF0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tìm việc phù hợp\nnhanh hơn với AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'JobLink phân tích kỹ năng để gợi ý công việc phù hợp với bạn.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context) {
    final categories = [
      const _CategoryData(
        'Phục vụ',
        Icons.restaurant_rounded,
      ),
      const _CategoryData(
        'Bán hàng',
        Icons.storefront_rounded,
      ),
      const _CategoryData(
        'Giao hàng',
        Icons.delivery_dining_rounded,
      ),
      const _CategoryData(
        'Gia sư',
        Icons.school_rounded,
      ),
      const _CategoryData(
        'Sự kiện',
        Icons.celebration_rounded,
      ),
    ];

    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (context, index) {
          final category = categories[index];

          return Container(
            width: 84,
            padding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    category.icon,
                    color: const Color(0xFF2563EB),
                    size: 23,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    required this.actionText,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(actionText),
        ),
      ],
    );
  }
}

class _AiJobCard extends StatelessWidget {
  const _AiJobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.match,
    required this.tags,
  });

  final String title;
  final String company;
  final String location;
  final String salary;
  final int match;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C3AED)
              .withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyLogo(
                icon: Icons.local_cafe_rounded,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      company,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
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
                  color: const Color(0xFF7C3AED)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$match%',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.location_on_outlined,
            text: location,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.payments_outlined,
            text: salary,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ...tags.map(
                    (tag) => _Tag(text: tag),
              ),
              const _Tag(
                text: 'AI phù hợp',
                ai: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.time,
  });

  final String title;
  final String company;
  final String location;
  final String salary;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CompanyLogo(
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  company,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 11),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: location,
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  text: time,
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  text: salary,
                  highlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF2563EB),
        size: 25,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
          color: highlighted
              ? const Color(0xFF16A34A)
              : Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight:
              highlighted ? FontWeight.w700 : FontWeight.w400,
              color: highlighted
                  ? const Color(0xFF16A34A)
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    this.ai = false,
  });

  final String text;
  final bool ai;

  @override
  Widget build(BuildContext context) {
    final color = ai
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 45,
          height: 45,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 23,
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData(
      this.title,
      this.icon,
      );

  final String title;
  final IconData icon;
}


class _MessagesPage extends StatelessWidget {
  const _MessagesPage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Tin nhắn',
      description:
      'Trò chuyện với nhà tuyển dụng và theo dõi các nhóm công việc.',
      icon: Icons.chat_bubble_outline_rounded,
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Hồ sơ',
      description:
      'Hoàn thiện hồ sơ, kỹ năng, CV và lịch rảnh của bạn.',
      icon: Icons.person_outline_rounded,
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB)
                          .withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 42,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 38,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.message,
    required this.onRetry,
  });

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
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
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
    );
  }
}
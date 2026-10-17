import 'package:flutter/material.dart';

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
      const _ActivityPage(),
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

class _WorkerHomePage extends StatelessWidget {
  const _WorkerHomePage();

  static const Color primaryColor = Color(0xFF2563EB);

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

                  const _AiJobCard(
                    title: 'Nhân viên phục vụ ca tối',
                    company: 'The Coffee House',
                    location: 'Thủ Dầu Một',
                    salary: '25.000 - 30.000đ/giờ',
                    match: 92,
                    tags: [
                      'Phục vụ',
                      'Ca tối',
                    ],
                  ),

                  const SizedBox(height: 12),

                  const _AiJobCard(
                    title: 'Nhân viên bán hàng Part-time',
                    company: 'Ministop',
                    location: 'Bình Dương',
                    salary: '28.000đ/giờ',
                    match: 87,
                    tags: [
                      'Bán hàng',
                      'Giao tiếp',
                    ],
                  ),

                  const SizedBox(height: 28),

                  _SectionHeader(
                    title: 'Việc làm gần bạn',
                    actionText: 'Xem tất cả',
                    onTap: () {},
                  ),

                  const SizedBox(height: 14),

                  const _JobCard(
                    title: 'Nhân viên pha chế',
                    company: 'Highlands Coffee',
                    location: '2.1 km',
                    salary: '30.000đ/giờ',
                    time: '17:00 - 22:00',
                  ),

                  const SizedBox(height: 12),

                  const _JobCard(
                    title: 'Nhân viên phục vụ',
                    company: 'Katinat',
                    location: '3.4 km',
                    salary: '25.000đ/giờ',
                    time: '18:00 - 23:00',
                  ),

                  const SizedBox(height: 12),

                  const _JobCard(
                    title: 'Cộng tác viên sự kiện',
                    company: 'Event Media',
                    location: '4.2 km',
                    salary: '300.000đ/ca',
                    time: 'Thứ 7 - Chủ nhật',
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

class _ActivityPage extends StatelessWidget {
  const _ActivityPage();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderPage(
      title: 'Hoạt động',
      description:
      'Theo dõi các công việc bạn đã ứng tuyển và lịch làm việc.',
      icon: Icons.work_history_outlined,
    );
  }
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
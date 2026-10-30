import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/worker_profile.dart';
import '../../services/worker_profile_service.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  static const Color primaryColor = Color(0xFF2563EB);

  static const Color aiColor = Color(0xFF7C3AED);

  final WorkerProfileService _service = WorkerProfileService();

  final TextEditingController _fullNameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _bioController = TextEditingController();

  final TextEditingController _searchAreaController = TextEditingController();

  final TextEditingController _salaryController = TextEditingController();

  final TextEditingController _skillSearchController = TextEditingController();

  WorkerProfile? _profile;

  List<WorkerOption> _categories = [];
  List<WorkerOption> _skills = [];

  final Set<String> _selectedCategoryIds = {};

  final Set<String> _selectedSkillIds = {};

  final Map<String, _EditableAvailability> _availability = {};

  String? _preferredSalaryType;
  int? _maxDistanceKm;

  bool _loading = true;
  bool _saving = false;

  String _skillSearch = '';

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _searchAreaController.dispose();
    _salaryController.dispose();
    _skillSearchController.dispose();

    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getMyProfile(),
        _service.getCategories(),
        _service.getSkills(),
      ]);

      if (!mounted) {
        return;
      }

      final profile = results[0] as WorkerProfile;

      final categories = results[1] as List<WorkerOption>;

      final skills = results[2] as List<WorkerOption>;

      _applyProfile(profile);

      setState(() {
        _profile = profile;
        _categories = categories;
        _skills = skills;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _friendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyProfile(WorkerProfile profile) {
    _fullNameController.text = profile.fullName ?? '';

    _phoneController.text = profile.phone ?? '';

    _bioController.text = profile.bio ?? '';

    _searchAreaController.text = profile.searchArea ?? '';

    _salaryController.text = profile.preferredMinSalary == null
        ? ''
        : profile.preferredMinSalary!.round().toString();

    _preferredSalaryType = profile.preferredSalaryType;

    _maxDistanceKm = profile.maxDistanceKm;

    _selectedSkillIds
      ..clear()
      ..addAll(profile.skills.map((item) => item.id));

    _selectedCategoryIds
      ..clear()
      ..addAll(profile.categories.map((item) => item.id));

    _availability.clear();

    for (final item in profile.availabilities) {
      _availability[item.dayOfWeek] = _EditableAvailability(
        dayOfWeek: item.dayOfWeek,
        startTime: _parseTime(item.startTime),
        endTime: _parseTime(item.endTime),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    double? salary;

    final salaryText = _salaryController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (salaryText.isNotEmpty) {
      salary = double.tryParse(salaryText);

      if (salary == null) {
        _showMessage('Mức lương không hợp lệ');

        return;
      }

      if (_preferredSalaryType == null) {
        _showMessage('Hãy chọn đơn vị lương');

        return;
      }
    }

    for (final item in _availability.values) {
      final start = item.startTime.hour * 60 + item.startTime.minute;

      final end = item.endTime.hour * 60 + item.endTime.minute;

      if (start == end) {
        _showMessage('Giờ bắt đầu và kết thúc không được giống nhau');

        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      final updated = await _service.updateMyProfile(
        fullName: _fullNameController.text,

        phone: _phoneController.text,

        bio: _bioController.text,

        searchArea: _searchAreaController.text,

        preferredMinSalary: salary,

        preferredSalaryType: salary == null ? null : _preferredSalaryType,

        maxDistanceKm: _maxDistanceKm,

        skillIds: _selectedSkillIds.toList(),

        categoryIds: _selectedCategoryIds.toList(),

        availabilities: _availability.values
            .map(
              (item) => {
                'dayOfWeek': item.dayOfWeek,

                'startTime': _formatTime(item.startTime),

                'endTime': _formatTime(item.endTime),
              },
            )
            .toList(),
      );

      if (!mounted) {
        return;
      }

      _applyProfile(updated);

      setState(() {
        _profile = updated;
      });

      _showMessage(
        updated.aiProfile.ready
            ? 'Đã lưu hồ sơ. AI đã sẵn sàng.'
            : 'Đã lưu hồ sơ.',
      );
    } catch (e) {
      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),

        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final profile = _profile;

    if (profile == null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadData,

      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),

        children: [
          _buildHeader(profile),

          const SizedBox(height: 18),

          _buildAiCard(profile),

          const SizedBox(height: 22),

          _ProfileSection(
            title: 'Thông tin cá nhân',

            icon: Icons.person_outline_rounded,

            child: Column(
              children: [
                TextField(
                  controller: _fullNameController,

                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',

                    prefixIcon: Icon(Icons.badge_outlined),

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _phoneController,

                  keyboardType: TextInputType.phone,

                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',

                    prefixIcon: Icon(Icons.phone_outlined),

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _bioController,

                  maxLines: 4,

                  decoration: const InputDecoration(
                    labelText: 'Giới thiệu bản thân',

                    hintText: 'Ví dụ: Sinh viên, có kinh nghiệm bán hàng...',

                    alignLabelWithHint: true,

                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _ProfileSection(
            title: 'Lĩnh vực quan tâm',

            icon: Icons.grid_view_rounded,

            subtitle: 'AI dùng lĩnh vực để ưu tiên loại công việc phù hợp.',

            child: Wrap(
              spacing: 8,

              runSpacing: 8,

              children: _categories.map((category) {
                final selected = _selectedCategoryIds.contains(category.id);

                return FilterChip(
                  label: Text(category.name),

                  selected: selected,

                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedCategoryIds.add(category.id);
                      } else {
                        _selectedCategoryIds.remove(category.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          _ProfileSection(
            title: 'Kỹ năng',

            icon: Icons.psychology_outlined,

            subtitle: 'Chọn những kỹ năng bạn thực sự có.',

            child: Column(
              children: [
                TextField(
                  controller: _skillSearchController,

                  onChanged: (value) {
                    setState(() {
                      _skillSearch = value.trim();
                    });
                  },

                  decoration: const InputDecoration(
                    hintText: 'Tìm kỹ năng...',

                    prefixIcon: Icon(Icons.search_rounded),

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,

                  child: Wrap(
                    spacing: 8,

                    runSpacing: 8,

                    children: _visibleSkills.map((skill) {
                      final selected = _selectedSkillIds.contains(skill.id);

                      return FilterChip(
                        label: Text(skill.name),

                        selected: selected,

                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedSkillIds.add(skill.id);
                            } else {
                              _selectedSkillIds.remove(skill.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                if (_visibleSkills.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),

                    child: Text(
                      'Không tìm thấy kỹ năng.',

                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _ProfileSection(
            title: 'Khu vực muốn làm',

            icon: Icons.location_on_outlined,

            subtitle: 'Bạn có thể nhập quận, thành phố hoặc khu vực mong muốn.',

            child: Column(
              children: [
                TextField(
                  controller: _searchAreaController,

                  decoration: const InputDecoration(
                    labelText: 'Khu vực tìm việc',

                    hintText: 'Ví dụ: Thủ Dầu Một, Bình Dương',

                    prefixIcon: Icon(Icons.map_outlined),

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<int>(
                  initialValue: _maxDistanceKm,

                  decoration: const InputDecoration(
                    labelText: 'Khoảng cách mong muốn',

                    prefixIcon: Icon(Icons.near_me_outlined),

                    border: OutlineInputBorder(),
                  ),

                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Trong 1 km')),

                    DropdownMenuItem(value: 3, child: Text('Trong 3 km')),

                    DropdownMenuItem(value: 5, child: Text('Trong 5 km')),

                    DropdownMenuItem(value: 10, child: Text('Trong 10 km')),

                    DropdownMenuItem(value: 20, child: Text('Trong 20 km')),

                    DropdownMenuItem(value: 50, child: Text('Trong 50 km')),
                  ],

                  onChanged: (value) {
                    setState(() {
                      _maxDistanceKm = value;
                    });
                  },
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,

                      size: 16,

                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        'Lọc chính xác theo km sẽ dùng tọa độ khi tích hợp Google Maps/GPS.',

                        style: TextStyle(
                          color: Colors.grey.shade600,

                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _ProfileSection(
            title: 'Mức lương mong muốn',

            icon: Icons.payments_outlined,

            child: Column(
              children: [
                TextField(
                  controller: _salaryController,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: 'Mức tối thiểu',

                    hintText: 'Ví dụ: 30000',

                    prefixIcon: Icon(Icons.payments_outlined),

                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _preferredSalaryType,

                  decoration: const InputDecoration(
                    labelText: 'Đơn vị lương',

                    border: OutlineInputBorder(),
                  ),

                  items: const [
                    DropdownMenuItem(value: 'HOURLY', child: Text('Theo giờ')),

                    DropdownMenuItem(value: 'DAILY', child: Text('Theo ngày')),

                    DropdownMenuItem(value: 'SHIFT', child: Text('Theo ca')),

                    DropdownMenuItem(
                      value: 'MONTHLY',
                      child: Text('Theo tháng'),
                    ),

                    DropdownMenuItem(
                      value: 'FIXED',
                      child: Text('Trọn công việc'),
                    ),
                  ],

                  onChanged: (value) {
                    setState(() {
                      _preferredSalaryType = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _buildAvailabilitySection(),

          const SizedBox(height: 18),

          _buildCvSection(profile),

          const SizedBox(height: 24),

          SizedBox(
            height: 54,

            child: FilledButton.icon(
              onPressed: _saving ? null : _save,

              icon: _saving
                  ? const SizedBox(
                      width: 18,

                      height: 18,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),

              label: Text(_saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WorkerProfile profile) {
    final name = profile.fullName?.trim();

    return Row(
      children: [
        Container(
          width: 58,

          height: 58,

          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),

            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.person_rounded,

            color: primaryColor,

            size: 32,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                name == null || name.isEmpty ? 'Hồ sơ Worker' : name,

                style: const TextStyle(
                  fontSize: 21,

                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                profile.email,

                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Tải lại',

          onPressed: _loadData,

          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildAiCard(WorkerProfile profile) {
    final ai = profile.aiProfile;

    final ready = ai.ready;

    final color = ready ? const Color(0xFF16A34A) : aiColor;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 44,

                height: 44,

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(
                  ready
                      ? Icons.check_circle_rounded
                      : Icons.auto_awesome_rounded,

                  color: color,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      ready ? 'AI đã sẵn sàng' : 'Hồ sơ AI',

                      style: const TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      ready
                          ? 'JobLink có thể dùng hồ sơ này để gợi ý việc làm.'
                          : 'Hoàn thiện thêm để nhận gợi ý chính xác hơn.',

                      style: TextStyle(
                        color: Colors.grey.shade600,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${ai.completionPercent}%',

                style: TextStyle(
                  color: color,

                  fontSize: 18,

                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),

            child: LinearProgressIndicator(
              value: ai.completionPercent / 100,

              minHeight: 8,

              backgroundColor: color.withValues(alpha: 0.1),

              color: color,
            ),
          ),

          if (!ready && ai.missingFields.isNotEmpty) ...[
            const SizedBox(height: 15),

            Wrap(
              spacing: 7,

              runSpacing: 7,

              children: ai.missingFields
                  .map((field) => _MissingTag(text: _missingFieldText(field)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return _ProfileSection(
      title: 'Lịch rảnh',

      icon: Icons.calendar_month_outlined,

      subtitle: 'Chọn ngày và khoảng thời gian bạn có thể làm.',

      child: Column(
        children: _days.entries.map((entry) {
          final day = entry.key;

          final enabled = _availability.containsKey(day);

          final item = _availability[day];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),

              borderRadius: BorderRadius.circular(14),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value,

                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),

                    Switch(
                      value: enabled,

                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            _availability[day] = _EditableAvailability(
                              dayOfWeek: day,

                              startTime: const TimeOfDay(hour: 8, minute: 0),

                              endTime: const TimeOfDay(hour: 17, minute: 0),
                            );
                          } else {
                            _availability.remove(day);
                          }
                        });
                      },
                    ),
                  ],
                ),

                if (enabled && item != null) ...[
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _TimeButton(
                          label: 'Bắt đầu',

                          time: item.startTime,

                          onTap: () async {
                            final selected = await showTimePicker(
                              context: context,

                              initialTime: item.startTime,
                            );

                            if (selected == null || !mounted) {
                              return;
                            }

                            setState(() {
                              item.startTime = selected;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _TimeButton(
                          label: 'Kết thúc',

                          time: item.endTime,

                          onTap: () async {
                            final selected = await showTimePicker(
                              context: context,

                              initialTime: item.endTime,
                            );

                            if (selected == null || !mounted) {
                              return;
                            }

                            setState(() {
                              item.endTime = selected;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCvSection(WorkerProfile profile) {
    return _ProfileSection(
      title: 'CV',

      icon: Icons.description_outlined,

      subtitle: 'CV không bắt buộc để sử dụng AI.',

      child: profile.cvs.isEmpty
          ? Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),

                borderRadius: BorderRadius.circular(14),
              ),

              child: Text(
                'Bạn chưa tải CV lên.',

                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : Column(
              children: profile.cvs.map((cv) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: const CircleAvatar(
                    child: Icon(Icons.description_outlined),
                  ),

                  title: Text(
                    cv.fileName,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,
                  ),

                  subtitle: const Text('CV đã tải lên'),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.cloud_off_rounded,

              size: 50,

              color: Colors.redAccent,
            ),

            const SizedBox(height: 14),

            Text(
              _error ?? 'Không thể tải hồ sơ Worker.',

              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _loadData,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  List<WorkerOption> get _visibleSkills {
    if (_skillSearch.isEmpty) {
      return _skills;
    }

    final keyword = _skillSearch.toLowerCase();

    return _skills.where((skill) {
      return skill.name.toLowerCase().contains(keyword);
    }).toList();
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
    }

    return 'Không thể xử lý hồ sơ Worker.';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');

    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;

    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  static String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  static String _missingFieldText(String value) {
    switch (value) {
      case 'SKILLS':
        return 'Kỹ năng';

      case 'CATEGORIES':
        return 'Lĩnh vực';

      case 'LOCATION':
        return 'Khu vực';

      case 'SALARY':
        return 'Mức lương';

      case 'AVAILABILITY':
        return 'Lịch rảnh';

      default:
        return value;
    }
  }
}

class _EditableAvailability {
  final String dayOfWeek;

  TimeOfDay startTime;
  TimeOfDay endTime;

  _EditableAvailability({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });
}

const Map<String, String> _days = {
  'MONDAY': 'Thứ Hai',
  'TUESDAY': 'Thứ Ba',
  'WEDNESDAY': 'Thứ Tư',
  'THURSDAY': 'Thứ Năm',
  'FRIDAY': 'Thứ Sáu',
  'SATURDAY': 'Thứ Bảy',
  'SUNDAY': 'Chủ Nhật',
};

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 38,

                height: 38,

                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),

                  borderRadius: BorderRadius.circular(11),
                ),

                child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 2),

                      Text(
                        subtitle!,

                        style: TextStyle(
                          color: Colors.grey.shade600,

                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          child,
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,

      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),

      child: Column(
        children: [
          Text(
            label,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),

          const SizedBox(height: 3),

          Text(
            '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}',

            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MissingTag extends StatelessWidget {
  const _MissingTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        '○ $text',

        style: const TextStyle(
          color: Color(0xFF7C3AED),

          fontSize: 11,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

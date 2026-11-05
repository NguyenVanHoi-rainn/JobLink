import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'job_location_picker_screen.dart';
import '../../services/employer_job_service.dart';

class EmployerEditJobScreen extends StatefulWidget {
  const EmployerEditJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<EmployerEditJobScreen> createState() => _EmployerEditJobScreenState();
}

class _EmployerEditJobScreenState extends State<EmployerEditJobScreen> {
  static const Color _primary = Color(0xFF2563EB);

  final EmployerJobService _service = EmployerJobService();

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();

  // Tọa độ vị trí
  double? _latitude;
  double? _longitude;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _skills = [];

  final Set<String> _selectedSkillIds = {};
  final Set<String> _selectedWorkDays = {};

  String? _categoryId;
  String? _originalCategoryId;

  String _status = 'DRAFT';

  String _salaryType = 'HOURLY';
  String _shiftType = 'FLEXIBLE';

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _urgent = false;
  DateTime? _urgentUntil;

  bool _cvRequired = false;

  DateTime? _deadline;
  bool _deadlineCleared = false;

  bool _loading = true;
  bool _saving = false;

  String? _error;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    _load();
  }

  // =====================================================
  // LOAD
  // =====================================================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getMyJobById(widget.jobId),
        _service.getCategories(),
        _service.getSkills(),
      ]);

      if (!mounted) {
        return;
      }

      final job = results[0] as Map<String, dynamic>;
      final categories = (results[1] as List)
          .whereType()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final skills = (results[2] as List)
          .whereType()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      // =================================================
      // BASIC
      // =================================================

      _titleController.text = job['title']?.toString() ?? '';
      _descriptionController.text = job['description']?.toString() ?? '';
      _salaryController.text = _numberText(job['salary']);
      _locationController.text = job['location']?.toString() ?? '';

      // Tọa độ
      _latitude = _toDouble(job['latitude']);
      _longitude = _toDouble(job['longitude']);

      // =================================================
      // CATEGORY
      // =================================================

      final category = _asMap(job['category']);

      _categoryId =
          job['categoryId']?.toString() ?? category?['id']?.toString();

      _originalCategoryId = _categoryId;

      if (_categoryId != null &&
          !categories.any((item) => item['id']?.toString() == _categoryId)) {
        if (category != null) {
          categories.add(category);
        }
      }

      // =================================================
      // STATUS
      // =================================================

      _status = job['status']?.toString() ?? 'DRAFT';

      // =================================================
      // SALARY TYPE
      // =================================================

      final salaryType = job['salaryType']?.toString();
      if (_salaryTypes.contains(salaryType)) {
        _salaryType = salaryType!;
      }

      // =================================================
      // SHIFT TYPE
      // =================================================

      final shiftType = job['shiftType']?.toString();
      if (_shiftTypes.contains(shiftType)) {
        _shiftType = shiftType!;
      }

      // =================================================
      // TIME
      // =================================================

      _startTime =
          _parseTime(job['startTime']) ?? const TimeOfDay(hour: 8, minute: 0);
      _endTime =
          _parseTime(job['endTime']) ?? const TimeOfDay(hour: 17, minute: 0);

      // =================================================
      // WORK DAYS
      // =================================================

      _selectedWorkDays.clear();
      final workDays = job['workDays'];
      if (workDays is List) {
        for (final day in workDays) {
          final value = day.toString();
          if (_days.containsKey(value)) {
            _selectedWorkDays.add(value);
          }
        }
      }

      // =================================================
      // URGENT
      // =================================================

      _urgent = job['urgent'] == true;
      final urgentUntilRaw = job['urgentUntil']?.toString();
      _urgentUntil = null;
      if (urgentUntilRaw != null && urgentUntilRaw.isNotEmpty) {
        _urgentUntil = DateTime.tryParse(urgentUntilRaw)?.toLocal();
      }

      // =================================================
      // CV
      // =================================================

      _cvRequired = job['cvRequired'] == true;

      // =================================================
      // DEADLINE
      // =================================================

      _deadline = null;
      _deadlineCleared = false;
      final deadlineRaw = job['deadline']?.toString();
      if (deadlineRaw != null && deadlineRaw.isNotEmpty) {
        _deadline = DateTime.tryParse(deadlineRaw)?.toLocal();
      }

      // =================================================
      // SKILLS
      // =================================================

      _selectedSkillIds.clear();
      final jobSkills = job['jobSkills'];
      if (jobSkills is List) {
        for (final item in jobSkills) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final skill = _asMap(map['skill']);
          final id = map['skillId']?.toString() ?? skill?['id']?.toString();
          if (id != null && id.isNotEmpty) {
            _selectedSkillIds.add(id);
          }
        }
      }

      setState(() {
        _categories = categories;
        _skills = skills;
      });
    } catch (error) {
      debugPrint('Load edit job failed: $error');
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải thông tin tin tuyển dụng';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =====================================================
  // DEADLINE
  // =====================================================

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    var initialDate = _deadline ?? tomorrow.add(const Duration(days: 6));
    final initialOnlyDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );

    if (initialOnlyDate.isBefore(today)) {
      initialDate = tomorrow;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        selected.year,
        selected.month,
        selected.day,
        23,
        59,
        59,
      );
      _deadlineCleared = false;
    });
  }

  void _clearDeadline() {
    setState(() {
      _deadline = null;
      _deadlineCleared = true;
    });
  }

  // =====================================================
  // URGENT UNTIL
  // =====================================================

  Future<void> _pickUrgentUntil() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var initialDate = _urgentUntil ?? today.add(const Duration(days: 2));
    final initialOnlyDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );

    if (initialOnlyDate.isBefore(today)) {
      initialDate = today;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _urgentUntil = DateTime(
        selected.year,
        selected.month,
        selected.day,
        23,
        59,
        59,
      );
    });
  }

  // =====================================================
  // TIME
  // =====================================================

  Future<void> _pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startTime = selected;
    });
  }

  Future<void> _pickEndTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _endTime = selected;
    });
  }

  // =====================================================
  // SAVE
  // =====================================================

  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null || _categoryId!.isEmpty) {
      _showMessage('Vui lòng chọn danh mục');
      return;
    }

    final salary = _parseSalary(_salaryController.text);
    if (salary == null || salary <= 0) {
      _showMessage('Mức lương không hợp lệ');
      return;
    }

    if (_selectedWorkDays.isEmpty) {
      _showMessage('Vui lòng chọn ít nhất một ngày làm việc');
      return;
    }

    if (_startTime.hour == _endTime.hour &&
        _startTime.minute == _endTime.minute) {
      _showMessage('Giờ bắt đầu và giờ kết thúc không được giống nhau');
      return;
    }

    if (_urgent && _urgentUntil == null) {
      _showMessage('Vui lòng chọn ngày kết thúc tuyển gấp');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _service.updateJob(
        jobId: widget.jobId,
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _categoryId != _originalCategoryId ? _categoryId : null,
        salary: salary,
        salaryType: _salaryType,
        location: _locationController.text,
        latitude: _latitude,
        longitude: _longitude,
        shiftType: _shiftType,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        workDays: _orderedWorkDays(),
        urgent: _urgent,
        urgentUntil: _urgent ? _urgentUntil : null,
        clearUrgentUntil: !_urgent,
        cvRequired: _cvRequired,
        deadline: _deadline,
        clearDeadline: _deadlineCleared,
        skillIds: _selectedSkillIds.toList(),
      );

      if (!mounted) return;

      _showMessage('Cập nhật tin tuyển dụng thành công');
      Navigator.pop(context, true);
    } on DioException catch (error) {
      _showMessage(_dioMessage(error) ?? 'Không thể cập nhật tin tuyển dụng');
    } catch (error) {
      debugPrint('Update job failed: $error');
      _showMessage('Không thể cập nhật tin tuyển dụng');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Sửa tin tuyển dụng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == 'HIDDEN') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tin tuyển dụng đang bị Admin ẩn nên hiện tại không thể chỉnh sửa.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 14),

          // =================================================
          // BASIC
          // =================================================
          _section(
            title: 'Thông tin công việc',
            children: [
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  label: 'Tên công việc *',
                  icon: Icons.work_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên công việc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 5,
                maxLines: 8,
                decoration: _inputDecoration(
                  label: 'Mô tả công việc *',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: 'Danh mục *',
                  icon: Icons.category_outlined,
                ),
                items: _categories.where((item) => item['id'] != null).map((item) {
                  final id = item['id'].toString();
                  final name = item['name']?.toString() ?? 'Danh mục';
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn danh mục';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // SALARY
          // =================================================
          _section(
            title: 'Mức lương',
            children: [
              TextFormField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  label: 'Mức lương *',
                  icon: Icons.payments_outlined,
                  suffix: 'VNĐ',
                ),
                validator: (value) {
                  final salary = _parseSalary(value ?? '');
                  if (salary == null || salary <= 0) {
                    return 'Mức lương không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _salaryType,
                decoration: _inputDecoration(
                  label: 'Đơn vị lương *',
                  icon: Icons.price_change_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'HOURLY', child: Text('Theo giờ')),
                  DropdownMenuItem(value: 'DAILY', child: Text('Theo ngày')),
                  DropdownMenuItem(value: 'SHIFT', child: Text('Theo ca')),
                  DropdownMenuItem(value: 'MONTHLY', child: Text('Theo tháng')),
                  DropdownMenuItem(value: 'FIXED', child: Text('Trọn công việc')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _salaryType = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // LOCATION & MAP PICKER
          // =================================================
          _section(
            title: 'Địa điểm',
            children: [
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(
                  label: 'Địa điểm làm việc *',
                  icon: Icons.location_on_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa điểm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<JobLocationResult>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobLocationPickerScreen(
                        initialLatitude: _latitude,
                        initialLongitude: _longitude,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _latitude = result.latitude;
                      _longitude = result.longitude;
                    });
                  }
                },
                icon: Icon(
                  _latitude != null ? Icons.check_circle_rounded : Icons.map_outlined,
                  color: _latitude != null ? Colors.green : _primary,
                ),
                label: Text(
                  _latitude != null
                      ? 'Đã ghim vị trí (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                      : 'Chọn vị trí trên bản đồ',
                  style: TextStyle(
                    color: _latitude != null ? Colors.green.shade700 : _primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // SCHEDULE
          // =================================================
          _section(
            title: 'Ca và lịch làm việc',
            subtitle: 'Khung giờ áp dụng cho các ngày đã chọn.',
            children: [
              DropdownButtonFormField<String>(
                initialValue: _shiftType,
                decoration: _inputDecoration(
                  label: 'Ca làm *',
                  icon: Icons.schedule_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 'MORNING', child: Text('Ca sáng')),
                  DropdownMenuItem(value: 'AFTERNOON', child: Text('Ca chiều')),
                  DropdownMenuItem(value: 'EVENING', child: Text('Ca tối')),
                  DropdownMenuItem(value: 'NIGHT', child: Text('Ca đêm')),
                  DropdownMenuItem(value: 'FLEXIBLE', child: Text('Linh hoạt')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _shiftType = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TimeSelector(
                      title: 'Bắt đầu',
                      time: _startTime,
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeSelector(
                      title: 'Kết thúc',
                      time: _endTime,
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Ngày làm việc *',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.entries.map((entry) {
                  final selected = _selectedWorkDays.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedWorkDays.add(entry.key);
                        } else {
                          _selectedWorkDays.remove(entry.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // URGENT
          // =================================================
          _section(
            title: 'Tuyển gấp',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _urgent,
                activeThumbColor: const Color(0xFFEA580C),
                secondary: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFEA580C),
                ),
                title: const Text(
                  'Đánh dấu tuyển gấp',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Worker có thể lọc các tin đang tuyển gấp.',
                ),
                onChanged: (value) {
                  setState(() {
                    _urgent = value;
                    if (!value) {
                      _urgentUntil = null;
                    }
                  });
                },
              ),
              if (_urgent) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text(
                    'Tuyển gấp đến *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _urgentUntil == null
                        ? 'Chọn ngày kết thúc'
                        : _formatDate(_urgentUntil!),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickUrgentUntil,
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // APPLICATION REQUIREMENTS
          // =================================================
          _section(
            title: 'Yêu cầu ứng tuyển',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Yêu cầu CV',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Worker phải chọn CV khi ứng tuyển'),
                value: _cvRequired,
                activeThumbColor: _primary,
                onChanged: (value) {
                  setState(() {
                    _cvRequired = value;
                  });
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text(
                  'Hạn ứng tuyển',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _deadline == null ? 'Không đặt hạn' : _formatDate(_deadline!),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickDeadline,
              ),
              if (_deadline != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _clearDeadline,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Bỏ hạn ứng tuyển'),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // SKILLS
          // =================================================
          _section(
            title: 'Kỹ năng',
            subtitle: 'Không bắt buộc',
            children: [
              if (_skills.isEmpty)
                Text(
                  'Chưa có kỹ năng.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) {
                    final id = skill['id']?.toString();
                    final name = skill['name']?.toString() ?? 'Kỹ năng';
                    final selected =
                        id != null && _selectedSkillIds.contains(id);

                    return FilterChip(
                      label: Text(name),
                      selected: selected,
                      onSelected: id == null
                          ? null
                          : (value) {
                        setState(() {
                          if (value) {
                            _selectedSkillIds.add(id);
                          } else {
                            _selectedSkillIds.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
            ],
          ),

          const SizedBox(height: 22),

          // =================================================
          // SAVE
          // =================================================
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              backgroundColor: _primary,
            ),
            icon: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.save_outlined),
            label: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // STATUS CARD
  // =====================================================

  Widget _buildStatusCard() {
    final (label, icon, color) = switch (_status) {
      'PUBLISHED' => ('Đang tuyển', Icons.public_rounded, Colors.green),
      'CLOSED' => ('Đã đóng', Icons.lock_outline_rounded, Colors.orange),
      _ => ('Bản nháp', Icons.edit_note_rounded, Colors.blueGrey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Trạng thái tin',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SECTION
  // =====================================================

  Widget _section({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // =====================================================
  // INPUT DECORATION
  // =====================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixText: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  // =====================================================
  // API ERROR
  // =====================================================

  String? _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is List) {
        return message.join(', ');
      }
      return message?.toString();
    }
    return null;
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  // =====================================================
  // HELPERS
  // =====================================================

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double? _parseSalary(String value) {
    final normalized = value
        .trim()
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceAll(' ', '');
    return double.tryParse(normalized);
  }

  String _numberText(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '');
    if (number == null) return '';
    if (number == number.roundToDouble()) {
      return number.round().toString();
    }
    return number.toString();
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final date = DateTime.tryParse(text);
    if (date != null) {
      final utc = date.toUtc();
      return TimeOfDay(hour: utc.hour, minute: utc.minute);
    }

    final parts = text.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  List<String> _orderedWorkDays() {
    return _days.keys.where(_selectedWorkDays.contains).toList();
  }

  static String _formatDate(DateTime value) {
    String two(int number) {
      return number.toString().padLeft(2, '0');
    }
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

// =======================================================
// TIME SELECTOR
// =======================================================

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.title,
    required this.time,
    required this.onTap,
  });

  final String title;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_rounded, size: 17),
              const SizedBox(width: 5),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================================================
// CONSTANTS
// =======================================================

const Set<String> _salaryTypes = {
  'HOURLY',
  'DAILY',
  'SHIFT',
  'MONTHLY',
  'FIXED',
};

const Set<String> _shiftTypes = {
  'MORNING',
  'AFTERNOON',
  'EVENING',
  'NIGHT',
  'FLEXIBLE',
};

const Map<String, String> _days = {
  'MONDAY': 'T2',
  'TUESDAY': 'T3',
  'WEDNESDAY': 'T4',
  'THURSDAY': 'T5',
  'FRIDAY': 'T6',
  'SATURDAY': 'T7',
  'SUNDAY': 'CN',
};
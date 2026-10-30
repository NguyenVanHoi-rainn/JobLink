import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'job_location_picker_screen.dart';
import '../../services/employer_job_service.dart';

class EmployerCreateJobScreen extends StatefulWidget {
  const EmployerCreateJobScreen({super.key});

  @override
  State<EmployerCreateJobScreen> createState() =>
      _EmployerCreateJobScreenState();
}

class _EmployerCreateJobScreenState extends State<EmployerCreateJobScreen> {
  static const Color _primary = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();

  final _descriptionController = TextEditingController();

  final _salaryController = TextEditingController();

  final _locationController = TextEditingController();

  final EmployerJobService _service = EmployerJobService();

  // =====================================================
  // META
  // =====================================================

  List<Map<String, dynamic>> _categories = [];

  List<Map<String, dynamic>> _skills = [];

  final Set<String> _selectedSkillIds = {};

  final Set<String> _selectedWorkDays = {};

  // =====================================================
  // JOB STATE
  // =====================================================

  String? _categoryId;

  String _salaryType = 'HOURLY';

  String _shiftType = 'FLEXIBLE';

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);

  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _urgent = false;

  DateTime? _urgentUntil;

  bool _cvRequired = false;

  DateTime? _deadline;

  bool _loadingMeta = true;

  bool _submitting = false;

  String? _metaError;

  double? _latitude;

  double? _longitude;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    _loadMeta();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });

    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getSkills(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = results[0];
        _skills = results[1];

        if (_categories.isNotEmpty) {
          _categoryId = _categories.first['id']?.toString();
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _metaError = 'Không thể tải danh mục và kỹ năng';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMeta = false;
        });
      }
    }
  }

  // =====================================================
  // PICK TIME
  // =====================================================

  Future<void> _pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startTime = selected;
    });
  }

  Future<void> _pickEndTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endTime = selected;
    });
  }

  // =====================================================
  // DEADLINE
  // =====================================================

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    final selected = await showDatePicker(
      context: context,

      initialDate: _deadline ?? tomorrow.add(const Duration(days: 6)),

      firstDate: tomorrow,

      lastDate: tomorrow.add(const Duration(days: 365)),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _deadline = DateTime(
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
  // URGENT UNTIL
  // =====================================================

  Future<void> _pickUrgentUntil() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final selected = await showDatePicker(
      context: context,

      initialDate: _urgentUntil ?? today.add(const Duration(days: 2)),

      firstDate: today,

      lastDate: today.add(const Duration(days: 30)),
    );

    if (selected == null || !mounted) {
      return;
    }

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
  // SUBMIT
  // =====================================================

  Future<void> _submit({required bool publishAfterCreate}) async {
    if (_submitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryId == null || _categoryId!.isEmpty) {
      _showMessage('Vui lòng chọn danh mục');

      return;
    }

    if (_selectedWorkDays.isEmpty) {
      _showMessage('Vui lòng chọn ít nhất một ngày làm việc');

      return;
    }

    if (_startTime.hour == _endTime.hour &&
        _startTime.minute == _endTime.minute) {
      _showMessage('Giờ bắt đầu và kết thúc không được giống nhau');

      return;
    }

    if (_urgent && _urgentUntil == null) {
      _showMessage('Vui lòng chọn ngày kết thúc tuyển gấp');

      return;
    }

    final salary = double.tryParse(
      _salaryController.text.trim().replaceAll(',', '').replaceAll('.', ''),
    );

    if (salary == null || salary <= 0) {
      _showMessage('Mức lương không hợp lệ');

      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final created = await _service.createJob(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _categoryId!,
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
        cvRequired: _cvRequired,
        deadline: _deadline,
        skillIds: _selectedSkillIds.toList(),
      );

      // =================================================
      // PUBLISH AFTER CREATE
      // =================================================

      if (publishAfterCreate) {
        final id = created['id']?.toString();

        if (id == null || id.isEmpty) {
          throw StateError('Backend không trả job id');
        }

        try {
          await _service.publishJob(id);
        } on DioException catch (e) {
          if (!mounted) {
            return;
          }

          await showDialog<void>(
            context: context,

            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Đã lưu bản nháp'),

                content: Text(
                  'Tin đã được tạo nhưng chưa thể đăng.\n\n'
                  '${_dioMessage(e) ?? 'Hãy kiểm tra trạng thái xác minh Employer.'}',
                ),

                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },

                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );

          if (!mounted) {
            return;
          }

          Navigator.pop(context, true);

          return;
        }
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        publishAfterCreate ? 'Đăng tin thành công' : 'Đã lưu bản nháp',
      );

      Navigator.pop(context, true);
    } on DioException catch (e) {
      _showMessage(_dioMessage(e) ?? 'Không thể tạo tin tuyển dụng');
    } catch (e) {
      debugPrint('Create job failed: $e');

      _showMessage('Không thể tạo tin tuyển dụng');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
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
          'Đăng tin tuyển dụng',

          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : _metaError != null
          ? _buildMetaError()
          : _buildForm(),
    );
  }

  Widget _buildMetaError() {
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

            Text(_metaError!, textAlign: TextAlign.center),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: _loadMeta,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,

      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),

        children: [
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

                minLines: 4,

                maxLines: 7,

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

                items: _categories
                    .where((item) => item['id'] != null)
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['id'].toString(),

                        child: Text(
                          item['name']?.toString() ?? 'Danh mục',

                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),

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

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),

                decoration: _inputDecoration(
                  label: 'Mức lương *',

                  icon: Icons.payments_outlined,

                  suffix: 'VNĐ',
                ),

                validator: (value) {
                  final text = (value ?? '')
                      .trim()
                      .replaceAll(',', '')
                      .replaceAll('.', '');

                  final number = double.tryParse(text);

                  if (number == null || number <= 0) {
                    return 'Vui lòng nhập mức lương hợp lệ';
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

                  DropdownMenuItem(
                    value: 'FIXED',

                    child: Text('Trọn công việc'),
                  ),
                ],

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _salaryType = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // LOCATION
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
                      : 'Chọn vị trí trên Google Maps',
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

            subtitle: 'Khoảng giờ này áp dụng cho tất cả ngày được chọn.',

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
                  if (value == null) {
                    return;
                  }

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

                title: const Text(
                  'Đánh dấu tuyển gấp',

                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                subtitle: const Text(
                  'Tin sẽ được ưu tiên trong mục Tuyển gấp của Worker.',
                ),

                secondary: const Icon(
                  Icons.local_fire_department_rounded,

                  color: Color(0xFFEA580C),
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
          // APPLY REQUIREMENTS
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
                  _deadline == null
                      ? 'Không bắt buộc'
                      : _formatDate(_deadline!),
                ),

                trailing: const Icon(Icons.chevron_right_rounded),

                onTap: _pickDeadline,
              ),

              if (_deadline != null)
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _deadline = null;
                      });
                    },

                    child: const Text('Bỏ hạn ứng tuyển'),
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
                  'Chưa có kỹ năng để chọn.',

                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                Wrap(
                  spacing: 8,

                  runSpacing: 8,

                  children: _skills.map((item) {
                    final id = item['id']?.toString();

                    final name = item['name']?.toString() ?? 'Kỹ năng';

                    final selected =
                        id != null && _selectedSkillIds.contains(id);

                    return FilterChip(
                      selected: selected,

                      label: Text(name),

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
          // BUTTONS
          // =================================================
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          _submit(publishAfterCreate: false);
                        },

                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),

                  child: const Text('Lưu nháp'),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton.icon(
                  onPressed: _submitting
                      ? null
                      : () {
                          _submit(publishAfterCreate: true);
                        },

                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),

                    backgroundColor: _primary,
                  ),

                  icon: _submitting
                      ? const SizedBox(
                          width: 18,

                          height: 18,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,

                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),

                  label: const Text('Đăng tin'),
                ),
              ),
            ],
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
  // HELPERS
  // =====================================================

  String? _dioMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map) {
      final raw = data['message'];

      if (raw is List) {
        return raw.join(', ');
      }

      return raw?.toString();
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _formatDate(DateTime value) {
    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  static String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  List<String> _orderedWorkDays() {
    return _days.keys.where(_selectedWorkDays.contains).toList();
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
// DAYS
// =======================================================

const Map<String, String> _days = {
  'MONDAY': 'T2',
  'TUESDAY': 'T3',
  'WEDNESDAY': 'T4',
  'THURSDAY': 'T5',
  'FRIDAY': 'T6',
  'SATURDAY': 'T7',
  'SUNDAY': 'CN',
};

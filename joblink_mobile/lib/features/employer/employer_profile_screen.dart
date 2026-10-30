import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/employer_profile_service.dart';

class EmployerProfileScreen
    extends StatefulWidget {
  const EmployerProfileScreen({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  State<EmployerProfileScreen>
  createState() =>
      _EmployerProfileScreenState();
}

class _EmployerProfileScreenState
    extends State<EmployerProfileScreen> {
  static const Color _primary =
  Color(0xFF2563EB);

  final EmployerProfileService
  _service =
  EmployerProfileService();

  Map<String, dynamic>?
  _profile;

  bool _loading = true;
  bool _submitting = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _load();
  }

  // =====================================================
  // LOAD
  // =====================================================

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final profile =
      await _service
          .getProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
      });
    } catch (error) {
      debugPrint(
        'Load employer profile failed: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _error =
        'Không thể tải hồ sơ Employer';
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
  // EDIT
  // =====================================================

  Future<void> _edit() async {
    final profile =
        _profile;

    if (profile == null) {
      return;
    }

    final changed =
    await Navigator.of(context)
        .push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _EmployerProfileEditScreen(
              profile:
              profile,
            ),
      ),
    );

    if (changed == true &&
        mounted) {
      await _load();
    }
  }

  // =====================================================
  // SUBMIT VERIFY
  // =====================================================

  Future<void>
  _submitVerification() async {
    if (_submitting) {
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
              'Gửi yêu cầu xác minh',
            ),

            content:
            const Text(
              'Thông tin doanh nghiệp sẽ được gửi cho Admin kiểm tra. Trong thời gian chờ duyệt, bạn sẽ không thể chỉnh sửa hồ sơ.',
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
                  'Gửi',
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final profile =
      await _service
          .submitVerification();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
      });

      _showMessage(
        'Đã gửi yêu cầu xác minh',
      );
    } on DioException catch (error) {
      _showMessage(
        _dioMessage(
          error,
        ) ??
            'Không thể gửi yêu cầu xác minh',
        error: true,
      );
    } catch (error) {
      _showMessage(
        'Không thể gửi yêu cầu xác minh',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
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
      String message, {
        bool error = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,

          backgroundColor:
          error
              ? Colors.red.shade700
              : null,

          content:
          Text(
            message,
          ),
        ),
      );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final profile =
        _profile;

    if (profile == null) {
      return const Center(
        child:
        Text(
          'Không tìm thấy hồ sơ Employer',
        ),
      );
    }

    final user =
    _asMap(
      profile['user'],
    );

    final companyName =
        _text(
          profile[
          'companyName'],
        ) ??
            'Employer';

    final email =
        _text(
          user?['email'],
        ) ??
            '';

    final status =
        _text(
          profile[
          'verificationStatus'],
        ) ??
            'UNVERIFIED';

    final statusData =
    _verificationStatus(
      status,
    );

    final rejectionReason =
    _text(
      profile[
      'rejectionReason'],
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
          // =================================================
          // HEADER
          // =================================================

          Container(
            padding:
            const EdgeInsets.all(
              20,
            ),

            decoration:
            BoxDecoration(
              color:
              Colors.white,

              borderRadius:
              BorderRadius.circular(
                22,
              ),

              border:
              Border.all(
                color:
                Colors.grey
                    .shade200,
              ),
            ),

            child:
            Column(
              children: [
                Container(
                  width: 76,
                  height: 76,

                  decoration:
                  BoxDecoration(
                    color:
                    _primary
                        .withValues(
                      alpha:
                      0.09,
                    ),

                    shape:
                    BoxShape.circle,
                  ),

                  child:
                  const Icon(
                    Icons
                        .business_rounded,

                    color:
                    _primary,

                    size:
                    38,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Text(
                  companyName,

                  textAlign:
                  TextAlign.center,

                  style:
                  const TextStyle(
                    fontSize:
                    20,

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                if (email.isNotEmpty) ...[
                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    email,

                    style:
                    TextStyle(
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 13,
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    12,
                    vertical:
                    7,
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
                      20,
                    ),
                  ),

                  child:
                  Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      Icon(
                        statusData.$3,

                        size:
                        16,

                        color:
                        statusData.$2,
                      ),

                      const SizedBox(
                        width:
                        6,
                      ),

                      Text(
                        statusData.$1,

                        style:
                        TextStyle(
                          color:
                          statusData.$2,

                          fontWeight:
                          FontWeight.w700,

                          fontSize:
                          12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =================================================
          // REJECTED
          // =================================================

          if (status ==
              'REJECTED') ...[
            const SizedBox(
              height: 14,
            ),

            Container(
              padding:
              const EdgeInsets.all(
                15,
              ),

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFDC2626,
                ).withValues(
                  alpha:
                  0.07,
                ),

                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),

              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  const Icon(
                    Icons
                        .error_outline_rounded,

                    color:
                    Color(
                      0xFFDC2626,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Xác minh bị từ chối',

                          style:
                          TextStyle(
                            color:
                            Color(
                              0xFFDC2626,
                            ),

                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          rejectionReason ??
                              'Vui lòng cập nhật lại thông tin và gửi xác minh lại.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          // =================================================
          // INFORMATION
          // =================================================

          _section(
            title:
            'Thông tin doanh nghiệp',

            children: [
              _infoRow(
                icon:
                Icons
                    .badge_outlined,

                label:
                'Người liên hệ',

                value:
                _display(
                  profile[
                  'contactName'],
                ),
              ),

              _infoRow(
                icon:
                Icons
                    .phone_outlined,

                label:
                'Số điện thoại',

                value:
                _display(
                  profile[
                  'phone'],
                ),
              ),

              _infoRow(
                icon:
                Icons
                    .location_on_outlined,

                label:
                'Địa chỉ',

                value:
                _display(
                  profile[
                  'address'],
                ),
              ),

              _infoRow(
                icon:
                Icons
                    .description_outlined,

                label:
                'Giới thiệu',

                value:
                _display(
                  profile[
                  'description'],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // =================================================
          // LEGAL
          // =================================================

          _section(
            title:
            'Thông tin xác minh',

            children: [
              _infoRow(
                icon:
                Icons
                    .numbers_rounded,

                label:
                'Mã số thuế',

                value:
                _display(
                  profile[
                  'taxCode'],
                ),
              ),

              _infoRow(
                icon:
                Icons
                    .verified_user_outlined,

                label:
                'Giấy phép kinh doanh',

                value:
                _display(
                  profile[
                  'businessLicense'],
                ),

                last:
                true,
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // =================================================
          // EDIT
          // =================================================

          if (status !=
              'PENDING')
            OutlinedButton.icon(
              onPressed:
              _edit,

              style:
              OutlinedButton
                  .styleFrom(
                minimumSize:
                const Size(
                  0,
                  52,
                ),
              ),

              icon:
              const Icon(
                Icons
                    .edit_outlined,
              ),

              label:
              const Text(
                'Chỉnh sửa hồ sơ',
              ),
            ),

          if (status !=
              'PENDING')
            const SizedBox(
              height: 10,
            ),

          // =================================================
          // VERIFICATION
          // =================================================

          if (status ==
              'UNVERIFIED' ||
              status ==
                  'REJECTED')
            FilledButton.icon(
              onPressed:
              _submitting
                  ? null
                  : _submitVerification,

              style:
              FilledButton
                  .styleFrom(
                minimumSize:
                const Size(
                  0,
                  54,
                ),

                backgroundColor:
                _primary,
              ),

              icon:
              _submitting
                  ? const SizedBox(
                width:
                18,
                height:
                18,

                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,

                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons
                    .verified_user_outlined,
              ),

              label:
              const Text(
                'Gửi yêu cầu xác minh',
              ),
            ),

          if (status ==
              'PENDING')
            Container(
              padding:
              const EdgeInsets.all(
                16,
              ),

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF59E0B,
                ).withValues(
                  alpha:
                  0.08,
                ),

                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),

              child:
              const Row(
                children: [
                  Icon(
                    Icons
                        .hourglass_top_rounded,

                    color:
                    Color(
                      0xFFF59E0B,
                    ),
                  ),

                  SizedBox(
                    width:
                    10,
                  ),

                  Expanded(
                    child:
                    Text(
                      'Hồ sơ đang chờ Admin xác minh.',
                    ),
                  ),
                ],
              ),
            ),

          if (status ==
              'VERIFIED')
            Container(
              padding:
              const EdgeInsets.all(
                16,
              ),

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFF16A34A,
                ).withValues(
                  alpha:
                  0.08,
                ),

                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),

              child:
              const Row(
                children: [
                  Icon(
                    Icons
                        .verified_rounded,

                    color:
                    Color(
                      0xFF16A34A,
                    ),
                  ),

                  SizedBox(
                    width:
                    10,
                  ),

                  Expanded(
                    child:
                    Text(
                      'Doanh nghiệp đã được xác minh.',
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(
            height: 18,
          ),

          // =================================================
          // LOGOUT
          // =================================================

          OutlinedButton.icon(
            onPressed:
            widget.onLogout,

            style:
            OutlinedButton
                .styleFrom(
              minimumSize:
              const Size(
                0,
                52,
              ),

              foregroundColor:
              const Color(
                0xFFDC2626,
              ),

              side:
              const BorderSide(
                color:
                Color(
                  0xFFFCA5A5,
                ),
              ),
            ),

            icon:
            const Icon(
              Icons.logout_rounded,
            ),

            label:
            const Text(
              'Đăng xuất',
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ERROR VIEW
  // =====================================================

  Widget _buildError() {
    return Center(
      child:
      Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),

        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,

              size:
              48,

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

  // =====================================================
  // UI HELPERS
  // =====================================================

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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

        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),

      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style:
            const TextStyle(
              fontSize:
              16,

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

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool last = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Container(
              width:
              38,
              height:
              38,

              decoration:
              BoxDecoration(
                color:
                _primary
                    .withValues(
                  alpha:
                  0.07,
                ),

                borderRadius:
                BorderRadius.circular(
                  11,
                ),
              ),

              child:
              Icon(
                icon,

                size:
                19,

                color:
                _primary,
              ),
            ),

            const SizedBox(
              width:
              11,
            ),

            Expanded(
              child:
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    label,

                    style:
                    TextStyle(
                      color: Colors
                          .grey
                          .shade600,

                      fontSize:
                      11.5,
                    ),
                  ),

                  const SizedBox(
                    height:
                    3,
                  ),

                  Text(
                    value,

                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w600,

                      height:
                      1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (!last)
          const Divider(
            height:
            26,
          ),
      ],
    );
  }

  String _display(
      dynamic value,
      ) {
    return _text(
      value,
    ) ??
        'Chưa cập nhật';
  }

  String? _text(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value
        .toString()
        .trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
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

  (String, Color, IconData)
  _verificationStatus(
      String status,
      ) {
    switch (status) {
      case 'PENDING':
        return (
        'Đang chờ xác minh',
        const Color(
          0xFFF59E0B,
        ),
        Icons
            .hourglass_top_rounded,
        );

      case 'VERIFIED':
        return (
        'Đã xác minh',
        const Color(
          0xFF16A34A,
        ),
        Icons
            .verified_rounded,
        );

      case 'REJECTED':
        return (
        'Bị từ chối',
        const Color(
          0xFFDC2626,
        ),
        Icons
            .cancel_outlined,
        );

      default:
        return (
        'Chưa xác minh',
        const Color(
          0xFF64748B,
        ),
        Icons
            .verified_user_outlined,
        );
    }
  }
}

// =========================================================
// EDIT PROFILE SCREEN
// =========================================================

class _EmployerProfileEditScreen
    extends StatefulWidget {
  const _EmployerProfileEditScreen({
    required this.profile,
  });

  final Map<String, dynamic>
  profile;

  @override
  State<_EmployerProfileEditScreen>
  createState() =>
      _EmployerProfileEditScreenState();
}

class _EmployerProfileEditScreenState
    extends State<
        _EmployerProfileEditScreen> {
  static const Color _primary =
  Color(0xFF2563EB);

  final EmployerProfileService
  _service =
  EmployerProfileService();

  final _formKey =
  GlobalKey<FormState>();

  late final TextEditingController
  _companyNameController;

  late final TextEditingController
  _contactNameController;

  late final TextEditingController
  _phoneController;

  late final TextEditingController
  _addressController;

  late final TextEditingController
  _descriptionController;

  late final TextEditingController
  _taxCodeController;

  late final TextEditingController
  _businessLicenseController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _companyNameController =
        TextEditingController(
          text:
          _value(
            'companyName',
          ),
        );

    _contactNameController =
        TextEditingController(
          text:
          _value(
            'contactName',
          ),
        );

    _phoneController =
        TextEditingController(
          text:
          _value(
            'phone',
          ),
        );

    _addressController =
        TextEditingController(
          text:
          _value(
            'address',
          ),
        );

    _descriptionController =
        TextEditingController(
          text:
          _value(
            'description',
          ),
        );

    _taxCodeController =
        TextEditingController(
          text:
          _value(
            'taxCode',
          ),
        );

    _businessLicenseController =
        TextEditingController(
          text:
          _value(
            'businessLicense',
          ),
        );
  }

  String _value(
      String key,
      ) {
    return widget
        .profile[key]
        ?.toString() ??
        '';
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _service.updateProfile(
        companyName:
        _companyNameController
            .text,

        contactName:
        _contactNameController
            .text,

        phone:
        _phoneController
            .text,

        address:
        _addressController
            .text,

        description:
        _descriptionController
            .text,

        taxCode:
        _taxCodeController
            .text,

        businessLicense:
        _businessLicenseController
            .text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text(
            'Cập nhật hồ sơ thành công',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final data =
          error.response?.data;

      String message =
          'Không thể cập nhật hồ sơ';

      if (data is Map &&
          data['message'] != null) {
        final raw =
        data['message'];

        message =
        raw is List
            ? raw.join(
          ', ',
        )
            : raw.toString();
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(
            message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final status =
        widget
            .profile[
        'verificationStatus']
            ?.toString() ??
            'UNVERIFIED';

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
          'Chỉnh sửa hồ sơ',
        ),
      ),

      body:
      Form(
        key:
        _formKey,

        child:
        ListView(
          padding:
          const EdgeInsets.all(
            18,
          ),

          children: [
            if (status ==
                'VERIFIED') ...[
              Container(
                padding:
                const EdgeInsets.all(
                  14,
                ),

                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF59E0B,
                  ).withValues(
                    alpha:
                    0.08,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                const Text(
                  'Nếu thay đổi tên doanh nghiệp, mã số thuế hoặc giấy phép kinh doanh, trạng thái xác minh sẽ được đặt lại.',
                ),
              ),

              const SizedBox(
                height: 14,
              ),
            ],

            _field(
              controller:
              _companyNameController,

              label:
              'Tên doanh nghiệp *',

              icon:
              Icons
                  .business_outlined,

              validator:
              _required,
            ),

            const SizedBox(
              height: 13,
            ),

            _field(
              controller:
              _contactNameController,

              label:
              'Người liên hệ',

              icon:
              Icons
                  .person_outline_rounded,
            ),

            const SizedBox(
              height: 13,
            ),

            _field(
              controller:
              _phoneController,

              label:
              'Số điện thoại',

              icon:
              Icons
                  .phone_outlined,

              keyboardType:
              TextInputType.phone,
            ),

            const SizedBox(
              height: 13,
            ),

            _field(
              controller:
              _addressController,

              label:
              'Địa chỉ doanh nghiệp',

              icon:
              Icons
                  .location_on_outlined,
            ),

            const SizedBox(
              height: 13,
            ),

            _field(
              controller:
              _descriptionController,

              label:
              'Giới thiệu doanh nghiệp',

              icon:
              Icons
                  .description_outlined,

              minLines:
              4,

              maxLines:
              7,
            ),

            const SizedBox(
              height: 13,
            ),

            _field(
              controller:
              _taxCodeController,

              label:
              'Mã số thuế',

              icon:
              Icons
                  .numbers_rounded,
            ),

            const SizedBox(
              height: 13,
            ),

            _field(
              controller:
              _businessLicenseController,

              label:
              'Giấy phép kinh doanh',

              hint:
              'Nhập số giấy phép / thông tin giấy phép',

              icon:
              Icons
                  .verified_user_outlined,
            ),

            const SizedBox(
              height: 22,
            ),

            FilledButton.icon(
              onPressed:
              _saving
                  ? null
                  : _save,

              style:
              FilledButton
                  .styleFrom(
                minimumSize:
                const Size(
                  0,
                  54,
                ),

                backgroundColor:
                _primary,
              ),

              icon:
              _saving
                  ? const SizedBox(
                width:
                18,
                height:
                18,

                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,

                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons
                    .save_outlined,
              ),

              label:
              const Text(
                'Lưu thay đổi',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController
    controller,

    required String label,

    required IconData icon,

    String? hint,

    TextInputType?
    keyboardType,

    int minLines = 1,

    int maxLines = 1,

    String? Function(String?)?
    validator,
  }) {
    return TextFormField(
      controller:
      controller,

      keyboardType:
      keyboardType,

      minLines:
      minLines,

      maxLines:
      maxLines,

      validator:
      validator,

      decoration:
      InputDecoration(
        labelText:
        label,

        hintText:
        hint,

        prefixIcon:
        Icon(
          icon,
        ),

        filled:
        true,

        fillColor:
        Colors.white,

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),
    );
  }

  String? _required(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Không được để trống';
    }

    return null;
  }

  @override
  void dispose() {
    _companyNameController
        .dispose();

    _contactNameController
        .dispose();

    _phoneController.dispose();

    _addressController
        .dispose();

    _descriptionController
        .dispose();

    _taxCodeController
        .dispose();

    _businessLicenseController
        .dispose();

    super.dispose();
  }
}
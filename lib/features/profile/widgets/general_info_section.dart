// FILE HỌC TẬP: lib/features/profile/widgets/general_info_section.dart
// Vai trò: Widget hồ sơ cho chung thông tin khu vực.
// Luồng sử dụng: Hiển thị/chỉnh sửa một phần hồ sơ và trả sự kiện về màn hình Profile.

import 'package:flutter/material.dart';
import 'package:project_trangdc24v7x324/models/user_profile_model.dart';
import '../../../shared/widgets/section_card.dart';

// Lớp GeneralInfoSection: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class GeneralInfoSection extends StatefulWidget {
  final UserProfileModel profile;
  final bool isEditing;
  final VoidCallback onEdit;
  final Future<void> Function({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String gender,
    required DateTime? dateOfBirth,
  })
  onSave;

  // Khởi tạo GeneralInfoSection: nhận các tham số cần thiết để tạo đối tượng cho widget hồ sơ cho chung thông tin khu vực.
  const GeneralInfoSection({
    super.key,
    required this.profile,
    required this.isEditing,
    required this.onEdit,
    required this.onSave,
  });

  // Tạo state (createState): liên kết GeneralInfoSection với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<GeneralInfoSection> createState() => _GeneralInfoSectionState();
}

// Lớp _GeneralInfoSectionState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _GeneralInfoSectionState extends State<GeneralInfoSection> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late String _selectedGender;
  DateTime? _selectedDate;
  bool _isSaving = false;

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _selectedGender = widget.profile.gender;
    _selectedDate = widget.profile.dateOfBirth;
  }

  // Đồng bộ widget (didUpdateWidget): cập nhật state khi widget cha truyền cấu hình mới.
  @override
  void didUpdateWidget(covariant GeneralInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isEditing) {
      _fullNameController.text = widget.profile.fullName;
      _emailController.text = widget.profile.email;
      _phoneController.text = widget.profile.phoneNumber;
      _selectedGender = widget.profile.gender;
      _selectedDate = widget.profile.dateOfBirth;
    }
  }

  // Giải phóng tài nguyên (dispose): hủy controller/listener khi widget bị loại khỏi cây giao diện.
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Định dạng ngày (_formatDate): chuyển dữ liệu thô thành giá trị dễ đọc để hiển thị.
  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Chọn ngày (_pickDate): mở công cụ chọn phù hợp và ghi kết quả vào state.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2004, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Xử lý _save: thực hiện phần nghiệp vụ tương ứng trong widget hồ sơ cho chung thông tin khu vực.
  Future<void> _save() async {
    if (_isSaving) return;

    final fullName = _fullNameController.text.trim();
    final phoneNumber = _phoneController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ và tên.')));
      return;
    }

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        fullName: fullName,
        email: _emailController.text.trim(),
        phoneNumber: phoneNumber,
        gender: _selectedGender,
        dateOfBirth: _selectedDate,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Xử lý _viewItem: thực hiện phần nghiệp vụ tương ứng trong widget hồ sơ cho chung thông tin khu vực.
  Widget _viewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Chưa cập nhật' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Xử lý _editTextItem: thực hiện phần nghiệp vụ tương ứng trong widget hồ sơ cho chung thông tin khu vực.
  Widget _editTextItem(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              enabled: enabled,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Xử lý _editGenderItem: thực hiện phần nghiệp vụ tương ứng trong widget hồ sơ cho chung thông tin khu vực.
  Widget _editGenderItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              'Giới tính',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedGender.isEmpty ? null : _selectedGender,
              items: const [
                DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedGender = value);
              },
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Xử lý _editDateItem: thực hiện phần nghiệp vụ tương ứng trong widget hồ sơ cho chung thông tin khu vực.
  Widget _editDateItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              'Ngày sinh',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade500),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Xây dựng giao diện (build): dựng cây widget của _GeneralInfoSectionState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Thông tin chung',
      action: IconButton(
        onPressed:
            _isSaving
                ? null
                : () {
                  if (widget.isEditing) {
                    _save();
                  } else {
                    widget.onEdit();
                  }
                },
        icon:
            _isSaving
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(
                  widget.isEditing ? Icons.check : Icons.edit_outlined,
                  color: const Color(0xFF8E1F16),
                ),
      ),
      child: Column(
        children: [
          widget.isEditing
              ? _editTextItem('Họ và tên', _fullNameController)
              : _viewItem('Họ và tên', widget.profile.fullName),
          widget.isEditing
              ? _editDateItem()
              : _viewItem('Ngày sinh', _formatDate(widget.profile.dateOfBirth)),
          widget.isEditing
              ? _editGenderItem()
              : _viewItem('Giới tính', widget.profile.gender),
          widget.isEditing
              ? _editTextItem('Email', _emailController, enabled: false)
              : _viewItem('Email', widget.profile.email),
          widget.isEditing
              ? _editTextItem(
                'Số điện thoại',
                _phoneController,
                keyboardType: TextInputType.phone,
              )
              : _viewItem('Số điện thoại', widget.profile.phoneNumber),
        ],
      ),
    );
  }
}

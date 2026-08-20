// FILE HỌC TẬP: lib/features/profile/widgets/address_section.dart
// Vai trò: Widget hồ sơ cho địa chỉ khu vực.
// Luồng sử dụng: Hiển thị/chỉnh sửa một phần hồ sơ và trả sự kiện về màn hình Profile.

import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/models/address_model.dart';
import 'package:project_trangdc24v7x324/services/delivery_service.dart';
import 'package:project_trangdc24v7x324/shared/widgets/section_card.dart';

// Lớp AddressSection: widget thành phần dùng để hiển thị một phần giao diện và nhận dữ liệu từ lớp cha.
class AddressSection extends StatefulWidget {
  final List<AddressModel> addresses;
  final bool isEditing;
  final VoidCallback onEdit;

  final Future<void> Function(List<AddressModel> updatedAddresses) onSave;

  // Khởi tạo AddressSection: nhận các tham số cần thiết để tạo đối tượng cho widget hồ sơ cho địa chỉ khu vực.
  const AddressSection({
    super.key,
    required this.addresses,
    required this.isEditing,
    required this.onEdit,
    required this.onSave,
  });

  // Tạo state (createState): liên kết AddressSection với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<AddressSection> createState() => _AddressSectionState();
}

// Lớp _AddressSectionState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _AddressSectionState extends State<AddressSection> {
  final DeliveryService _deliveryService = DeliveryService();

  late List<AddressModel> _localAddresses;

  bool _isSaving = false;
  int? _resolvingIndex;

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();

    _localAddresses = _copyAddresses(widget.addresses);
  }

  // Đồng bộ widget (didUpdateWidget): cập nhật state khi widget cha truyền cấu hình mới.
  @override
  void didUpdateWidget(covariant AddressSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isEditing) {
      _localAddresses = _copyAddresses(widget.addresses);
    }
  }

  // Xử lý _copyAddresses: thực hiện phần nghiệp vụ tương ứng trong widget hồ sơ cho địa chỉ khu vực.
  List<AddressModel> _copyAddresses(List<AddressModel> addresses) {
    return addresses.map((address) => address.copyWith()).toList();
  }

  // Thêm new địa chỉ (_addNewAddress): đưa mục mới vào state/backend và cập nhật giao diện.
  void _addNewAddress() {
    setState(() {
      _localAddresses.add(
        AddressModel(
          // Record mới chưa có PocketBase id.
          id: '',
          userId: '',
          label: _localAddresses.isEmpty ? 'Nhà' : 'Khác',
          receiverName: '',
          phoneNumber: '',
          addressLine: '',
          note: '',
          latitude: 0,
          longitude: 0,
          isDefault: _localAddresses.isEmpty,
        ),
      );
    });
  }

  // Xóa địa chỉ (_removeAddress): loại bỏ dữ liệu được chọn và đồng bộ state liên quan.
  void _removeAddress(int index) {
    setState(() {
      final wasDefault = _localAddresses[index].isDefault;

      _localAddresses.removeAt(index);

      if (wasDefault && _localAddresses.isNotEmpty) {
        _localAddresses[0] = _localAddresses[0].copyWith(isDefault: true);
      }
    });
  }

  // Cập nhật mặc định địa chỉ (_setDefaultAddress): gán state nội bộ và thông báo lại cho UI khi cần.
  void _setDefaultAddress(int index) {
    setState(() {
      _localAddresses =
          _localAddresses
              .asMap()
              .entries
              .map(
                (entry) => entry.value.copyWith(isDefault: entry.key == index),
              )
              .toList();
    });
  }

  // Xử lý địa chỉ (_resolveAddress): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
  Future<void> _resolveAddress(int index, {bool showMessage = true}) async {
    if (_resolvingIndex != null ||
        index < 0 ||
        index >= _localAddresses.length) {
      return;
    }

    final address = _localAddresses[index];

    final text = address.addressLine.trim();

    if (text.isEmpty) {
      if (showMessage) {
        _showMessage('Vui lòng nhập địa chỉ đầy đủ trước.');
      }
      return;
    }

    setState(() {
      _resolvingIndex = index;
    });

    try {
      final coordinates = await _deliveryService.resolveAddressText(text);

      if (!mounted) {
        return;
      }

      setState(() {
        _localAddresses[index] = _localAddresses[index].copyWith(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
        );
      });

      if (showMessage) {
        _showMessage('Đã xác định vị trí giao hàng.');
      }
    } catch (e) {
      if (showMessage && mounted) {
        _showMessage(
          'Chưa xác định được vị trí. '
          'Bạn vẫn có thể lưu và tính lại ở bước thanh toán.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _resolvingIndex = null;
        });
      }
    }
  }

  // Xử lý còn thiếu tọa độ (_resolveMissingCoordinates): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
  Future<void> _resolveMissingCoordinates() async {
    for (int i = 0; i < _localAddresses.length; i++) {
      final address = _localAddresses[i];

      if (address.addressLine.trim().isEmpty || address.hasCoordinates) {
        continue;
      }

      await _resolveAddress(i, showMessage: false);
    }
  }

  // Kiểm tra điều kiện (_isPhoneValid): đánh giá trạng thái số điện thoại hợp lệ và trả kết quả cho lớp gọi.
  bool _isPhoneValid(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s\-.()]'), '');

    return RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(normalized);
  }

  // Lưu địa chỉ (_saveAddresses): kiểm tra dữ liệu, ghi thay đổi và đồng bộ state sau khi thành công.
  Future<void> _saveAddresses() async {
    if (_isSaving) {
      return;
    }

    final invalidRequired = _localAddresses.any(
      (address) =>
          address.receiverName.trim().isEmpty ||
          address.phoneNumber.trim().isEmpty ||
          address.addressLine.trim().isEmpty,
    );

    if (invalidRequired) {
      _showMessage('Vui lòng nhập đầy đủ tên, số điện thoại và địa chỉ.');
      return;
    }

    final invalidPhone = _localAddresses.any(
      (address) => !_isPhoneValid(address.phoneNumber),
    );

    if (invalidPhone) {
      _showMessage('Có số điện thoại chưa đúng định dạng.');
      return;
    }

    final hasDefault = _localAddresses.any((address) => address.isDefault);

    _localAddresses =
        _localAddresses
            .asMap()
            .entries
            .map(
              (entry) => entry.value.copyWith(
                label:
                    entry.value.label.trim().isEmpty
                        ? 'Khác'
                        : entry.value.label.trim(),
                isDefault: hasDefault ? entry.value.isDefault : entry.key == 0,
              ),
            )
            .toList();

    setState(() {
      _isSaving = true;
    });

    try {
      // Cố gắng resolve tọa độ trước khi lưu.
      // Không chặn lưu nếu native geocoding không resolve được.
      await _resolveMissingCoordinates();

      await widget.onSave(_localAddresses);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Hiển thị tin nhắn (_showMessage): mở thông báo/dialog hoặc thành phần hỗ trợ trên giao diện.
  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Tạo giao diện view mục (_buildViewItem): dựng widget con từ dữ liệu hiện tại.
  Widget _buildViewItem(AddressModel address) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff7f7f7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  address.label.trim().isEmpty ? 'Khác' : address.label,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address.receiverName.trim().isEmpty
                      ? 'Chưa có tên người nhận'
                      : address.receiverName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Mặc định',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_outlined, size: 17, color: Colors.grey),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  address.phoneNumber.trim().isEmpty
                      ? 'Chưa có số điện thoại'
                      : address.phoneNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: Colors.grey,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  address.addressLine.trim().isEmpty
                      ? 'Chưa có địa chỉ giao hàng'
                      : address.addressLine,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                address.hasCoordinates
                    ? Icons.check_circle_outline
                    : Icons.location_searching,
                size: 16,
                color: address.hasCoordinates ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.hasCoordinates
                      ? 'Đã xác định vị trí giao hàng'
                      : 'Chưa xác định vị trí; hệ thống sẽ xử lý khi thanh toán',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        address.hasCoordinates
                            ? Colors.green
                            : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (address.note.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ghi chú: ${address.note}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // Tạo giao diện chỉnh sửa mục (_buildEditItem): dựng widget con từ dữ liệu hiện tại.
  Widget _buildEditItem(int index) {
    final address = _localAddresses[index];

    final bool resolving = _resolvingIndex == index;

    final String keyValue =
        address.id.trim().isNotEmpty ? address.id : 'new-$index';

    return Container(
      key: ValueKey(keyValue),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff7f7f7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Địa chỉ ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Xóa địa chỉ',
                onPressed: _isSaving ? null : () => _removeAddress(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 8),

          TextFormField(
            initialValue: address.label,
            decoration: const InputDecoration(
              labelText: 'Nhãn địa chỉ',
              hintText: 'Nhà, Trường, Công ty...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _localAddresses[index] = _localAddresses[index].copyWith(
                label: value,
              );
            },
          ),

          const SizedBox(height: 10),

          TextFormField(
            initialValue: address.receiverName,
            decoration: const InputDecoration(
              labelText: 'Tên người nhận',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _localAddresses[index] = _localAddresses[index].copyWith(
                receiverName: value,
              );
            },
          ),

          const SizedBox(height: 10),

          TextFormField(
            initialValue: address.phoneNumber,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              _localAddresses[index] = _localAddresses[index].copyWith(
                phoneNumber: value,
              );
            },
          ),

          const SizedBox(height: 10),

          TextFormField(
            initialValue: address.addressLine,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ đầy đủ',
              hintText: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              // Address text đổi thì tọa độ cũ không còn đáng tin.
              _localAddresses[index] = _localAddresses[index].copyWith(
                addressLine: value,
                latitude: 0,
                longitude: 0,
              );
            },
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _isSaving || _resolvingIndex != null
                      ? null
                      : () => _resolveAddress(index),
              icon:
                  resolving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.location_searching),
              label: Text(
                address.hasCoordinates
                    ? 'Xác định lại vị trí'
                    : 'Xác định vị trí từ địa chỉ',
              ),
            ),
          ),

          if (address.hasCoordinates) ...[
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đã xác định vị trí để tính phí và chỉ đường giao hàng.',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          TextFormField(
            initialValue: address.note,
            decoration: const InputDecoration(
              labelText: 'Ghi chú giao hàng',
              hintText: 'Ví dụ: gọi trước khi giao, cổng sau...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              _localAddresses[index] = _localAddresses[index].copyWith(
                note: value,
              );
            },
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Checkbox(
                value: address.isDefault,
                onChanged:
                    _isSaving
                        ? null
                        : (value) {
                          if (value == true) {
                            _setDefaultAddress(index);
                          }
                        },
              ),
              const Expanded(child: Text('Đặt làm địa chỉ mặc định')),
            ],
          ),
        ],
      ),
    );
  }

  // Xây dựng giao diện (build): dựng cây widget của _AddressSectionState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Địa chỉ giao hàng',
      action: IconButton(
        onPressed:
            _isSaving
                ? null
                : () {
                  if (widget.isEditing) {
                    _saveAddresses();
                  } else {
                    widget.onEdit();
                  }
                },
        icon:
            _isSaving
                ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(
                  widget.isEditing ? Icons.check : Icons.edit_outlined,
                  color: const Color(0xFF8E1F16),
                ),
      ),
      child: Column(
        children: [
          if (_localAddresses.isEmpty && !widget.isEditing)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chưa có địa chỉ giao hàng',
                style: TextStyle(color: Colors.grey),
              ),
            ),

          ..._localAddresses.asMap().entries.map(
            (entry) =>
                widget.isEditing
                    ? _buildEditItem(entry.key)
                    : _buildViewItem(entry.value),
          ),

          if (widget.isEditing)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _addNewAddress,
                icon: const Icon(Icons.add),
                label: const Text('Thêm địa chỉ'),
              ),
            ),
        ],
      ),
    );
  }
}

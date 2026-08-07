import 'package:flutter/material.dart';

import 'package:CT466_project_trangdc24v7x324/models/address_model.dart';
import 'package:CT466_project_trangdc24v7x324/services/delivery_service.dart';
import 'package:CT466_project_trangdc24v7x324/shared/widgets/section_card.dart';

class AddressSection extends StatefulWidget {
  final List<AddressModel> addresses;
  final bool isEditing;
  final VoidCallback onEdit;

  final Future<void> Function(
    List<AddressModel> updatedAddresses,
  ) onSave;

  const AddressSection({
    super.key,
    required this.addresses,
    required this.isEditing,
    required this.onEdit,
    required this.onSave,
  });

  @override
  State<AddressSection> createState() =>
      _AddressSectionState();
}

class _AddressSectionState
    extends State<AddressSection> {
  final DeliveryService _deliveryService =
      DeliveryService();

  late List<AddressModel>
      _localAddresses;

  bool _isSaving = false;
  int? _resolvingIndex;

  @override
  void initState() {
    super.initState();

    _localAddresses =
        _copyAddresses(
      widget.addresses,
    );
  }

  @override
  void didUpdateWidget(
    covariant AddressSection oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (!widget.isEditing) {
      _localAddresses =
          _copyAddresses(
        widget.addresses,
      );
    }
  }

  List<AddressModel> _copyAddresses(
    List<AddressModel> addresses,
  ) {
    return addresses
        .map(
          (address) =>
              address.copyWith(),
        )
        .toList();
  }

  void _addNewAddress() {
    setState(() {
      _localAddresses.add(
        AddressModel(
          // Record mới chưa có PocketBase id.
          id: '',
          userId: '',
          label:
              _localAddresses.isEmpty
                  ? 'Nhà'
                  : 'Khác',
          receiverName: '',
          phoneNumber: '',
          addressLine: '',
          note: '',
          latitude: 0,
          longitude: 0,
          isDefault:
              _localAddresses.isEmpty,
        ),
      );
    });
  }

  void _removeAddress(int index) {
    setState(() {
      final wasDefault =
          _localAddresses[index]
              .isDefault;

      _localAddresses
          .removeAt(index);

      if (wasDefault &&
          _localAddresses
              .isNotEmpty) {
        _localAddresses[0] =
            _localAddresses[0]
                .copyWith(
          isDefault: true,
        );
      }
    });
  }

  void _setDefaultAddress(
    int index,
  ) {
    setState(() {
      _localAddresses =
          _localAddresses
              .asMap()
              .entries
              .map(
                (entry) =>
                    entry.value
                        .copyWith(
                  isDefault:
                      entry.key ==
                          index,
                ),
              )
              .toList();
    });
  }

  Future<void> _resolveAddress(
    int index, {
    bool showMessage = true,
  }) async {
    if (_resolvingIndex != null ||
        index < 0 ||
        index >=
            _localAddresses.length) {
      return;
    }

    final address =
        _localAddresses[index];

    final text =
        address.addressLine.trim();

    if (text.isEmpty) {
      if (showMessage) {
        _showMessage(
          'Vui lòng nhập địa chỉ đầy đủ trước.',
        );
      }
      return;
    }

    setState(() {
      _resolvingIndex = index;
    });

    try {
      final coordinates =
          await _deliveryService
              .resolveAddressText(
        text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _localAddresses[index] =
            _localAddresses[index]
                .copyWith(
          latitude:
              coordinates.latitude,
          longitude:
              coordinates.longitude,
        );
      });

      if (showMessage) {
        _showMessage(
          'Đã xác định tọa độ địa chỉ.',
        );
      }
    } catch (e) {
      if (showMessage &&
          mounted) {
        _showMessage(
          'Chưa xác định được tọa độ. '
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

  Future<void>
      _resolveMissingCoordinates() async {
    for (int i = 0;
        i <
            _localAddresses.length;
        i++) {
      final address =
          _localAddresses[i];

      if (address
              .addressLine
              .trim()
              .isEmpty ||
          address.hasCoordinates) {
        continue;
      }

      await _resolveAddress(
        i,
        showMessage: false,
      );
    }
  }

  bool _isPhoneValid(
    String value,
  ) {
    final normalized =
        value.replaceAll(
      RegExp(r'[\s\-.()]'),
      '',
    );

    return RegExp(
      r'^(0|\+84)[0-9]{9,10}$',
    ).hasMatch(normalized);
  }

  Future<void>
      _saveAddresses() async {
    if (_isSaving) {
      return;
    }

    final invalidRequired =
        _localAddresses.any(
      (address) =>
          address.receiverName
              .trim()
              .isEmpty ||
          address.phoneNumber
              .trim()
              .isEmpty ||
          address.addressLine
              .trim()
              .isEmpty,
    );

    if (invalidRequired) {
      _showMessage(
        'Vui lòng nhập đầy đủ tên, số điện thoại và địa chỉ.',
      );
      return;
    }

    final invalidPhone =
        _localAddresses.any(
      (address) =>
          !_isPhoneValid(
        address.phoneNumber,
      ),
    );

    if (invalidPhone) {
      _showMessage(
        'Có số điện thoại chưa đúng định dạng.',
      );
      return;
    }

    final hasDefault =
        _localAddresses.any(
      (address) =>
          address.isDefault,
    );

    _localAddresses =
        _localAddresses
            .asMap()
            .entries
            .map(
              (entry) =>
                  entry.value
                      .copyWith(
                label:
                    entry.value.label
                            .trim()
                            .isEmpty
                        ? 'Khác'
                        : entry.value
                            .label
                            .trim(),
                isDefault:
                    hasDefault
                        ? entry.value
                            .isDefault
                        : entry.key ==
                            0,
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

      await widget.onSave(
        _localAddresses,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildViewItem(
    AddressModel address,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xfff7f7f7,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE3F2FD,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
                child: Text(
                  address.label
                          .trim()
                          .isEmpty
                      ? 'Khác'
                      : address.label,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF1565C0,
                    ),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  address.receiverName
                          .trim()
                          .isEmpty
                      ? 'Chưa có tên người nhận'
                      : address
                          .receiverName,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              if (address
                  .isDefault)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red
                            .shade50,
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'Mặc định',
                    style:
                        TextStyle(
                      color:
                          Colors.red
                              .shade700,
                      fontSize: 11,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 17,
                color:
                    Colors.grey,
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child: Text(
                  address.phoneNumber
                          .trim()
                          .isEmpty
                      ? 'Chưa có số điện thoại'
                      : address
                          .phoneNumber,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 6,
          ),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons
                    .location_on_outlined,
                size: 17,
                color:
                    Colors.grey,
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child: Text(
                  address.addressLine
                          .trim()
                          .isEmpty
                      ? 'Chưa có địa chỉ giao hàng'
                      : address
                          .addressLine,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 6,
          ),
          Row(
            children: [
              Icon(
                address.hasCoordinates
                    ? Icons
                        .check_circle_outline
                    : Icons
                        .location_searching,
                size: 16,
                color:
                    address
                            .hasCoordinates
                        ? Colors.green
                        : Colors.orange,
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child: Text(
                  address.hasCoordinates
                      ? 'Đã có tọa độ giao hàng'
                      : 'Chưa có tọa độ; hệ thống sẽ xác định khi thanh toán',
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        address
                                .hasCoordinates
                            ? Colors.green
                            : Colors
                                .orange
                                .shade800,
                  ),
                ),
              ),
            ],
          ),
          if (address.note
              .trim()
              .isNotEmpty) ...[
            const SizedBox(
              height: 6,
            ),
            Text(
              'Ghi chú: ${address.note}',
              style:
                  const TextStyle(
                color:
                    Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditItem(
    int index,
  ) {
    final address =
        _localAddresses[index];

    final bool resolving =
        _resolvingIndex ==
            index;

    final String keyValue =
        address.id
                .trim()
                .isNotEmpty
            ? address.id
            : 'new-$index';

    return Container(
      key: ValueKey(
        keyValue,
      ),
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xfff7f7f7,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Địa chỉ ${index + 1}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    'Xóa địa chỉ',
                onPressed:
                    _isSaving
                        ? null
                        : () =>
                            _removeAddress(
                              index,
                            ),
                icon:
                    const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          TextFormField(
            initialValue:
                address.label,
            decoration:
                const InputDecoration(
              labelText:
                  'Nhãn địa chỉ',
              hintText:
                  'Nhà, Trường, Công ty...',
              border:
                  OutlineInputBorder(),
            ),
            onChanged: (value) {
              _localAddresses[index] =
                  _localAddresses[
                          index]
                      .copyWith(
                label: value,
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          TextFormField(
            initialValue:
                address
                    .receiverName,
            decoration:
                const InputDecoration(
              labelText:
                  'Tên người nhận',
              border:
                  OutlineInputBorder(),
            ),
            onChanged: (value) {
              _localAddresses[index] =
                  _localAddresses[
                          index]
                      .copyWith(
                receiverName: value,
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          TextFormField(
            initialValue:
                address
                    .phoneNumber,
            decoration:
                const InputDecoration(
              labelText:
                  'Số điện thoại',
              border:
                  OutlineInputBorder(),
            ),
            keyboardType:
                TextInputType.phone,
            onChanged: (value) {
              _localAddresses[index] =
                  _localAddresses[
                          index]
                      .copyWith(
                phoneNumber: value,
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          TextFormField(
            initialValue:
                address
                    .addressLine,
            decoration:
                const InputDecoration(
              labelText:
                  'Địa chỉ đầy đủ',
              hintText:
                  'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành',
              border:
                  OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              // Address text đổi thì tọa độ cũ không còn đáng tin.
              _localAddresses[index] =
                  _localAddresses[
                          index]
                      .copyWith(
                addressLine: value,
                latitude: 0,
                longitude: 0,
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                OutlinedButton.icon(
              onPressed:
                  _isSaving ||
                          _resolvingIndex !=
                              null
                      ? null
                      : () =>
                          _resolveAddress(
                            index,
                          ),
              icon:
                  resolving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                      : const Icon(
                        Icons
                            .location_searching,
                      ),
              label:
                  Text(
                address.hasCoordinates
                    ? 'Xác định lại tọa độ'
                    : 'Xác định tọa độ từ địa chỉ',
              ),
            ),
          ),

          if (address.hasCoordinates) ...[
            const SizedBox(
              height: 6,
            ),
            Align(
              alignment:
                  Alignment
                      .centerLeft,
              child: Text(
                'Lat: ${address.latitude.toStringAsFixed(6)}  •  '
                'Lng: ${address.longitude.toStringAsFixed(6)}',
                style:
                    const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                ),
              ),
            ),
          ],

          const SizedBox(
            height: 10,
          ),

          TextFormField(
            initialValue:
                address.note,
            decoration:
                const InputDecoration(
              labelText:
                  'Ghi chú giao hàng',
              hintText:
                  'Ví dụ: gọi trước khi giao, cổng sau...',
              border:
                  OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              _localAddresses[index] =
                  _localAddresses[
                          index]
                      .copyWith(
                note: value,
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Checkbox(
                value:
                    address.isDefault,
                onChanged:
                    _isSaving
                        ? null
                        : (value) {
                          if (value ==
                              true) {
                            _setDefaultAddress(
                              index,
                            );
                          }
                        },
              ),
              const Expanded(
                child: Text(
                  'Đặt làm địa chỉ mặc định',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SectionCard(
      title:
          'Địa chỉ giao hàng',
      action: IconButton(
        onPressed:
            _isSaving
                ? null
                : () {
                  if (widget
                      .isEditing) {
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
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                : Icon(
                  widget.isEditing
                      ? Icons.check
                      : Icons
                          .edit_outlined,
                  color:
                      const Color(
                    0xFF8E1F16,
                  ),
                ),
      ),
      child: Column(
        children: [
          if (_localAddresses
                  .isEmpty &&
              !widget
                  .isEditing)
            const Align(
              alignment:
                  Alignment
                      .centerLeft,
              child: Text(
                'Chưa có địa chỉ giao hàng',
                style:
                    TextStyle(
                  color:
                      Colors.grey,
                ),
              ),
            ),

          ..._localAddresses
              .asMap()
              .entries
              .map(
                (entry) =>
                    widget
                            .isEditing
                        ? _buildEditItem(
                          entry.key,
                        )
                        : _buildViewItem(
                          entry.value,
                        ),
              ),

          if (widget.isEditing)
            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    _isSaving
                        ? null
                        : _addNewAddress,
                icon:
                    const Icon(
                  Icons.add,
                ),
                label:
                    const Text(
                  'Thêm địa chỉ',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

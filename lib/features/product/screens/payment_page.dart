// FILE HỌC TẬP: lib/features/product/screens/payment_page.dart
// Vai trò: Màn hình thanh toán.
// Luồng sử dụng: Phục vụ luồng mua hàng: xem món, giỏ hàng, đặt đơn, thanh toán hoặc theo dõi đơn.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_trangdc24v7x324/models/cart_item_model.dart';
import 'package:project_trangdc24v7x324/models/payment_method_model.dart';
import 'package:project_trangdc24v7x324/models/payment_record_model.dart';
import 'package:project_trangdc24v7x324/models/delivery_quote_model.dart';
import 'package:project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/services/delivery_service.dart';
import 'package:project_trangdc24v7x324/services/payment_service.dart';

import 'package:project_trangdc24v7x324/shared/theme/app_colors.dart';
import 'package:project_trangdc24v7x324/shared/theme/app_text.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_layout.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_body.dart';
import 'package:project_trangdc24v7x324/shared/widgets/app_card.dart';

// Lớp PaymentPage: định nghĩa màn hình và điểm vào giao diện của chức năng này.
class PaymentPage extends StatefulWidget {
  // Khởi tạo PaymentPage: nhận các tham số cần thiết để tạo đối tượng cho màn hình thanh toán.
  const PaymentPage({super.key});

  // Tạo state (createState): liên kết PaymentPage với lớp State để Flutter quản lý vòng đời màn hình.
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

// Lớp _PaymentPageState: quản lý state, vòng đời và các xử lý tương tác của widget phía trên.
class _PaymentPageState extends State<PaymentPage> {
  String? selectedMethod;

  final TextEditingController noteController = TextEditingController();

  final Set<String> _checkoutKeys = <String>{};

  bool _routeArgsLoaded = false;
  bool _isSubmitting = false;

  final DeliveryService _deliveryService = DeliveryService();

  final PaymentService _paymentService = PaymentService();

  DeliveryQuote? _deliveryQuote;

  bool _isLoadingDelivery = false;
  String? _deliveryError;
  String? _lastAddressId;

  // Address checkout state.
  // PaymentPage luôn load lại ProfileProvider từ backend,
  // nhưng người dùng có thể chọn một address cụ thể hoặc GPS hiện tại.
  String? _selectedProfileAddressId;
  String? _checkoutAddressText;
  String _deliveryAddressSource = 'profile';

  // Xử lý _lineKey: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  String _lineKey(CartItemModel item) {
    return '${item.productId}|${item.normalizedNote}';
  }

  // Khởi tạo state (initState): chạy các tác vụ chuẩn bị dữ liệu khi widget được tạo lần đầu.
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentData();
    });
  }

  // Xử lý _initializePaymentData: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  Future<void> _initializePaymentData() async {
    final profileProvider = context.read<ProfileProvider>();

    // Luôn gọi lại backend khi mở Payment để tránh dùng
    // address cũ đang cache trong ProfileProvider.
    await profileProvider.loadProfile();

    if (!mounted) {
      return;
    }

    final profile = profileProvider.profile;

    final methods = profile?.paymentMethods ?? [];

    final defaultMethod =
        methods.where((m) => m.isDefault).isNotEmpty
            ? methods.firstWhere((m) => m.isDefault)
            : (methods.isNotEmpty ? methods.first : null);

    final defaultAddress = _findDefaultOrFirstAddress(profile);

    setState(() {
      selectedMethod = defaultMethod?.title;

      _selectedProfileAddressId = _addressId(defaultAddress);

      _checkoutAddressText = _addressLine(defaultAddress);

      _deliveryAddressSource = 'profile';

      _deliveryQuote = null;
      _deliveryError = null;
      _lastAddressId = null;
    });
  }

  // Cập nhật phụ thuộc (didChangeDependencies): xử lý lại khi Provider/InheritedWidget liên quan thay đổi.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routeArgsLoaded) {
      return;
    }

    final Object? args = ModalRoute.of(context)?.settings.arguments;

    final cart = context.read<CartProvider>();

    if (args is List<CartItemModel>) {
      _checkoutKeys.addAll(args.map(_lineKey));
    } else {
      // Tương thích route cũ:
      // nếu PaymentPage được mở không kèm arguments thì
      // dùng toàn bộ cart hiện tại.
      _checkoutKeys.addAll(cart.items.map(_lineKey));
    }

    _routeArgsLoaded = true;
  }

  // Giải phóng tài nguyên (dispose): hủy controller/listener khi widget bị loại khỏi cây giao diện.
  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  // Kiểm tra out các mục (_checkoutItems): xác minh điều kiện/định dạng và trả kết quả cho lớp gọi.
  List<CartItemModel> _checkoutItems(CartProvider cart) {
    return cart.items.where((item) {
      return _checkoutKeys.contains(_lineKey(item));
    }).toList();
  }

  // Định dạng giá (formatPrice): chuyển số tiền thành chuỗi dễ đọc để hiển thị.
  String formatPrice(double price) {
    final text = price.round().toString();

    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final pos = text.length - i;

      result.write(text[i]);

      if (pos > 1 && pos % 3 == 1) {
        result.write('.');
      }
    }

    return '$resultđ';
  }

  // =========================================================
  // PROFILE ADDRESS SYNC
  // =========================================================

  // Xử lý _profileAddresses: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  List<dynamic> _profileAddresses(dynamic profile) {
    try {
      return List<dynamic>.from(profile?.addresses ?? const []);
    } catch (_) {
      return <dynamic>[];
    }
  }

  // Xử lý _findDefaultOrFirstAddress: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  dynamic _findDefaultOrFirstAddress(dynamic profile) {
    final addresses = _profileAddresses(profile);

    if (addresses.isEmpty) {
      return null;
    }

    for (final address in addresses) {
      try {
        if (address.isDefault == true) {
          return address;
        }
      } catch (_) {}
    }

    return addresses.first;
  }

  // Xử lý đã chọn hồ sơ địa chỉ (_resolveSelectedProfileAddress): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù
  // hợp.
  dynamic _resolveSelectedProfileAddress(dynamic profile) {
    final addresses = _profileAddresses(profile);

    if (addresses.isEmpty) {
      return null;
    }

    final selectedId = _selectedProfileAddressId?.trim();

    if (selectedId != null && selectedId.isNotEmpty) {
      for (final address in addresses) {
        if (_addressId(address) == selectedId) {
          return address;
        }
      }
    }

    return _findDefaultOrFirstAddress(profile);
  }

  // Xử lý _receiverName: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  String _receiverName(dynamic address) {
    try {
      return address.receiverName.toString().trim();
    } catch (_) {
      return '';
    }
  }

  // Xử lý _phoneNumber: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  String _phoneNumber(dynamic address) {
    try {
      return address.phoneNumber.toString().trim();
    } catch (_) {
      return '';
    }
  }

  // Thêm ress nhãn (_addressLabel): đưa mục mới vào state/backend và cập nhật giao diện.
  String _addressLabel(dynamic address) {
    try {
      final label = address.label.toString().trim();

      if (label.isNotEmpty) {
        return label;
      }
    } catch (_) {}

    try {
      if (address.isDefault == true) {
        return 'Địa chỉ mặc định';
      }
    } catch (_) {}

    return 'Địa chỉ đã lưu';
  }

  // Xử lý _effectiveDeliveryAddress: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  String _effectiveDeliveryAddress(dynamic profileAddress) {
    final checkoutText = _checkoutAddressText?.trim();

    if (checkoutText != null && checkoutText.isNotEmpty) {
      return checkoutText;
    }

    return _addressLine(profileAddress);
  }

  // Chọn hồ sơ địa chỉ (_selectProfileAddress): lưu lựa chọn để dùng cho lọc, biểu mẫu hoặc nghiệp vụ tiếp theo.
  void _selectProfileAddress(dynamic address) {
    setState(() {
      _selectedProfileAddressId = _addressId(address);

      _checkoutAddressText = _addressLine(address);

      _deliveryAddressSource = 'profile';

      _deliveryQuote = null;
      _deliveryError = null;
      _lastAddressId = null;
    });
  }

  // Tải hồ sơ địa chỉ (_reloadProfileAddresses): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<void> _reloadProfileAddresses({
    bool keepCurrentSelection = true,
  }) async {
    final provider = context.read<ProfileProvider>();

    final oldSelectedId = _selectedProfileAddressId;

    await provider.loadProfile(forceReload: true);

    if (!mounted) {
      return;
    }

    final profile = provider.profile;

    dynamic nextAddress;

    if (keepCurrentSelection &&
        oldSelectedId != null &&
        oldSelectedId.isNotEmpty) {
      final addresses = _profileAddresses(profile);

      for (final address in addresses) {
        if (_addressId(address) == oldSelectedId) {
          nextAddress = address;
          break;
        }
      }
    }

    nextAddress ??= _findDefaultOrFirstAddress(profile);

    setState(() {
      _selectedProfileAddressId = _addressId(nextAddress);

      _checkoutAddressText = _addressLine(nextAddress);

      _deliveryAddressSource = 'profile';

      _deliveryQuote = null;
      _deliveryError = null;
      _lastAddressId = null;
    });
  }

  // Hiển thị địa chỉ picker (_showAddressPicker): mở thông báo/dialog hoặc thành phần hỗ trợ trên giao diện.
  Future<void> _showAddressPicker(dynamic profile) async {
    final addresses = _profileAddresses(profile);

    if (addresses.isEmpty) {
      await Navigator.pushNamed(context, AppRoutes.profile);

      if (!mounted) {
        return;
      }

      await _reloadProfileAddresses(keepCurrentSelection: false);

      return;
    }

    final selectedId = _selectedProfileAddressId;

    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn địa chỉ giao hàng', style: AppText.productTitle),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final address = addresses[index];

                      final isSelected = _addressId(address) == selectedId;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        title: Text(
                          _receiverName(address),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_phoneNumber(address)}\n'
                          '${_addressLine(address)}',
                        ),
                        isThreeLine: true,
                        trailing:
                            _isDefaultAddress(address)
                                ? const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                )
                                : null,
                        onTap: () {
                          Navigator.pop(sheetContext, address);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);

                      await Navigator.pushNamed(context, AppRoutes.profile);

                      if (!mounted) {
                        return;
                      }

                      await _reloadProfileAddresses(keepCurrentSelection: true);
                    },
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Quản lý địa chỉ trong hồ sơ'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    _selectProfileAddress(selected);
  }

  // Kiểm tra điều kiện (_isDefaultAddress): đánh giá trạng thái mặc định địa chỉ và trả kết quả cho lớp gọi.
  bool _isDefaultAddress(dynamic address) {
    try {
      return address.isDefault == true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // DELIVERY
  // =========================================================

  // Thêm ress mã (_addressId): đưa mục mới vào state/backend và cập nhật giao diện.
  String _addressId(dynamic address) {
    try {
      final value = address.id?.toString() ?? '';

      return value.trim();
    } catch (_) {
      return '';
    }
  }

  // Thêm ress dòng (_addressLine): đưa mục mới vào state/backend và cập nhật giao diện.
  String _addressLine(dynamic address) {
    try {
      return address.addressLine.toString().trim();
    } catch (_) {
      return '';
    }
  }

  // Thêm ress vĩ độ (_addressLatitude): đưa mục mới vào state/backend và cập nhật giao diện.
  double _addressLatitude(dynamic address) {
    try {
      final value = address.latitude;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // Thêm ress kinh độ (_addressLongitude): đưa mục mới vào state/backend và cập nhật giao diện.
  double _addressLongitude(dynamic address) {
    try {
      final value = address.longitude;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // Thêm ress has tọa độ (_addressHasCoordinates): đưa mục mới vào state/backend và cập nhật giao diện.
  bool _addressHasCoordinates(dynamic address) {
    final latitude = _addressLatitude(address);
    final longitude = _addressLongitude(address);

    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  // Trì hoãn tính phí (_scheduleSavedDeliveryQuote): chống gọi tính phí lặp khi địa chỉ thay đổi liên tục.
  void _scheduleSavedDeliveryQuote(dynamic address) {
    if (address == null ||
        _isLoadingDelivery ||
        _deliveryAddressSource == 'gps') {
      return;
    }

    final addressId = _addressId(address);
    final addressText = _addressLine(address);
    final latitude = _addressLatitude(address);
    final longitude = _addressLongitude(address);
    final fingerprint = '$addressId|$addressText|$latitude|$longitude';

    if (addressText.isEmpty || _lastAddressId == fingerprint) {
      return;
    }

    _lastAddressId = fingerprint;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _useTypedAddress(address);
    });
  }

  // Dùng GPS hiện tại: tính phí trước, reverse geocode chạy sau để không giữ màn hình loading lâu.
  // Dùng GPS hiện tại (_useCurrentLocation): xin quyền vị trí, lấy tọa độ và tính phí giao hàng.
  Future<void> _useCurrentLocation(dynamic address) async {
    if (address == null || _isLoadingDelivery || _isSubmitting) {
      return;
    }

    setState(() {
      _isLoadingDelivery = true;
      _deliveryError = null;
    });

    try {
      final position = await _deliveryService.getCurrentPosition();

      final quote = await _deliveryService.quoteForCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      // Có quote là cho UI sử dụng ngay; không chờ reverse geocoding.
      setState(() {
        _checkoutAddressText = 'Vị trí giao hàng đã chọn bằng GPS';
        _deliveryAddressSource = 'gps';
        _deliveryQuote = quote;
        _lastAddressId = null;
        _isLoadingDelivery = false;
      });

      try {
        final readableAddress = await _deliveryService
            .resolveCoordinatesToAddress(
              latitude: position.latitude,
              longitude: position.longitude,
            )
            .timeout(const Duration(seconds: 4));

        if (!mounted || _deliveryAddressSource != 'gps') return;

        final value = readableAddress.trim();
        if (value.isNotEmpty) {
          setState(() {
            _checkoutAddressText = value;
          });
        }
      } catch (_) {
        // Tọa độ vẫn đủ để giao hàng/chỉ đường; địa chỉ đọc được chỉ là dữ liệu bổ sung.
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _deliveryError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingDelivery = false;
      });
    }
  }

  // Dùng địa chỉ đã chọn (_useTypedAddress): ưu tiên tọa độ lưu sẵn và tính báo giá giao hàng.
  Future<void> _useTypedAddress(dynamic address) async {
    if (address == null || _isLoadingDelivery || _isSubmitting) {
      return;
    }

    final text = _addressLine(address);

    if (text.isEmpty) {
      setState(() {
        _deliveryError = 'Địa chỉ đang trống.';
      });
      return;
    }

    setState(() {
      _isLoadingDelivery = true;
      _deliveryError = null;
    });

    try {
      double latitude = _addressLatitude(address);
      double longitude = _addressLongitude(address);

      // Ưu tiên tọa độ đã lưu; chỉ geocode khi địa chỉ chưa có tọa độ hợp lệ.
      if (!_addressHasCoordinates(address)) {
        final coordinates = await _deliveryService.resolveAddressText(text);
        latitude = coordinates.latitude;
        longitude = coordinates.longitude;

        final addressId = _addressId(address);

        if (addressId.isNotEmpty) {
          try {
            await _deliveryService.saveAddressCoordinates(
              addressId: addressId,
              latitude: latitude,
              longitude: longitude,
            );
          } catch (_) {
            // Lỗi lưu cache tọa độ không được chặn checkout.
          }
        }
      }

      final quote = await _deliveryService.quoteForCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _checkoutAddressText = text;
        _deliveryAddressSource = 'profile';
        _deliveryQuote = quote;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _deliveryError =
            'Không thể xác định vị trí giao hàng. '
            '${error.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDelivery = false;
        });
      }
    }
  }

  // Làm mới giao hàng báo giá (_refreshDeliveryQuote): tải dữ liệu mới nhất và đồng bộ state hiện tại.
  Future<DeliveryQuote?> _refreshDeliveryQuote() async {
    final current = _deliveryQuote;

    if (current == null) {
      return null;
    }

    return _deliveryService.quoteForCoordinates(
      latitude: current.customerLatitude,
      longitude: current.customerLongitude,
    );
  }

  // Hiển thị thanh toán picker (_showPaymentPicker): mở thông báo/dialog hoặc thành phần hỗ trợ trên giao diện.
  void _showPaymentPicker(List<PaymentMethodModel> methods) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn phương thức thanh toán',
                  style: AppText.productTitle,
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: selectedMethod,
                  onChanged: (value) {
                    if (_isSubmitting || value == null) return;

                    setState(() {
                      selectedMethod = value;
                    });

                    Navigator.pop(sheetContext);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        methods.map((method) {
                          return RadioListTile<String>(
                            value: method.title,
                            enabled: !_isSubmitting,
                            activeColor: AppColors.primary,
                            title: Text(method.title),
                            subtitle: Text(method.subtitle),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Xác nhận thanh toán (_confirmPayment): kiểm tra điều kiện và thực hiện nghiệp vụ sau khi người dùng xác nhận.
  Future<void> _confirmPayment({
    required BuildContext context,
    required CartProvider cart,
    required dynamic address,
  }) async {
    if (_isSubmitting) return;

    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm địa chỉ giao hàng.')),
      );
      return;
    }

    final currentQuote = _deliveryQuote;

    if (currentQuote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng xác định vị trí giao hàng trước khi đặt đơn.'),
        ),
      );
      return;
    }

    if (!currentQuote.isDeliverable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentQuote.message)),
      );
      return;
    }

    if (selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phương thức thanh toán.')),
      );
      return;
    }

    final checkoutItems = _checkoutItems(cart);

    if (checkoutItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không còn sản phẩm nào để thanh toán.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Chỉ xác nhận lại phí giao hàng. Giá và trạng thái sản phẩm được
      // OrderService kiểm tra trực tiếp trên PocketBase trước khi tạo đơn.
      final latestDeliveryQuote = await _refreshDeliveryQuote();

      if (!context.mounted) return;

      if (latestDeliveryQuote == null || !latestDeliveryQuote.isDeliverable) {
        setState(() {
          _deliveryQuote = latestDeliveryQuote;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              latestDeliveryQuote?.message ?? 'Không thể xác nhận phí giao hàng.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _deliveryQuote = latestDeliveryQuote;
      });

      final itemTotal = checkoutItems.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );
      final total = itemTotal + latestDeliveryQuote.deliveryFee;
      final orderProvider = context.read<OrderProvider>();

      final success = await orderProvider.placeOrder(
        checkoutItems,
        total,
        receiverName: _receiverName(address),
        receiverPhone: _phoneNumber(address),
        address: _effectiveDeliveryAddress(address),
        deliveryLatitude: latestDeliveryQuote.customerLatitude,
        deliveryLongitude: latestDeliveryQuote.customerLongitude,
        paymentMethod: selectedMethod!,
        note: noteController.text.trim(),
      );

      if (!context.mounted) return;

      if (!success) {
        // Chỉ tải lại giỏ khi backend phát hiện giá/trạng thái sản phẩm thay đổi.
        await cart.refreshCart();

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Đặt hàng thất bại'),
          ),
        );
        return;
      }

      PaymentRecordModel? paymentRecord;
      String paymentRecordMessage = '';
      final createdOrder = orderProvider.selectedOrder;

      if (createdOrder != null) {
        try {
          paymentRecord = await _paymentService.ensureInitialPayment(
            orderId: createdOrder.id,
            method: selectedMethod!,
            amount: createdOrder.totalAmount,
          );

          paymentRecordMessage = _paymentService.isCashMethod(selectedMethod!)
              ? 'Thanh toán khi nhận hàng. Trạng thái: chưa thanh toán.'
              : 'Yêu cầu thanh toán demo đã được tạo và đang chờ xác nhận.';
        } catch (error) {
          debugPrint('Không thể tạo payment cho order ${createdOrder.id}: $error');
          paymentRecordMessage =
              'Đơn hàng đã tạo nhưng giao dịch thanh toán chưa đồng bộ. '
              'Bạn có thể tiếp tục thanh toán trong chi tiết đơn hàng.';
        }
      } else {
        paymentRecordMessage = 'Đơn hàng đã tạo nhưng chưa đọc được dữ liệu đơn.';
      }

      final cleanupSuccess = await cart.removePurchasedItems(checkoutItems);

      if (!context.mounted) return;

      final hasRemainingItems = cart.items.isNotEmpty;
      final cartMessage = cleanupSuccess
          ? (hasRemainingItems
              ? 'Các sản phẩm chưa thanh toán vẫn được giữ trong giỏ.'
              : 'Giỏ hàng hiện đã trống.')
          : 'Giỏ hàng chưa đồng bộ hoàn toàn; vui lòng tải lại trước đơn tiếp theo.';

      final isCash = _paymentService.isCashMethod(selectedMethod!);

      if (!isCash && createdOrder != null && paymentRecord != null) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.paymentTest,
          arguments: {'orderId': createdOrder.id},
        );
        return;
      }

      final dialogMessage =
          'Đơn hàng đã được ghi nhận. $paymentRecordMessage $cartMessage';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đặt hàng thành công',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Text(dialogMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
                },
                child: const Text('Về trang chủ'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacementNamed(context, AppRoutes.orders);
                },
                child: const Text('Xem đơn hàng'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Xây dựng giao diện (build): dựng cây widget của _PaymentPageState từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final profile = context.watch<ProfileProvider>().profile;

    final address = _resolveSelectedProfileAddress(profile);

    final methods = profile?.paymentMethods ?? [];

    _scheduleSavedDeliveryQuote(address);

    final checkoutItems = _checkoutItems(cart);

    if (_routeArgsLoaded && checkoutItems.isEmpty) {
      return AppLayout(
        title: 'Thanh toán',
        showBack: true,
        child: AppBody(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_checkout,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không còn sản phẩm để thanh toán.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Quay lại giỏ hàng'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppLayout(
      title: 'Thanh toán',
      showBack: true,
      child: AppBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            children: [
              _itemsSection(checkoutItems),
              const SizedBox(height: 16),
              _addressSection(context, profile, address),
              const SizedBox(height: 16),
              _paymentSection(methods),
              const SizedBox(height: 16),
              _noteSection(),
              const SizedBox(height: 20),
              _totalSection(context, cart, address, checkoutItems),
            ],
          ),
        ),
      ),
    );
  }

  // Xử lý _itemsSection: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  Widget _itemsSection(List<CartItemModel> items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Sản phẩm thanh toán', style: AppText.productTitle),
              ),
              Text(
                '${items.length} dòng',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];

            return Column(
              children: [
                if (index > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: AppText.productTitle),
                            const SizedBox(height: 3),
                            Text(
                              '${formatPrice(item.price)} × ${item.quantity}',
                              style: AppText.body.copyWith(
                                color: AppColors.textGrey,
                              ),
                            ),
                            if (item.note.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Ghi chú: ${item.note}',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(formatPrice(item.subtotal), style: AppText.price),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Thêm ress khu vực (_addressSection): đưa mục mới vào state/backend và cập nhật giao diện.
  Widget _addressSection(
    BuildContext context,
    dynamic profile,
    dynamic address,
  ) {
    final displayAddress = _effectiveDeliveryAddress(address);

    final bool usingGps = _deliveryAddressSource == 'gps';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Địa chỉ giao hàng', style: AppText.productTitle),
              ),
              TextButton(
                onPressed:
                    _isSubmitting
                        ? null
                        : () {
                          _showAddressPicker(profile);
                        },
                child: const Text('Chọn địa chỉ'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (address != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _receiverName(address),
                    style: AppText.productTitle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        usingGps
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    usingGps ? 'GPS hiện tại' : _addressLabel(address),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          usingGps
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF6A1B9A),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(_phoneNumber(address), style: AppText.body),

            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  usingGps ? Icons.my_location : Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    displayAddress.isNotEmpty
                        ? displayAddress
                        : 'Chưa có địa chỉ giao hàng.',
                    style: AppText.body,
                  ),
                ),
              ],
            ),

            if (usingGps) ...[
              const SizedBox(height: 7),
              Text(
                'Vị trí GPS chỉ dùng cho đơn hàng hiện tại; '
                'không tự ghi đè địa chỉ đã lưu trong hồ sơ.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],

            const SizedBox(height: 14),

            if (_isLoadingDelivery)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đang xác định vị trí và tính phí giao hàng...',
                    ),
                  ),
                ],
              )
            else if (_deliveryQuote != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _deliveryQuote!.isDeliverable
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deliveryQuote!.isDeliverable
                          ? 'Có thể giao hàng'
                          : 'Ngoài phạm vi giao',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            _deliveryQuote!.isDeliverable
                                ? const Color(0xFF2E7D32)
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Khoảng cách: '
                      '${_deliveryQuote!.distanceKm.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(height: 3),
                    if (_deliveryQuote!.isDeliverable)
                      Text(
                        'Phí giao hàng: '
                        '${formatPrice(_deliveryQuote!.deliveryFee)}',
                      )
                    else
                      Text(
                        _deliveryQuote!.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),

            if (_deliveryError != null) ...[
              const SizedBox(height: 8),
              Text(
                _deliveryError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isSubmitting || _isLoadingDelivery
                            ? null
                            : () {
                              _useTypedAddress(address);
                            },
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Dùng địa chỉ hồ sơ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSubmitting || _isLoadingDelivery
                            ? null
                            : () {
                              _useCurrentLocation(address);
                            },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Dùng GPS hiện tại'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : () async {
                          await Navigator.pushNamed(context, AppRoutes.profile);

                          if (!mounted) {
                            return;
                          }

                          await _reloadProfileAddresses(
                            keepCurrentSelection: true,
                          );
                        },
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: const Text('Quản lý địa chỉ trong hồ sơ'),
              ),
            ),
          ] else ...[
            Text(
              'Chưa có địa chỉ trong hồ sơ.',
              style: AppText.body.copyWith(color: AppColors.textGrey),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : () async {
                          await Navigator.pushNamed(context, AppRoutes.profile);

                          if (!mounted) {
                            return;
                          }

                          await _reloadProfileAddresses(
                            keepCurrentSelection: false,
                          );
                        },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Thêm địa chỉ trong hồ sơ'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Xử lý _paymentSection: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  Widget _paymentSection(List<PaymentMethodModel> methods) {
    if (methods.isEmpty) {
      return AppCard(
        child: Text(
          'Chưa có phương thức thanh toán',
          style: AppText.body.copyWith(color: AppColors.textGrey),
        ),
      );
    }

    final current = methods.firstWhere(
      (m) => m.title == selectedMethod,
      orElse: () => methods.first,
    );

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phương thức thanh toán',
                  style: AppText.productTitle,
                ),
              ),
              TextButton(
                onPressed:
                    _isSubmitting ? null : () => _showPaymentPicker(methods),
                child: const Text('Thay đổi'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.payment_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${current.title}\n${current.subtitle}',
                  style: AppText.body,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Xử lý _noteSection: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  Widget _noteSection() {
    return AppCard(
      child: TextField(
        controller: noteController,
        enabled: !_isSubmitting,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Ghi chú',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // Xử lý _totalSection: thực hiện phần nghiệp vụ tương ứng trong màn hình thanh toán.
  Widget _totalSection(
    BuildContext context,
    CartProvider cart,
    dynamic address,
    List<CartItemModel> items,
  ) {
    final double originalTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.originalSubtotal,
    );

    final double discount = items.fold<double>(
      0,
      (sum, item) => sum + item.totalDiscount,
    );

    final double itemTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    final double deliveryFee =
        _deliveryQuote?.isDeliverable == true ? _deliveryQuote!.deliveryFee : 0;

    final double total = itemTotal + deliveryFee;

    return AppCard(
      child: Column(
        children: [
          if (discount > 0) ...[
            Row(
              children: [
                Text('Giá gốc', style: TextStyle(color: AppColors.textGrey)),
                const Spacer(),
                Text(
                  formatPrice(originalTotal),
                  style: TextStyle(
                    color: AppColors.textGrey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Text(
                  'Khuyến mãi',
                  style: TextStyle(color: Color(0xFF2E7D32)),
                ),
                const Spacer(),
                Text(
                  '-${formatPrice(discount)}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
          ],

          Row(
            children: [
              Text(
                'Tạm tính sản phẩm',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const Spacer(),
              Text(formatPrice(itemTotal)),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Text(
                'Phí giao hàng',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const Spacer(),
              Text(
                _deliveryQuote == null
                    ? 'Chưa tính'
                    : (_deliveryQuote!.isDeliverable
                        ? formatPrice(deliveryFee)
                        : 'Không giao'),
                style: TextStyle(
                  color:
                      _deliveryQuote != null && !_deliveryQuote!.isDeliverable
                          ? Colors.red
                          : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Divider(),

          Row(
            children: [
              Text('Tổng thanh toán', style: AppText.productTitle),
              const Spacer(),
              Text(formatPrice(total), style: AppText.total),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed:
                  _isSubmitting ||
                          _deliveryQuote == null ||
                          !_deliveryQuote!.isDeliverable
                      ? null
                      : () {
                        _confirmPayment(
                          context: context,
                          cart: cart,
                          address: address,
                        );
                      },
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Xác nhận thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

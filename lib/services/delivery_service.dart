// FILE HỌC TẬP: lib/services/delivery_service.dart
// Vai trò: Service nghiệp vụ giao hàng.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'dart:math' as math;

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/delivery_quote_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// Lớp DeliveryService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class DeliveryService {
  static _StoreLocation? _cachedStore;
  static DateTime? _cachedStoreAt;
  static const Duration _storeCacheDuration = Duration(minutes: 5);
  // Không khởi tạo Geocoding ngay lập tức.
  // Package geocoding không hỗ trợ Flutter Web.
  Geocoding? _geocoding;

  // Đọc native geocoding (_nativeGeocoding): trả giá trị hiện tại cho UI/nghiệp vụ mà không thay đổi state.
  Geocoding get _nativeGeocoding {
    if (kIsWeb) {
      throw UnsupportedError(
        'Geocoding không hỗ trợ trực tiếp trên Flutter Web.',
      );
    }

    return _geocoding ??= Geocoding();
  }

  // =========================================================
  // CURRENT GPS
  // =========================================================

  // Lấy hiện tại position (getCurrentPosition): truy xuất và trả kết quả cho lớp gọi.
  Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Dịch vụ vị trí đang tắt. '
        'Vui lòng bật GPS hoặc dùng địa chỉ đã nhập.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Bạn chưa cấp quyền vị trí. '
        'Có thể dùng địa chỉ đã nhập để tính phí giao hàng.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đã bị từ chối vĩnh viễn. '
        'Hãy bật lại quyền trong cài đặt ứng dụng '
        'hoặc dùng địa chỉ đã nhập.',
      );
    }

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  // =========================================================
  // MANUAL ADDRESS -> COORDINATES
  // =========================================================

  Future<({double latitude, double longitude})> resolveAddressText(
    String addressText,
  ) async {
    final text = addressText.trim();

    if (text.isEmpty) {
      throw Exception('Địa chỉ đang trống.');
    }

    if (kIsWeb) {
      throw UnsupportedError(
        'Chức năng chuyển địa chỉ thành tọa độ '
        'chưa hỗ trợ trực tiếp trên phiên bản Web.',
      );
    }

    final candidates = <String>[
      text,
      if (!text.toLowerCase().contains('việt nam')) '$text, Việt Nam',
    ];

    Object? lastError;

    for (final candidate in candidates) {
      try {
        final locations = await _nativeGeocoding
            .locationFromAddress(candidate)
            .timeout(const Duration(seconds: 8));

        if (locations.isNotEmpty) {
          final first = locations.first;

          if (_validCoordinate(first.latitude, first.longitude)) {
            return (latitude: first.latitude, longitude: first.longitude);
          }
        }
      } catch (e) {
        lastError = e;
      }

      // Cho native geocoder nghỉ ngắn trước lần retry.
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }

    debugPrint(
      'resolveAddressText failed: '
      '$text | $lastError',
    );

    throw Exception(
      'Không xác định được tọa độ từ địa chỉ. '
      'Vui lòng nhập đầy đủ số nhà, đường, '
      'phường/xã, quận/huyện và tỉnh/thành.',
    );
  }
  // =========================================================
  // COORDINATES -> HUMAN READABLE ADDRESS
  // =========================================================

  // Xử lý tọa độ to địa chỉ (resolveCoordinatesToAddress): chuẩn hóa điều kiện đầu vào và thực hiện nhánh nghiệp vụ phù hợp.
  Future<String> resolveCoordinatesToAddress({
    required double latitude,
    required double longitude,
  }) async {
    if (!_validCoordinate(latitude, longitude)) {
      throw Exception('Tọa độ không hợp lệ.');
    }

    // Flutter Web:
    // Không gọi plugin geocoding native.
    if (kIsWeb) {
      return 'Vị trí giao hàng đã chọn bằng GPS';
    }

    final placemarks = await _nativeGeocoding.placemarkFromCoordinates(
      latitude,
      longitude,
      locale: const Locale('vi', 'VN'),
    );

    if (placemarks.isEmpty) {
      throw Exception('Không xác định được địa chỉ từ vị trí GPS.');
    }

    final place = placemarks.first;

    final rawParts = <String>[
      place.street ?? '',
      place.subLocality ?? '',
      place.locality ?? '',
      place.subAdministrativeArea ?? '',
      place.administrativeArea ?? '',
      place.country ?? '',
    ];

    final parts = <String>[];

    for (final raw in rawParts) {
      final value = raw.trim();

      if (value.isEmpty) {
        continue;
      }

      final alreadyExists = parts.any(
        (item) => item.toLowerCase() == value.toLowerCase(),
      );

      if (!alreadyExists) {
        parts.add(value);
      }
    }

    if (parts.isEmpty) {
      return 'Vị trí giao hàng đã chọn bằng GPS';
    }

    return parts.join(', ');
  }

  // =========================================================
  // SAVED ADDRESS COORDINATES
  // =========================================================

  // Tính báo giá from saved địa chỉ (quoteFromSavedAddress): xác định khoảng cách/phí và trả kết quả giao hàng.
  Future<DeliveryQuote?> quoteFromSavedAddress(String addressId) async {
    if (addressId.trim().isEmpty) {
      return null;
    }

    try {
      final record = await pb.collection('addresses').getOne(addressId);

      final latitude = _toDouble(record.data['latitude']);

      final longitude = _toDouble(record.data['longitude']);

      if (!_validCoordinate(latitude, longitude)) {
        return null;
      }

      return quoteForCoordinates(latitude: latitude, longitude: longitude);
    } catch (_) {
      return null;
    }
  }

  // Lưu địa chỉ tọa độ (saveAddressCoordinates): kiểm tra dữ liệu, ghi thay đổi và đồng bộ state sau khi thành công.
  Future<void> saveAddressCoordinates({
    required String addressId,
    required double latitude,
    required double longitude,
  }) async {
    if (addressId.trim().isEmpty) {
      return;
    }

    if (!_validCoordinate(latitude, longitude)) {
      throw Exception('Tọa độ địa chỉ không hợp lệ.');
    }

    await pb
        .collection('addresses')
        .update(
          addressId,
          body: {'latitude': latitude, 'longitude': longitude},
        );
  }

  // =========================================================
  // DELIVERY QUOTE
  // =========================================================

  // Tính báo giá for tọa độ (quoteForCoordinates): xác định khoảng cách/phí và trả kết quả giao hàng.
  Future<DeliveryQuote> quoteForCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (!_validCoordinate(latitude, longitude)) {
      throw Exception('Tọa độ giao hàng không hợp lệ.');
    }

    final store = await _loadActiveStore();

    final distanceKm = _haversineKm(
      store.latitude,
      store.longitude,
      latitude,
      longitude,
    );

    final radius = store.deliveryRadiusKm > 0 ? store.deliveryRadiusKm : 10.0;

    if (distanceKm > radius) {
      return DeliveryQuote(
        storeId: store.id,
        storeName: store.name,
        storeLatitude: store.latitude,
        storeLongitude: store.longitude,
        customerLatitude: latitude,
        customerLongitude: longitude,
        distanceKm: distanceKm,
        deliveryFee: 0,
        deliveryRadiusKm: radius,
        isDeliverable: false,
        message:
            'Địa chỉ cách cửa hàng '
            '${distanceKm.toStringAsFixed(1)} km, '
            'vượt phạm vi giao '
            '${radius.toStringAsFixed(1)} km.',
      );
    }

    final double fee;

    if (distanceKm <= 3) {
      fee = 15000;
    } else if (distanceKm <= 7) {
      fee = 25000;
    } else {
      fee = 35000;
    }

    return DeliveryQuote(
      storeId: store.id,
      storeName: store.name,
      storeLatitude: store.latitude,
      storeLongitude: store.longitude,
      customerLatitude: latitude,
      customerLongitude: longitude,
      distanceKm: distanceKm,
      deliveryFee: fee,
      deliveryRadiusKm: radius,
      isDeliverable: true,
      message:
          'Khoảng cách '
          '${distanceKm.toStringAsFixed(1)} km '
          '• Phí giao hàng '
          '${fee.toStringAsFixed(0)}đ',
    );
  }

  // =========================================================
  // STORE
  // =========================================================

  // Tải đang hoạt động cửa hàng (_loadActiveStore): lấy dữ liệu cần cho màn hình và cập nhật state hiển thị.
  Future<_StoreLocation> _loadActiveStore() async {
    final cached = _cachedStore;
    final cachedAt = _cachedStoreAt;

    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _storeCacheDuration) {
      return cached;
    }

    final records = await pb
        .collection('stores')
        .getFullList(filter: 'isActive = true', sort: '-updated');

    if (records.isEmpty) {
      throw Exception(
        'Chưa cấu hình cửa hàng giao hàng trong PocketBase.',
      );
    }

    final record = records.first;
    final latitude = _toDouble(record.data['latitude']);
    final longitude = _toDouble(record.data['longitude']);

    if (!_validCoordinate(latitude, longitude)) {
      throw Exception('Tọa độ cửa hàng chưa được cấu hình đúng.');
    }

    final store = _StoreLocation(
      id: record.id,
      name: (record.data['name'] ?? 'YourFood').toString(),
      latitude: latitude,
      longitude: longitude,
      deliveryRadiusKm: _toDouble(record.data['deliveryRadius']),
    );

    _cachedStore = store;
    _cachedStoreAt = DateTime.now();

    return store;
  }

  // Làm mới cấu hình giao hàng: dùng khi Manager thay đổi tọa độ hoặc bán kính cửa hàng.
  // Xử lý invalidateStoreCache: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ giao hàng.
  static void invalidateStoreCache() {
    _cachedStore = null;
    _cachedStoreAt = null;
  }

  // Xử lý _haversineKm: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ giao hàng.
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);

    final dLon = _toRadians(lon2 - lon1);

    final lat1Rad = _toRadians(lat1);

    final lat2Rad = _toRadians(lat2);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  // Xử lý _toRadians: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ giao hàng.
  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  // Xử lý _validCoordinate: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ giao hàng.
  bool _validCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  // Xử lý _toDouble: thực hiện phần nghiệp vụ tương ứng trong service nghiệp vụ giao hàng.
  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// Lớp _StoreLocation: thành phần phục vụ service nghiệp vụ giao hàng.
class _StoreLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double deliveryRadiusKm;

  // Khởi tạo _StoreLocation: nhận các tham số cần thiết để tạo đối tượng cho service nghiệp vụ giao hàng.
  const _StoreLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.deliveryRadiusKm,
  });
}

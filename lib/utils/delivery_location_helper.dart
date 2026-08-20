
class DeliveryLocationData {
  final String address;
  final double latitude;
  final double longitude;

  const DeliveryLocationData({
    required this.address,
    this.latitude = 0,
    this.longitude = 0,
  });

  bool get hasCoordinates {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }
}

class DeliveryLocationHelper {
  static final RegExp _metadataPattern = RegExp(
    r'\[\[GPS:([+-]?(?:\d+\.?\d*|\.\d+)),([+-]?(?:\d+\.?\d*|\.\d+))\]\]',
    caseSensitive: false,
  );

  static final RegExp _legacyGpsPattern = RegExp(
    r'^Vị trí GPS\s+([+-]?(?:\d+\.?\d*|\.\d+))\s*,\s*([+-]?(?:\d+\.?\d*|\.\d+))$',
    caseSensitive: false,
  );

  static String encode({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    final cleanedAddress = displayAddress(address);

    if (!_isValidCoordinate(latitude, longitude)) {
      return cleanedAddress;
    }

    final visibleAddress =
        cleanedAddress.isEmpty ? 'Vị trí giao hàng đã chọn' : cleanedAddress;

    return '$visibleAddress\n'
        '[[GPS:${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}]]';
  }

  static DeliveryLocationData decode(String rawValue) {
    final raw = rawValue.trim();

    if (raw.isEmpty) {
      return const DeliveryLocationData(address: '');
    }

    final metadataMatch = _metadataPattern.firstMatch(raw);

    if (metadataMatch != null) {
      final latitude = double.tryParse(metadataMatch.group(1) ?? '') ?? 0;
      final longitude = double.tryParse(metadataMatch.group(2) ?? '') ?? 0;
      final address = raw.replaceAll(_metadataPattern, '').trim();

      return DeliveryLocationData(
        address: address.isEmpty ? 'Vị trí giao hàng đã chọn' : address,
        latitude: latitude,
        longitude: longitude,
      );
    }

    final legacyMatch = _legacyGpsPattern.firstMatch(raw);

    if (legacyMatch != null) {
      return DeliveryLocationData(
        address: 'Vị trí giao hàng đã chọn',
        latitude: double.tryParse(legacyMatch.group(1) ?? '') ?? 0,
        longitude: double.tryParse(legacyMatch.group(2) ?? '') ?? 0,
      );
    }

    return DeliveryLocationData(address: raw);
  }

  static String displayAddress(String rawValue) {
    return decode(rawValue).address;
  }

  static bool _isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }
}

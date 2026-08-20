// FILE HỌC TẬP: lib/services/map_navigation_service.dart
// Vai trò: Service nghiệp vụ điều hướng bản đồ.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'package:url_launcher/url_launcher.dart';

// Lớp MapNavigationService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class MapNavigationService {
  // Khởi tạo MapNavigationService._: tạo đối tượng MapNavigationService bằng constructor _ từ dữ liệu đầu vào.
  const MapNavigationService._();

  // Tạo liên kết chỉ đường: Google Maps tự dùng vị trí hiện tại làm điểm xuất phát.
  // Tạo giao diện chỉ đường uri (buildDirectionsUri): dựng widget con từ dữ liệu hiện tại.
  static Uri buildDirectionsUri({
    required double latitude,
    required double longitude,
  }) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });
  }

  // Mở chỉ đường: dùng ứng dụng bản đồ hoặc trình duyệt phù hợp với nền tảng.
  // Mở chỉ đường (openDirections): tạo Google Maps URL từ tọa độ giao hàng và mở trên thiết bị.
  static Future<void> openDirections({
    required double latitude,
    required double longitude,
  }) async {
    final uri = buildDirectionsUri(
      latitude: latitude,
      longitude: longitude,
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!opened) {
      throw Exception('Không thể mở ứng dụng bản đồ.');
    }
  }
}

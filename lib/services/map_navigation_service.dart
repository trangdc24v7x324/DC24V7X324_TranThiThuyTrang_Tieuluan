
import 'package:url_launcher/url_launcher.dart';

class MapNavigationService {

  const MapNavigationService._();

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

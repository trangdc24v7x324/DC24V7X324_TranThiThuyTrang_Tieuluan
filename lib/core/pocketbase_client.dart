// FILE HỌC TẬP: lib/core/pocketbase_client.dart
// Vai trò: Quản lý kết nối PocketBase dùng chung.
// Luồng sử dụng: Khởi tạo client, phục hồi phiên đăng nhập và cung cấp client cho các Service.

import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Địa chỉ PocketBase mặc định khi chạy trên Android Emulator.
///
/// Địa chỉ Host-only ổn định của Ubuntu Server VirtualBox.
/// Nginx lắng nghe cổng 80 và reverse proxy đến PocketBase 127.0.0.1:8090.
const String _defaultPocketBaseUrl = 'http://192.168.56.102';

/// Khóa dùng để lưu phiên đăng nhập PocketBase.
const String _authStorageKey = 'pb_auth';

late final PocketBase pb;

bool _isPocketBaseInitialized = false;

/// Trả về PocketBase client dùng chung của toàn ứng dụng.
///
/// Phải gọi [initPocketBase] trước khi sử dụng hàm này.
// Lấy PocketBase client (getPocketBase): trả client dùng chung và báo lỗi nếu chưa khởi tạo.
PocketBase getPocketBase() {
  if (!_isPocketBaseInitialized) {
    throw StateError(
      'PocketBase chưa được khởi tạo. '
      'Hãy gọi initPocketBase() trước runApp().',
    );
  }

  return pb;
}

/// Khởi tạo PocketBase client và phục hồi phiên đăng nhập.
///
/// URL PocketBase có thể được truyền khi chạy ứng dụng:
///
/// flutter run --dart-define=POCKETBASE_URL=http://192.168.56.102
// Khởi tạo PocketBase (initPocketBase): tạo client, phục hồi phiên đăng nhập và chuẩn bị backend.
Future<void> initPocketBase() async {
  if (_isPocketBaseInitialized) {
    return;
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const String pocketBaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: _defaultPocketBaseUrl,
  );

  pb = PocketBase(
    pocketBaseUrl,
    authStore: AsyncAuthStore(
      initial: prefs.getString(_authStorageKey),
      save: (String data) async {
        await prefs.setString(_authStorageKey, data);
      },
      clear: () async {
        await prefs.remove(_authStorageKey);
      },
    ),
  );

  _isPocketBaseInitialized = true;
}

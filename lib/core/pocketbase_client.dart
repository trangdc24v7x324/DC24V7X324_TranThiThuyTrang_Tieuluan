
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _defaultPocketBaseUrl = 'http://192.168.56.102';

const String _authStorageKey = 'pb_auth';

late final PocketBase pb;

bool _isPocketBaseInitialized = false;

PocketBase getPocketBase() {
  if (!_isPocketBaseInitialized) {
    throw StateError(
      'PocketBase chưa được khởi tạo. '
      'Hãy gọi initPocketBase() trước runApp().',
    );
  }

  return pb;
}

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

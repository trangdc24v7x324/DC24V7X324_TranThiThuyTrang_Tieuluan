import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_home_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_home_page.dart';

/// Tự chọn giao diện Manager theo nền tảng.
///
/// - Flutter Web: dùng giao diện web mới.
/// - Android/iOS/desktop app: giữ nguyên ManagerHomePage hiện tại.
class ManagerHomeEntryPage extends StatelessWidget {
  const ManagerHomeEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebHomePage();
    }

    return const ManagerHomePage();
  }
}

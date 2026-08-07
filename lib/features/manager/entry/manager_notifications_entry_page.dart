import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:CT466_project_trangdc24v7x324/features/notification/manager_notifications_page.dart';
import 'package:CT466_project_trangdc24v7x324/features/manager/web/screens/manager_web_notifications_page.dart';

class ManagerNotificationsEntryPage extends StatelessWidget {
  const ManagerNotificationsEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebNotificationsPage();
    }

    return const ManagerNotificationsPage();
  }
}

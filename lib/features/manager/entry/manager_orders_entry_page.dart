import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:CT466_project_trangdc24v7x324/features/manager/app/screens/manager_orders_page.dart';
import 'package:CT466_project_trangdc24v7x324/features/manager/web/screens/manager_web_orders_page.dart';

class ManagerOrdersEntryPage extends StatelessWidget {
  const ManagerOrdersEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebOrdersPage();
    }

    return const ManagerOrdersPage();
  }
}


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_revenue_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_revenue_page.dart';

class ManagerRevenueEntryPage extends StatelessWidget {

  const ManagerRevenueEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebRevenuePage();
    }

    return const ManagerRevenuePage();
  }
}

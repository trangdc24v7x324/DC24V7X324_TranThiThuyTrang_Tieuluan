
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_products_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_products_page.dart';

class ManagerProductsEntryPage extends StatelessWidget {

  const ManagerProductsEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebProductsPage();
    }

    return const ManagerProductsPage();
  }
}

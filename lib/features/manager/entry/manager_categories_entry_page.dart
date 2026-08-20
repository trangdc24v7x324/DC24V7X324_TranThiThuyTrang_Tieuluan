
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:project_trangdc24v7x324/features/manager/app/screens/manager_categories_page.dart';
import 'package:project_trangdc24v7x324/features/manager/web/screens/manager_web_categories_page.dart';

class ManagerCategoriesEntryPage extends StatelessWidget {

  const ManagerCategoriesEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebCategoriesPage();
    }

    return const ManagerCategoriesPage();
  }
}

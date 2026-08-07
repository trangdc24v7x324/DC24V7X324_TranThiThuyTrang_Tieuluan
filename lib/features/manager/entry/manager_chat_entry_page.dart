import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:CT466_project_trangdc24v7x324/features/chat/screens/manager_chat_list_page.dart';
import 'package:CT466_project_trangdc24v7x324/features/manager/web/screens/manager_web_chat_page.dart';

class ManagerChatEntryPage extends StatelessWidget {
  const ManagerChatEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const ManagerWebChatPage();
    }

    return const ManagerChatListPage();
  }
}

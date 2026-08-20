// FILE HỌC TẬP: lib/main.dart
// Vai trò: Điểm khởi động ứng dụng YourFood.
// Luồng sử dụng: Khởi tạo PocketBase, đăng ký các Provider và cấu hình MaterialApp cùng hệ thống route.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/providers/cart_provider.dart';
import 'package:project_trangdc24v7x324/providers/order_provider.dart';
import 'package:project_trangdc24v7x324/providers/product_provider.dart';
import 'package:project_trangdc24v7x324/providers/profile_provider.dart';
import 'package:project_trangdc24v7x324/providers/chat_provider.dart';
import 'package:project_trangdc24v7x324/providers/notification_provider.dart';
import 'package:project_trangdc24v7x324/routes/app_routes.dart';
import 'package:project_trangdc24v7x324/providers/review_provider.dart';

// Khởi động ứng dụng (main): bảo đảm Flutter sẵn sàng, khởi tạo PocketBase rồi chạy MyApp.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initPocketBase();

  runApp(const MyApp());
}

// Lớp MyApp: thành phần phục vụ điểm khởi động ứng dụng yourfood.
class MyApp extends StatelessWidget {
  // Khởi tạo MyApp: nhận các tham số cần thiết để tạo đối tượng cho điểm khởi động ứng dụng yourfood.
  const MyApp({super.key});

  // Xây dựng giao diện (build): dựng cây widget của MyApp từ dữ liệu và state hiện tại.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'YourFood',
        theme: ThemeData(
          textTheme: GoogleFonts.robotoTextTheme(),
          primarySwatch: Colors.blue,
        ),
        builder: (context, child) {
          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

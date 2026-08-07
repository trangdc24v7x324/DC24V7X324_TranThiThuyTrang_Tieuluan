import 'package:project_trangdc24v7x324/features/auth/screens/forgot_password_page.dart';
import 'package:project_trangdc24v7x324/features/auth/screens/login_page.dart';
import 'package:project_trangdc24v7x324/features/auth/screens/register_page.dart';
import 'package:project_trangdc24v7x324/features/auth/screens/splash_screen.dart';
import 'package:project_trangdc24v7x324/features/chat/screens/chat_page.dart';
import 'package:project_trangdc24v7x324/features/manager/entry/manager_categories_entry_page.dart';
import 'package:project_trangdc24v7x324/features/manager/entry/manager_chat_entry_page.dart';
import 'package:project_trangdc24v7x324/features/manager/entry/manager_home_entry_page.dart';
import 'package:project_trangdc24v7x324/features/manager/entry/manager_notifications_entry_page.dart';
import 'package:project_trangdc24v7x324/features/manager/entry/manager_orders_entry_page.dart';
import 'package:project_trangdc24v7x324/features/manager/entry/manager_products_entry_page.dart';
import 'package:project_trangdc24v7x324/features/manager/entry/manager_revenue_entry_page.dart';
import 'package:project_trangdc24v7x324/features/notification/notification_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/cart_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/favourite_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/home_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/order_detail_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/orders_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/payment_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/payment_test_page.dart';
import 'package:project_trangdc24v7x324/features/product/screens/product_page.dart';
import 'package:project_trangdc24v7x324/features/profile/screens/profile_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';

  // Customer
  static const String home = '/home';
  static const String product = '/product';
  static const String profile = '/profile';
  static const String favourite = '/favourite';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String notifications = '/notifications';
  static const String payment = '/payment';
  static const String paymentTest = '/payment-test';
  static const String orderDetail = '/order-detail';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Manager
  static const String managerHome = '/manager-home';
  static const String managerOrders = '/manager-orders';
  static const String managerRevenue = '/manager-revenue';
  static const String managerProducts = '/manager-products';
  static const String managerCategories = '/manager-categories';
  static const String managerChat = '/manager-chat';
  static const String managerChatDetail = '/manager-chat-detail';
  static const String managerNotifications = '/manager-notifications';

  static Map<String, WidgetBuilder> get routes => {
    // Auth
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    forgotPassword: (context) => const ForgotPasswordPage(),

    // Customer
    home: (context) => const HomePage(),
    product: (context) => const ProductPage(),
    profile: (context) => const ProfilePage(),
    favourite: (context) => const FavouritePage(),
    cart: (context) => const CartPage(),
    orders: (context) => const OrdersPage(),
    notifications: (context) => const NotificationsPage(),
    payment: (context) => const PaymentPage(),

    // Manager
    // EntryPage sẽ tự chọn giao diện Web hoặc giao diện app bằng kIsWeb.
    managerHome: (context) => const ManagerHomeEntryPage(),
    managerProducts: (context) => const ManagerProductsEntryPage(),
    managerCategories: (context) => const ManagerCategoriesEntryPage(),
    managerOrders: (context) => const ManagerOrdersEntryPage(),
    managerRevenue: (context) => const ManagerRevenueEntryPage(),
    managerChat: (context) => const ManagerChatEntryPage(),
    managerNotifications: (context) => const ManagerNotificationsEntryPage(),
  };

  /// Các route cần nhận arguments động được xử lý tại đây.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case managerChatDetail:
        return _buildManagerChatDetailRoute(settings);

      case orderDetail:
        return _buildOrderDetailRoute(settings);

      case paymentTest:
        return _buildPaymentTestRoute(settings);
    }

    return null;
  }

  static Route<dynamic> _buildManagerChatDetailRoute(RouteSettings settings) {
    final args = settings.arguments;

    if (args is Map<String, dynamic>) {
      final otherUserId = args['otherUserId']?.toString().trim() ?? '';

      final otherUserName =
          args['otherUserName']?.toString().trim() ?? 'Người dùng';

      if (otherUserId.isNotEmpty) {
        return MaterialPageRoute(
          builder:
              (_) => ChatPage(
                otherUserId: otherUserId,
                otherUserName:
                    otherUserName.isEmpty ? 'Người dùng' : otherUserName,
              ),
          settings: settings,
        );
      }
    }

    return _routeError(
      settings,
      'Thiếu thông tin người nhận để mở cuộc trò chuyện.',
    );
  }

  static Route<dynamic> _buildOrderDetailRoute(RouteSettings settings) {
    final args = settings.arguments;

    debugPrint('Route orderDetail args: $args');

    if (args is String && args.trim().isNotEmpty) {
      return MaterialPageRoute(
        builder: (_) => OrderDetailPage(orderId: args.trim()),
        settings: settings,
      );
    }

    if (args is Map<String, dynamic>) {
      final orderId = args['orderId']?.toString().trim() ?? '';

      if (orderId.isNotEmpty) {
        return MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: orderId),
          settings: settings,
        );
      }
    }

    return _routeError(settings, 'Không nhận được orderId.');
  }

  static Route<dynamic> _buildPaymentTestRoute(RouteSettings settings) {
    final args = settings.arguments;
    String orderId = '';

    if (args is String) {
      orderId = args.trim();
    }

    if (args is Map<String, dynamic>) {
      orderId = args['orderId']?.toString().trim() ?? '';
    }

    if (orderId.isNotEmpty) {
      return MaterialPageRoute(
        builder: (_) => PaymentTestPage(orderId: orderId),
        settings: settings,
      );
    }

    return _routeError(
      settings,
      'Không nhận được orderId cho PaymentTestPage.',
    );
  }

  static MaterialPageRoute<dynamic> _routeError(
    RouteSettings settings,
    String message,
  ) {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Lỗi điều hướng')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '$message\n\n'
                  'Route: ${settings.name}\n'
                  'Arguments: ${settings.arguments}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
      settings: settings,
    );
  }
}

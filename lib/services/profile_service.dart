import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:CT466_project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:CT466_project_trangdc24v7x324/models/address_model.dart';
import 'package:CT466_project_trangdc24v7x324/models/payment_method_model.dart';
import 'package:CT466_project_trangdc24v7x324/models/user_profile_model.dart';

class ProfileService {
  // =========================================================
  // PROFILE
  // =========================================================

  Future<UserProfileModel> fetchProfile() async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    try {
      final userRecord = await pb.collection('users').getOne(authUser.id);

      final userData = userRecord.data;

      final avatarUrl = _buildUserAvatarUrl(
        userId: userRecord.id,
        fileName: userData['avatar']?.toString(),
      );

      final addressRecords = await pb
          .collection('addresses')
          .getFullList(
            filter: 'user = "${userRecord.id}"',
            sort: '-isDefault,-created',
          );

      final addresses = addressRecords.map(AddressModel.fromRecord).toList();

      final paymentRecords = await pb
          .collection('payment_methods')
          .getFullList(
            filter: 'user = "${userRecord.id}"',
            sort: '-isDefault,-created',
          );

      final paymentMethods =
          paymentRecords.map((record) {
            return PaymentMethodModel.fromJson({
              'id': record.id,
              ...record.data,
              'created': record.created,
              'updated': record.updated,
            });
          }).toList();

      return UserProfileModel.fromJson(
        {
          'id': userRecord.id,
          ...userRecord.data,
          'email': userRecord.getStringValue('email'),
          'created': userRecord.created,
          'updated': userRecord.updated,
        },
        avatarUrl: avatarUrl,
        addresses: addresses,
        paymentMethods: paymentMethods,
      );
    } catch (e) {
      // Không clear authStore chỉ vì lỗi mạng/rule/profile.
      // Logout chỉ nên xảy ra khi user chủ động logout
      // hoặc AuthService xác định token thực sự không còn hợp lệ.
      debugPrint('FETCH PROFILE ERROR: $e');

      rethrow;
    }
  }

  // =========================================================
  // GENERAL INFO
  // =========================================================

  Future<void> updateGeneralInfo({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String gender,
    required DateTime? dateOfBirth,
  }) async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    final body = <String, dynamic>{
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'gender': gender.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };

    // Giữ logic email của auth collection riêng.
    // Chỉ gửi email khi thực sự thay đổi.
    final currentEmail = authUser.getStringValue('email').trim();

    final newEmail = email.trim();

    if (newEmail.isNotEmpty && newEmail != currentEmail) {
      body['email'] = newEmail;
    }

    await pb.collection('users').update(authUser.id, body: body);

    await pb.collection('users').authRefresh();
  }

  // =========================================================
  // AVATAR
  // =========================================================

  Future<void> updateAvatar(File file) async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    await pb
        .collection('users')
        .update(
          authUser.id,
          files: [
            http.MultipartFile.fromBytes(
              'avatar',
              await file.readAsBytes(),
              filename: file.path.split('/').last,
            ),
          ],
        );

    await pb.collection('users').authRefresh();
  }

  // =========================================================
  // ADDRESSES
  // =========================================================

  Future<void> updateAddresses(List<AddressModel> addresses) async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    final userId = authUser.id;

    final normalized = _normalizeAddresses(addresses);

    final oldRecords = await pb
        .collection('addresses')
        .getFullList(filter: 'user = "$userId"');

    final oldById = {for (final record in oldRecords) record.id: record};

    final keptIds = <String>{};

    // Tạo/cập nhật trước.
    // Không xóa toàn bộ rồi tạo lại để ID của address
    // được giữ ổn định cho PaymentPage.
    for (final address in normalized) {
      final body = address.toPocketBaseBody(userIdOverride: userId);

      final id = address.id.trim();

      if (id.isNotEmpty && oldById.containsKey(id)) {
        await pb.collection('addresses').update(id, body: body);

        keptIds.add(id);
      } else {
        final created = await pb.collection('addresses').create(body: body);

        keptIds.add(created.id);
      }
    }

    // Chỉ xóa những record user đã thực sự bỏ khỏi Profile.
    for (final record in oldRecords) {
      if (!keptIds.contains(record.id)) {
        await pb.collection('addresses').delete(record.id);
      }
    }
  }

  List<AddressModel> _normalizeAddresses(List<AddressModel> source) {
    if (source.isEmpty) {
      return <AddressModel>[];
    }

    final cleaned =
        source.map((address) {
          return address.copyWith(
            label: address.label.trim().isEmpty ? 'Khác' : address.label.trim(),
            receiverName: address.receiverName.trim(),
            phoneNumber: address.phoneNumber.trim(),
            addressLine: address.addressLine.trim(),
            note: address.note.trim(),
          );
        }).toList();

    final defaultIndexes = <int>[];

    for (int i = 0; i < cleaned.length; i++) {
      if (cleaned[i].isDefault) {
        defaultIndexes.add(i);
      }
    }

    final int defaultIndex = defaultIndexes.isEmpty ? 0 : defaultIndexes.first;

    return cleaned
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(isDefault: entry.key == defaultIndex),
        )
        .toList();
  }

  // =========================================================
  // PAYMENT METHODS
  // =========================================================

  Future<void> updatePaymentMethods(List<PaymentMethodModel> methods) async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    // Payment methods hiện chưa được Order/Payment tham chiếu
    // bằng record id, nên giữ flow đơn giản cho MVP:
    // replace toàn bộ danh sách.
    final oldRecords = await pb
        .collection('payment_methods')
        .getFullList(filter: 'user = "${authUser.id}"');

    for (final record in oldRecords) {
      await pb.collection('payment_methods').delete(record.id);
    }

    if (methods.isEmpty) {
      return;
    }

    final firstDefaultIndex = methods.indexWhere((item) => item.isDefault);

    final resolvedDefault = firstDefaultIndex >= 0 ? firstDefaultIndex : 0;

    for (int i = 0; i < methods.length; i++) {
      final method = methods[i];

      await pb
          .collection('payment_methods')
          .create(
            body: {
              'user': authUser.id,
              'type': method.type.trim(),
              'displayName': method.displayName.trim(),
              'accountNumber': method.accountNumber.trim(),
              'provider': method.provider.trim(),
              'isDefault': i == resolvedDefault,
            },
          );
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _buildUserAvatarUrl({
    required String userId,
    required String? fileName,
  }) {
    if (fileName == null || fileName.trim().isEmpty) {
      return '';
    }

    return '${pb.baseUrl}/api/files/users/'
        '$userId/$fileName'
        '?ts=${DateTime.now().millisecondsSinceEpoch}';
  }
}

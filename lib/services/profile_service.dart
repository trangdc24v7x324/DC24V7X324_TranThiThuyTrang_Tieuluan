// FILE HỌC TẬP: lib/services/profile_service.dart
// Vai trò: Service nghiệp vụ hồ sơ.
// Luồng sử dụng: Thực hiện truy vấn PocketBase hoặc tác vụ hệ thống và trả kết quả cho Provider/UI.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:project_trangdc24v7x324/core/pocketbase_client.dart';
import 'package:project_trangdc24v7x324/models/address_model.dart';
import 'package:project_trangdc24v7x324/models/payment_method_model.dart';
import 'package:project_trangdc24v7x324/models/user_profile_model.dart';

// Lớp ProfileService: tập trung nghiệp vụ và thao tác dữ liệu/backend cho chức năng tương ứng.
class ProfileService {
  // =========================================================
  // PROFILE
  // =========================================================

  // Lấy hồ sơ (fetchProfile): truy xuất từ PocketBase và trả kết quả cho lớp gọi.
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

      // Địa chỉ và phương thức thanh toán độc lập nên tải song song.
      final relatedData = await Future.wait([
        pb.collection('addresses').getFullList(
          filter: 'user = "${userRecord.id}"',
          sort: '-isDefault,-created',
        ),
        pb.collection('payment_methods').getFullList(
          filter: 'user = "${userRecord.id}"',
          sort: '-isDefault,-created',
        ),
      ]);

      final addressRecords = relatedData[0];
      final paymentRecords = relatedData[1];
      final addresses = addressRecords.map(AddressModel.fromRecord).toList();
      final paymentMethods = paymentRecords.map((record) {
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
    } catch (error) {
      debugPrint('FETCH PROFILE ERROR: $error');
      rethrow;
    }
  }

  // Cập nhật thông tin cá nhân (updateGeneralInfo): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
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

  // Cập nhật ảnh đại diện (updateAvatar): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<String> updateAvatar(File file) async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    final updated = await pb
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

    return _buildUserAvatarUrl(
      userId: updated.id,
      fileName: updated.data['avatar']?.toString(),
    );
  }

  // =========================================================
  // ADDRESSES
  // =========================================================

  // Cập nhật địa chỉ (updateAddresses): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<List<AddressModel>> updateAddresses(List<AddressModel> addresses) async {
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

    final freshRecords = await pb.collection('addresses').getFullList(
      filter: 'user = "$userId"',
      sort: '-isDefault,-created',
    );

    return freshRecords.map(AddressModel.fromRecord).toList();
  }

  // Chuẩn hóa địa chỉ (_normalizeAddresses): đưa dữ liệu về định dạng thống nhất trước khi kiểm tra hoặc lưu.
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

  // Cập nhật phương thức thanh toán (updatePaymentMethods): gửi thay đổi tới service/backend và đồng bộ state hiện tại.
  Future<List<PaymentMethodModel>> updatePaymentMethods(List<PaymentMethodModel> methods) async {
    final authUser = pb.authStore.model;

    if (authUser == null) {
      throw Exception('Chưa đăng nhập');
    }

    final oldRecords = await pb
        .collection('payment_methods')
        .getFullList(filter: 'user = "${authUser.id}"');
    final oldById = {for (final record in oldRecords) record.id: record};
    final keptIds = <String>{};

    if (methods.isNotEmpty) {
      final requestedDefault = methods.indexWhere((item) => item.isDefault);
      final defaultIndex = requestedDefault >= 0 ? requestedDefault : 0;

      for (int index = 0; index < methods.length; index++) {
        final method = methods[index];
        final body = <String, dynamic>{
          'user': authUser.id,
          'type': method.type.trim(),
          'displayName': method.displayName.trim(),
          'accountNumber': method.accountNumber.trim(),
          'provider': method.provider.trim(),
          'isDefault': index == defaultIndex,
        };

        final id = method.id.trim();

        if (id.isNotEmpty && oldById.containsKey(id)) {
          await pb.collection('payment_methods').update(id, body: body);
          keptIds.add(id);
        } else {
          final created = await pb.collection('payment_methods').create(body: body);
          keptIds.add(created.id);
        }
      }
    }

    // Chỉ xóa phương thức người dùng đã loại bỏ, không xóa rồi tạo lại toàn bộ.
    for (final record in oldRecords) {
      if (!keptIds.contains(record.id)) {
        await pb.collection('payment_methods').delete(record.id);
      }
    }

    final freshRecords = await pb.collection('payment_methods').getFullList(
      filter: 'user = "${authUser.id}"',
      sort: '-isDefault,-created',
    );

    return freshRecords.map((record) {
      return PaymentMethodModel.fromJson({
        'id': record.id,
        ...record.data,
        'created': record.created,
        'updated': record.updated,
      });
    }).toList();
  }

  // Tạo giao diện người dùng ảnh đại diện url (_buildUserAvatarUrl): dựng widget con từ dữ liệu hiện tại.
  String _buildUserAvatarUrl({
    required String userId,
    required String? fileName,
  }) {
    if (fileName == null || fileName.trim().isEmpty) {
      return '';
    }

    // PocketBase đổi tên file khi avatar thay đổi, nên không cache-bust theo thời gian.
    // Nhờ đó lưu họ tên/số điện thoại không làm ảnh đại diện tải lại.
    return '${pb.baseUrl}/api/files/users/$userId/${fileName.trim()}';
  }
}

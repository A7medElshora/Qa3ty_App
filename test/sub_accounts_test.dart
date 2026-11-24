import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/features/auth/data/models/user_model.dart';
import 'package:qa3ty_app/features/sub_accounts/data/services/sub_accounts_service.dart';

void main() {
  test('permissions and primary-account data are parsed safely', () {
    final user = AppUser.fromJson({
      'id': 'owner-id',
      'username': 'owner',
      'full_name': 'صاحب القاعة',
      'role': 'tenant_admin',
      'is_primary': true,
      'permissions': {
        'can_manage_bookings': false,
        'can_view_reports': true,
        'can_manage_sub_accounts': true,
      },
    });

    expect(user.isPrimary, isTrue);
    expect(user.permissions.canManageBookings, isFalse);
    expect(user.permissions.canViewReports, isTrue);
    expect(user.permissions.canManageSubAccounts, isTrue);
    expect(user.permissions.canManageExpenses, isFalse);
    expect(user.permissions.canManageInventory, isFalse);

    final defaults = UserPermissions.fromJson(const {});
    expect(defaults.canManageBookings, isTrue);
    expect(defaults.canViewReports, isFalse);
    expect(defaults.toJson().containsKey('can_manage_sub_accounts'), isFalse);
  });

  test('sub-account service uses the requested CRUD endpoints and payloads',
      () async {
    AppConfig.current = AppConfig(
      flavor: AppFlavor.development,
      baseUrl: 'https://test.example',
      useMockData: false,
    );
    final adapter = _SubAccountsAdapter();
    final service = SubAccountsService(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );
    const permissions = UserPermissions(
      canManageBookings: true,
      canViewReports: true,
      canManageExpenses: false,
      canManageInventory: true,
      canManageWorkers: false,
    );

    final accounts = await service.getSubAccounts();
    expect(accounts.single.fullName, 'موظف القاعة');
    expect(accounts.single.permissions.canManageInventory, isTrue);

    await service.createSubAccount(
      username: 'staff.one',
      password: 'secure-password',
      fullName: 'موظف جديد',
      phone: null,
      permissions: permissions,
    );
    await service.updateSubAccount(
      id: 'staff-id',
      isActive: false,
      permissions: permissions,
    );
    await service.resetPassword('staff-id', 'new-password');
    await service.deleteSubAccount('staff-id');

    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /sub-accounts',
        'POST /sub-accounts',
        'PATCH /sub-accounts/staff-id',
        'POST /sub-accounts/staff-id/reset-password',
        'DELETE /sub-accounts/staff-id',
      ],
    );
    expect(adapter.requests[1].body, {
      'username': 'staff.one',
      'password': 'secure-password',
      'full_name': 'موظف جديد',
      'phone': null,
      'permissions': permissions.toJson(),
    });
    expect(adapter.requests[2].body, {
      'is_active': false,
      'permissions': permissions.toJson(),
    });
    expect(adapter.requests[3].body, {'new_password': 'new-password'});
  });
}

class _RecordedRequest {
  final String method;
  final String path;
  final Map<String, dynamic>? body;

  const _RecordedRequest(this.method, this.path, this.body);
}

class _SubAccountsAdapter implements HttpClientAdapter {
  final List<_RecordedRequest> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Map<String, dynamic>? body;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    }

    requests.add(
      _RecordedRequest(options.method, options.uri.path, body),
    );
    final account = {
      'id': 'staff-id',
      'username': 'staff.one',
      'full_name': 'موظف القاعة',
      'phone': '01000000000',
      'is_active': true,
      'is_primary': false,
      'permissions': {
        'can_manage_bookings': true,
        'can_view_reports': false,
        'can_manage_expenses': false,
        'can_manage_inventory': true,
        'can_manage_workers': false,
      },
    };

    final responseData = options.method == 'GET'
        ? {
            'items': [account],
          }
        : options.method == 'DELETE' ||
                options.uri.path.endsWith('/reset-password')
            ? <String, dynamic>{}
            : {
                ...account,
                if (body?['is_active'] != null) 'is_active': body!['is_active'],
                if (body?['permissions'] != null)
                  'permissions': body!['permissions'],
              };

    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': responseData}),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

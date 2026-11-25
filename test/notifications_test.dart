import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/features/notifications/data/models/notification_model.dart';

void main() {
  test('deposit reminders map to due notifications with their action route',
      () async {
    final adapter = _NotificationsAdapter('''
      {"success":true,"data":{"items":[{
        "id":"notification-1",
        "title":"تذكير بالعربون",
        "message":"يوجد عربون مستحق",
        "type":"deposit_reminder",
        "created_at":"2026-11-24T10:00:00Z",
        "action_url":"/bookings/1042",
        "is_read":false
      }]}}
    ''');
    final repository = RemoteNotificationsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    final notifications = await repository.getNotifications();

    expect(notifications, hasLength(1));
    expect(notifications.single.type, NotificationType.remainingDue);
    expect(notifications.single.route, '/bookings/1042');
  });

  test('registers the FCM token with the server', () async {
    final adapter = _NotificationsAdapter('{"success":true}');
    final repository = RemoteNotificationsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    await repository.registerDeviceToken(fcmToken: 'test-fcm-token');

    expect(adapter.method, 'POST');
    expect(adapter.path, '/device-tokens');
    expect(jsonDecode(adapter.requestBody!)['token'], 'test-fcm-token');
  });

  test('notifications are ordered newest first', () async {
    final adapter = _NotificationsAdapter('''
      {"success":true,"data":{"items":[
        {"id":"old","created_at":"2026-11-20T10:00:00Z"},
        {"id":"new","created_at":"2026-11-24T10:00:00Z"}
      ]}}
    ''');
    final repository = RemoteNotificationsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    final notifications = await repository.getNotifications();

    expect(notifications.map((item) => item.id), ['new', 'old']);
  });
}

class _NotificationsAdapter implements HttpClientAdapter {
  final String responseJson;
  String? method;
  String? path;
  String? requestBody;

  _NotificationsAdapter(this.responseJson);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.uri.path;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      requestBody = utf8.decode(bytes);
    }
    return ResponseBody.fromString(
      responseJson,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

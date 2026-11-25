import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/inventory/data/models/inventory_model.dart';
import 'package:qa3ty_app/features/inventory/presentation/screens/inventory_screen.dart';

void main() {
  test('opening stock is recorded as a purchase against the server item id',
      () async {
    final adapter = _InventoryAdapter({
      '/inventory':
          '{"success":true,"data":{"id":"server-item-7","name":"مناديل"}}',
      '/inventory/movements': '{"success":true}',
    });
    final repository = RemoteInventoryRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    await repository.addItem(
      const InventoryItem(
        id: '',
        name: 'مناديل',
        category: 'ضيافة',
        quantity: 12,
        unit: 'علبة',
        minAlertQuantity: 3,
        unitCost: 20,
      ),
    );

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests[0].path, '/inventory');
    expect(adapter.requests[0].body['name'], 'مناديل');
    expect(adapter.requests[0].body.containsKey('quantity'), isFalse);
    expect(adapter.requests[1].path, '/inventory/movements');
    expect(adapter.requests[1].body, {
      'inventory_item_id': 'server-item-7',
      'movement_type': 'purchase',
      'quantity': 12,
      'notes': 'رصيد افتتاحي',
    });
  });

  test('opening stock failure exposes the server validation detail', () async {
    final adapter = _InventoryAdapter(
      {
        '/inventory':
            '{"success":true,"data":{"id":"server-item-8","name":"مناديل"}}',
        '/inventory/movements':
            '{"success":false,"error":{"code":"validation_error","message":"Required"}}',
      },
      statusCodes: const {'/inventory/movements': 400},
    );
    final repository = RemoteInventoryRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    await expectLater(
      repository.addItem(
        const InventoryItem(
          id: '',
          name: 'مناديل',
          category: 'ضيافة',
          quantity: 12,
          unit: 'علبة',
          minAlertQuantity: 3,
          unitCost: 20,
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having(
                (error) => error.code, 'code', 'inventory_initial_stock_failed')
            .having((error) => error.message, 'message', contains('Required'))
            .having((error) => error.statusCode, 'statusCode', 400),
      ),
    );
    expect(adapter.requests.map((request) => request.path), [
      '/inventory',
      '/inventory/movements',
    ]);
  });

  test('purchase, occasion consumption, and waste use distinct movement types',
      () async {
    final adapter = _InventoryAdapter({
      '/inventory/movements': '{"success":true}',
    });
    final repository = RemoteInventoryRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    for (final type in MovementType.values) {
      await repository.recordMovement(
        StockMovement(
          id: '',
          itemId: 'item-1',
          itemName: 'أكواب',
          type: type,
          quantity: 1,
          date: DateTime(2026, 11, 24),
          reason: switch (type) {
            MovementType.purchase => null,
            MovementType.consumption => 'حفل زفاف',
            MovementType.waste => 'كسر',
            MovementType.issue => 'صرف للمخزن',
          },
        ),
      );
    }

    expect(
      adapter.requests.map((request) => request.body['movement_type']),
      ['purchase', 'issue', 'consumption', 'waste'],
    );
    expect(adapter.requests.every((request) => request.body['notes'] != null),
        isTrue);
    expect(adapter.requests.first.body['notes'], 'شراء توريد');
    expect(adapter.requests[2].body['notes'], 'حفل زفاف');
    expect(adapter.requests[3].body['notes'], 'كسر');
  });

  test('inventory maps quantity_on_hand from the API', () async {
    final adapter = _InventoryAdapter({
      '/inventory':
          '{"success":true,"data":{"items":[{"id":"item-1","name":"مناديل","quantity_on_hand":17,"unit":"علبة","unit_cost":5}]}}',
    });
    final repository = RemoteInventoryRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    final items = await repository.getItems();

    expect(items.single.quantity, 17);
    expect(items.single.name, 'مناديل');
  });

  test('mock repository rejects invalid quantities and insufficient stock',
      () async {
    final repository = MockInventoryRepository();
    final item = (await repository.getItems()).first;

    await expectLater(
      repository.recordMovement(
        StockMovement(
          id: '',
          itemId: item.id,
          itemName: item.name,
          type: MovementType.purchase,
          quantity: 0,
          date: DateTime.now(),
        ),
      ),
      throwsArgumentError,
    );
    await expectLater(
      repository.recordMovement(
        StockMovement(
          id: '',
          itemId: item.id,
          itemName: item.name,
          type: MovementType.waste,
          quantity: item.quantity + 1,
          date: DateTime.now(),
          reason: 'هالك',
        ),
      ),
      throwsStateError,
    );
    expect((await repository.getItems()).first.quantity, item.quantity);
  });

  testWidgets('occasion movement requires a quantity and occasion name',
      (tester) async {
    final repository = _InventoryScreenRepository();
    final locator = ServicesLocator.locator;
    await locator.reset();
    locator.registerSingleton<InventoryRepository>(repository);
    addTearDown(locator.reset);
    await tester.pumpWidget(
      const MaterialApp(home: InventoryScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('صرف لمناسبة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل كمية صحيحة أكبر من صفر.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '2');
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل المناسبة أو سبب الهالك.'), findsOneWidget);
    expect(repository.recordedMovements, isEmpty);
  });

  testWidgets('new supply rejects negative starting stock', (tester) async {
    final repository = _InventoryScreenRepository();
    final locator = ServicesLocator.locator;
    await locator.reset();
    locator.registerSingleton<InventoryRepository>(repository);
    addTearDown(locator.reset);
    await tester.pumpWidget(
      const MaterialApp(home: InventoryScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'مناديل');
    await tester.enterText(find.byType(TextFormField).at(2), '-1');
    await tester.enterText(find.byType(TextFormField).at(5), '10');
    await tester.tap(find.text('حفظ الصنف'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل الكمية صحيحاً (صفر أو أكثر).'), findsOneWidget);
    expect(repository.items, hasLength(1));
  });

  testWidgets('purchase sheet records a quantity without premature disposal',
      (tester) async {
    final repository = _InventoryScreenRepository();
    final locator = ServicesLocator.locator;
    await locator.reset();
    locator.registerSingleton<InventoryRepository>(repository);
    addTearDown(locator.reset);
    await tester.pumpWidget(
      const MaterialApp(home: InventoryScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('شراء (+)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '3');
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(repository.recordedMovements, hasLength(1));
    expect(repository.recordedMovements.single.type, MovementType.purchase);
    expect(repository.recordedMovements.single.quantity, 3);
    expect(tester.takeException(), isNull);
  });
}

class _RecordedRequest {
  final String path;
  final Map<String, dynamic> body;

  const _RecordedRequest(this.path, this.body);
}

class _InventoryAdapter implements HttpClientAdapter {
  final Map<String, String> responses;
  final Map<String, int> statusCodes;
  final List<_RecordedRequest> requests = [];

  _InventoryAdapter(this.responses, {this.statusCodes = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.fold<List<int>>(
            <int>[],
            (buffer, chunk) => buffer..addAll(chunk),
          );
    final body = bytes.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (options.method == 'POST') {
      requests.add(_RecordedRequest(options.uri.path, body));
    }
    return ResponseBody.fromString(
      responses[options.uri.path] ?? '{"success":true}',
      statusCodes[options.uri.path] ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _InventoryScreenRepository implements InventoryRepository {
  final List<InventoryItem> items = [
    const InventoryItem(
      id: 'item-1',
      name: 'أكواب',
      category: 'ضيافة',
      quantity: 10,
      unit: 'قطعة',
      minAlertQuantity: 2,
      unitCost: 1,
    ),
  ];
  final List<StockMovement> recordedMovements = [];

  @override
  Future<List<InventoryItem>> getItems() async => List.of(items);

  @override
  Future<List<StockMovement>> getMovements() async =>
      List.of(recordedMovements);

  @override
  Future<InventoryItem> addItem(InventoryItem item) async {
    items.add(item);
    return item;
  }

  @override
  Future<void> updateItem(InventoryItem item) async {}

  @override
  Future<void> recordMovement(StockMovement movement) async {
    recordedMovements.add(movement);
  }
}

import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/networking/dio_factory.dart';

enum MovementType {
  purchase, // مشتريات (+ أخضر)
  issue, // صرف
  consumption, // استهلاك
  waste, // هالك/تالف (أحمر)
}

class StockMovement {
  final String id;
  final String itemId;
  final String itemName;
  final MovementType type;
  final int quantity;
  final DateTime date;
  final String? reason;

  const StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.date,
    this.reason,
  });
}

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit; // كرتونة, زجاجة, متر, قطعة
  final int minAlertQuantity;
  final int unitCost;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.minAlertQuantity,
    required this.unitCost,
  });

  bool get isLowStock => quantity <= minAlertQuantity;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    int? minAlertQuantity,
    int? unitCost,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minAlertQuantity: minAlertQuantity ?? this.minAlertQuantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}

abstract class InventoryRepository {
  Future<List<InventoryItem>> getItems();
  Future<List<StockMovement>> getMovements();
  Future<InventoryItem> addItem(InventoryItem item);
  Future<void> updateItem(InventoryItem item);
  Future<void> recordMovement(StockMovement movement);
}

class RemoteInventoryRepository implements InventoryRepository {
  final Dio _dio;

  RemoteInventoryRepository([Dio? dio]) : _dio = dio ?? DioFactory.getDio();

  List<dynamic> _collectionFromResponse(dynamic data) {
    final payload = data is Map ? data['data'] : null;
    final items = payload is Map ? payload['items'] : payload;
    if (items is List) return items;
    if (data is List) return data;
    return const [];
  }

  @override
  Future<List<InventoryItem>> getItems() async {
    try {
      final response = await _dio.get('/inventory');
      final rawItems = _collectionFromResponse(response.data);

      return rawItems.map<InventoryItem>((item) {
        return InventoryItem(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          category: item['category']?.toString() ?? 'عام',
          quantity: ((item['quantity_on_hand'] ??
                  item['current_stock'] ??
                  item['quantity'] ??
                  0) as num)
              .toInt(),
          unit: item['unit']?.toString() ?? 'قطعة',
          minAlertQuantity:
              ((item['min_stock'] ?? item['min_alert_quantity'] ?? 5) as num)
                  .toInt(),
          unitCost: ((item['unit_cost'] ?? 0) as num).round(),
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<StockMovement>> getMovements() async {
    try {
      final response = await _dio.get('/inventory/movements');
      final rawItems = _collectionFromResponse(response.data);

      final movements = rawItems.map<StockMovement>((item) {
        MovementType mType = MovementType.consumption;
        final tStr = (item['movement_type']?.toString() ?? '').toLowerCase();
        if (tStr == 'purchase') {
          mType = MovementType.purchase;
        } else if (tStr == 'issue') {
          mType = MovementType.issue;
        } else if (tStr == 'consumption') {
          mType = MovementType.consumption;
        } else if (tStr == 'waste') {
          mType = MovementType.waste;
        }

        DateTime d = DateTime.now();
        final rawDate =
            item['created_at'] ?? item['movement_date'] ?? item['date'];
        if (rawDate != null) {
          d = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
        }

        return StockMovement(
          id: item['id']?.toString() ?? '',
          itemId: item['inventory_item_id']?.toString() ?? '',
          itemName: (item['inventory_items'] is Map
                      ? item['inventory_items']['name']
                      : null)
                  ?.toString() ??
              item['item_name']?.toString() ??
              '',
          type: mType,
          quantity: ((item['quantity'] ?? 0) as num).toInt(),
          date: d,
          reason: item['notes']?.toString() ?? item['reason']?.toString(),
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return movements;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<InventoryItem> addItem(InventoryItem item) async {
    try {
      final response = await _dio.post(
        '/inventory',
        data: {
          'name': item.name,
          'unit': item.unit,
          'unit_cost': item.unitCost.toDouble(),
          'min_stock': item.minAlertQuantity,
          'category': item.category,
        },
      );
      final data = response.data;
      final itemData = data is Map && data['data'] is Map ? data['data'] : data;
      final createdId = itemData is Map
          ? (itemData['id'] ?? itemData['inventory_item_id'])?.toString()
          : null;
      final createdItem = item.copyWith(id: createdId ?? item.id);

      if (item.quantity > 0) {
        if (createdId == null || createdId.isEmpty) {
          throw const ApiException(
            code: 'inventory_item_created_without_id',
            message:
                'تم إنشاء الصنف، لكن لم يُرجع الخادم معرفه؛ تعذر تسجيل الرصيد الافتتاحي.',
          );
        }
        try {
          await recordMovement(
            StockMovement(
              id: '',
              itemId: createdId,
              itemName: item.name,
              type: MovementType.purchase,
              quantity: item.quantity,
              date: DateTime.now(),
              reason: 'رصيد افتتاحي',
            ),
          );
        } catch (error) {
          final reason =
              error is ApiException ? error.message : error.toString();
          throw ApiException(
            code: 'inventory_initial_stock_failed',
            message: 'تم إنشاء الصنف، لكن تعذر تسجيل رصيده الافتتاحي '
                '($reason). لا تُعِد إنشاءه؛ سجّل الكمية من زر "شراء (+)" '
                'في بطاقة الصنف.',
            statusCode: error is ApiException ? error.statusCode : null,
          );
        }
      }

      return createdItem;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    try {
      await _dio.put(
        '/inventory/${item.id}',
        data: {
          'name': item.name,
          'unit': item.unit,
          'unit_cost': item.unitCost.toDouble(),
          'min_stock': item.minAlertQuantity,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    if (movement.quantity <= 0) {
      throw ArgumentError.value(
        movement.quantity,
        'quantity',
        'يجب أن تكون الكمية أكبر من صفر.',
      );
    }
    final notes = movement.reason?.trim();
    if (movement.type != MovementType.purchase &&
        (notes == null || notes.isEmpty)) {
      throw ArgumentError.value(
        movement.reason,
        'reason',
        'يجب إدخال سبب حركة المخزون.',
      );
    }
    try {
      await _dio.post(
        '/inventory/movements',
        data: {
          'inventory_item_id': movement.itemId,
          'movement_type': movement.type.name,
          'quantity': movement.quantity,
          'notes': notes?.isNotEmpty == true ? notes : 'شراء توريد',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class MockInventoryRepository implements InventoryRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  final List<InventoryItem> _items = [
    const InventoryItem(
      id: 'inv_1',
      name: 'سائل دخان ثقيل',
      category: 'مؤثرات',
      quantity: 4,
      unit: 'جركن ٥ لتر',
      minAlertQuantity: 5,
      unitCost: 850,
    ),
    const InventoryItem(
      id: 'inv_2',
      name: 'مناديل سفرة فاخرة',
      category: 'ضيافة',
      quantity: 45,
      unit: 'علبة',
      minAlertQuantity: 15,
      unitCost: 65,
    ),
    const InventoryItem(
      id: 'inv_3',
      name: 'مدافع ورد وأوراق ملونة',
      category: 'مؤثرات',
      quantity: 8,
      unit: 'حبة',
      minAlertQuantity: 10,
      unitCost: 120,
    ),
    const InventoryItem(
      id: 'inv_4',
      name: 'أكواب كريستال عصير',
      category: 'بوفيه',
      quantity: 250,
      unit: 'قطعة',
      minAlertQuantity: 50,
      unitCost: 35,
    ),
  ];

  final List<StockMovement> _movements = [
    StockMovement(
      id: 'mov_1',
      itemId: 'inv_1',
      itemName: 'سائل دخان ثقيل',
      type: MovementType.consumption,
      quantity: 2,
      date: DateTime.now().subtract(const Duration(days: 1)),
      reason: 'حفل زفاف قاعة الماسة',
    ),
    StockMovement(
      id: 'mov_2',
      itemId: 'inv_2',
      itemName: 'مناديل سفرة فاخرة',
      type: MovementType.purchase,
      quantity: 50,
      date: DateTime.now().subtract(const Duration(days: 3)),
      reason: 'شراء دفعة جديدة من المورد',
    ),
    StockMovement(
      id: 'mov_3',
      itemId: 'inv_4',
      itemName: 'أكواب كريستال عصير',
      type: MovementType.waste,
      quantity: 6,
      date: DateTime.now().subtract(const Duration(days: 4)),
      reason: 'كسر أثناء نقل البوفيه',
    ),
  ];

  @override
  Future<List<InventoryItem>> getItems() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_items);
  }

  @override
  Future<List<StockMovement>> getMovements() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_movements);
  }

  @override
  Future<InventoryItem> addItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final storedItem = item.copyWith(
      id: item.id.isEmpty
          ? 'inv_${DateTime.now().millisecondsSinceEpoch}'
          : item.id,
    );
    _items.add(storedItem);
    if (storedItem.quantity > 0) {
      _movements.insert(
        0,
        StockMovement(
          id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
          itemId: storedItem.id,
          itemName: storedItem.name,
          type: MovementType.purchase,
          quantity: storedItem.quantity,
          date: DateTime.now(),
          reason: 'رصيد افتتاحي',
        ),
      );
    }
    return storedItem;
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) _items[idx] = item;
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (movement.quantity <= 0) {
      throw ArgumentError.value(movement.quantity, 'quantity');
    }
    final idx = _items.indexWhere((i) => i.id == movement.itemId);
    if (idx == -1) {
      throw StateError('Inventory item not found: ${movement.itemId}');
    }
    final item = _items[idx];
    final isPurchase = movement.type == MovementType.purchase;
    if (!isPurchase && movement.quantity > item.quantity) {
      throw StateError('Insufficient stock for ${item.name}');
    }
    _movements.insert(0, movement);
    _items[idx] = item.copyWith(
      quantity: isPurchase
          ? item.quantity + movement.quantity
          : item.quantity - movement.quantity,
    );
  }
}

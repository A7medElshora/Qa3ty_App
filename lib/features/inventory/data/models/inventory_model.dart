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
  Future<void> addItem(InventoryItem item);
  Future<void> updateItem(InventoryItem item);
  Future<void> recordMovement(StockMovement movement);
}

class RemoteInventoryRepository implements InventoryRepository {
  final Dio _dio = DioFactory.getDio();

  @override
  Future<List<InventoryItem>> getItems() async {
    try {
      final response = await _dio.get('/inventory');
      final data = response.data;
      final List rawItems = (data is Map && data['data'] != null)
          ? (data['data'] is Map ? (data['data']['items'] ?? []) : data['data'])
          : (data is List ? data : []);

      return rawItems.map<InventoryItem>((item) {
        return InventoryItem(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          category: item['category']?.toString() ?? 'عام',
          quantity: ((item['current_stock'] ?? item['quantity'] ?? 0) as num).toInt(),
          unit: item['unit']?.toString() ?? 'قطعة',
          minAlertQuantity: ((item['min_stock'] ?? item['min_alert_quantity'] ?? 5) as num).toInt(),
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
      final data = response.data;
      final List rawItems = (data is Map && data['data'] != null)
          ? (data['data'] is Map ? (data['data']['items'] ?? []) : data['data'])
          : (data is List ? data : []);

      return rawItems.map<StockMovement>((item) {
        MovementType mType = MovementType.consumption;
        final tStr = (item['movement_type']?.toString() ?? '').toLowerCase();
        if (tStr == 'purchase') {
          mType = MovementType.purchase;
        } else if (tStr == 'issue') {
          mType = MovementType.issue;
        } else if (tStr == 'waste') {
          mType = MovementType.waste;
        }

        DateTime d = DateTime.now();
        final rawDate = item['created_at'] ?? item['movement_date'] ?? item['date'];
        if (rawDate != null) {
          d = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
        }

        return StockMovement(
          id: item['id']?.toString() ?? '',
          itemId: item['inventory_item_id']?.toString() ?? '',
          itemName: item['inventory_items']?['name']?.toString() ?? item['item_name']?.toString() ?? '',
          type: mType,
          quantity: ((item['quantity'] ?? 0) as num).toInt(),
          date: d,
          reason: item['notes']?.toString() ?? item['reason']?.toString(),
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> addItem(InventoryItem item) async {
    try {
      await _dio.post(
        '/inventory',
        data: {
          'name': item.name,
          'unit': item.unit,
          'unit_cost': item.unitCost.toDouble(),
          'min_stock': item.minAlertQuantity,
          'category': item.category,
        },
      );
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
    } on DioException catch (_) {
      // Backend does not expose PUT /inventory/:id yet per Section 8.12
    }
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    try {
      await _dio.post(
        '/inventory/movements',
        data: {
          'inventory_item_id': movement.itemId,
          'movement_type': movement.type.name,
          'quantity': movement.quantity,
          if (movement.reason != null && movement.reason!.isNotEmpty) 'notes': movement.reason,
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
  Future<void> addItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _items.add(item);
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
    _movements.insert(0, movement);
    final idx = _items.indexWhere((i) => i.id == movement.itemId);
    if (idx != -1) {
      final item = _items[idx];
      int newQty = item.quantity;
      if (movement.type == MovementType.purchase) {
        newQty += movement.quantity;
      } else {
        newQty -= movement.quantity;
        if (newQty < 0) newQty = 0;
      }
      _items[idx] = item.copyWith(quantity: newQty);
    }
  }
}

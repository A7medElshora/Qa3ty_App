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

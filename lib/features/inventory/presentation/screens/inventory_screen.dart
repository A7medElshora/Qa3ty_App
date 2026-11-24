import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_bottom_sheet.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../../data/models/inventory_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<InventoryItem> _items = [];
  List<StockMovement> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final items = await ServicesLocator.inventoryRepo.getItems();
    final movements = await ServicesLocator.inventoryRepo.getMovements();
    setState(() {
      _items = items;
      _movements = movements;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'إدارة المخزون والمستلزمات',
                subtitle: 'متابعة الأرصدة وتنبيهات النواقص وسجل الحركات',
                actions: [
                  CircleIconButton.primary(
                    icon: const Icon(LucideIcons.plus,
                        size: 20, color: AppColors.white),
                    onTap: _showAddItemBottomSheet,
                  ),
                ],
              ),
            ),

            // Tabs: الأصناف والمخزون / سجل الحركات
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.muted,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'أصناف المخزون'),
                  Tab(text: 'سجل حركات الأصناف'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const AppListSkeleton(itemCount: 4)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildItemsTab(),
                        _buildMovementsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTab() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 2),
                          Text(
                              '${item.category} · تكلفة الوحدة: ${AppFormatters.formatMoney(item.unitCost)}',
                              style: AppTextStyles.muted),
                        ],
                      ),
                    ),
                    if (item.isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.redBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.alertTriangle,
                                size: 12, color: AppColors.red),
                            SizedBox(width: 4),
                            Text('رصيد منخفض',
                                style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الرصيد: ${item.quantity.toArabicDigits()} ${item.unit}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'الحد الأدنى: ${item.minAlertQuantity.toArabicDigits()} ${item.unit}',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'شراء (+)',
                        height: 36,
                        textColor: AppColors.green,
                        borderColor: AppColors.green,
                        onPressed: () =>
                            _showMovementDialog(item, MovementType.purchase),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'صرف لمناسبة',
                        height: 36,
                        onPressed: () =>
                            _showMovementDialog(item, MovementType.consumption),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'تسجيل هالك',
                        height: 36,
                        textColor: AppColors.red,
                        borderColor: AppColors.red,
                        onPressed: () =>
                            _showMovementDialog(item, MovementType.waste),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovementsTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
      itemCount: _movements.length,
      itemBuilder: (context, i) {
        final mov = _movements[i];
        final isPurchase = mov.type == MovementType.purchase;
        final isWaste = mov.type == MovementType.waste;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.cardShadow,
          ),
          child: ListTile(
            title: Text(mov.itemName, style: AppTextStyles.cardTitle),
            subtitle: Text(
                '${mov.reason ?? ""} · ${AppFormatters.formatDayMonth(mov.date)}',
                style: AppTextStyles.muted),
            trailing: Text(
              '${isPurchase ? "+" : "-"}${mov.quantity.toArabicDigits()}',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isPurchase
                    ? AppColors.green
                    : (isWaste ? AppColors.red : AppColors.ink),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddItemBottomSheet() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'مؤثرات');
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'قطعة');
    final minCtrl = TextEditingController(text: '5');
    final costCtrl = TextEditingController();

    AppBottomSheet.show(
      context: context,
      title: 'إضافة صنف مخزون جديد',
      child: Column(
        children: [
          AppTextField(label: 'اسم الصنف', controller: nameCtrl),
          const SizedBox(height: 10),
          AppTextField(label: 'التصنيف', controller: catCtrl),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: AppTextField(
                      label: 'الكمية الابتدائية',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: AppTextField(
                      label: 'الوحدة (علبة/كرتونة)', controller: unitCtrl)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: AppTextField(
                      label: 'حد التنبيه الأدنى',
                      controller: minCtrl,
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: AppTextField(
                      label: 'تكلفة الوحدة (ج.م)',
                      controller: costCtrl,
                      keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            text: 'حفظ الصنف',
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                final newItem = InventoryItem(
                  id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  category: catCtrl.text.trim(),
                  quantity: int.tryParse(qtyCtrl.text.trim()) ?? 0,
                  unit: unitCtrl.text.trim(),
                  minAlertQuantity: int.tryParse(minCtrl.text.trim()) ?? 5,
                  unitCost: int.tryParse(costCtrl.text.trim()) ?? 0,
                );
                await ServicesLocator.inventoryRepo.addItem(newItem);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchData();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMovementDialog(InventoryItem item, MovementType type) {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    String typeLabel = type == MovementType.purchase
        ? 'شراء توريد'
        : (type == MovementType.waste ? 'تسجيل هالك' : 'صرف لمناسبة');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(typeLabel, style: AppTextStyles.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الصنف: ${item.name}', style: AppTextStyles.body),
            const SizedBox(height: 10),
            AppTextField(
              label: 'الكمية (${item.unit})',
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            AppTextField(
              label: 'السبب / المناسبة / الملاحظة',
              controller: reasonCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (qty > 0) {
                final movement = StockMovement(
                  id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
                  itemId: item.id,
                  itemName: item.name,
                  type: type,
                  quantity: qty,
                  date: DateTime.now(),
                  reason: reasonCtrl.text.trim(),
                );
                await ServicesLocator.inventoryRepo.recordMovement(movement);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                _fetchData();
              }
            },
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

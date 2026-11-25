import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
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
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final items = await ServicesLocator.inventoryRepo.getItems();
      final movements = await ServicesLocator.inventoryRepo.getMovements();
      if (!mounted) return;
      setState(() {
        _items = items;
        _movements = movements;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _friendlyError(error, 'تعذر تحميل بيانات المخزون.');
        _isLoading = false;
      });
    }
  }

  String _friendlyError(Object error, String fallback) =>
      error is ApiException ? error.message : fallback;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.red : AppColors.green,
        ),
      );
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
                  : _loadError != null
                      ? ErrorState(
                          message: _loadError!,
                          onRetry: _fetchData,
                        )
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
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 320,
                  child: EmptyState(
                    title: 'لا توجد أصناف مخزون',
                    subtitle: 'أضف المستلزمات لتسجيل أرصدتها وحركاتها.',
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 80, top: 8),
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
                              onPressed: () => _showMovementDialog(
                                  item, MovementType.purchase),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppSecondaryButton(
                              text: 'صرف لمناسبة',
                              height: 36,
                              onPressed: () => _showMovementDialog(
                                  item, MovementType.consumption),
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
    if (_movements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: EmptyState(
              title: 'لا توجد حركات مسجلة',
              subtitle: 'ستظهر هنا عمليات الشراء والصرف والهالك.',
            ),
          ),
        ],
      );
    }

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

  Future<void> _showAddItemBottomSheet() async {
    final result = await AppBottomSheet.show<_InventorySheetResult>(
      context: context,
      title: 'إضافة صنف مخزون جديد',
      child: _InventoryItemFormSheet(
        onSave: ServicesLocator.inventoryRepo.addItem,
      ),
    );
    if (!mounted || result == null) return;
    if (result.itemCreated) await _fetchData();
    _showMessage(result.message, isError: result.isError);
  }

  Future<void> _showMovementDialog(
      InventoryItem item, MovementType type) async {
    final saved = await AppBottomSheet.show<bool>(
      context: context,
      title: _movementTitle(type),
      child: _InventoryMovementFormSheet(
        item: item,
        type: type,
        onSave: ServicesLocator.inventoryRepo.recordMovement,
      ),
    );
    if (saved == true && mounted) {
      await _fetchData();
      _showMessage('تم تسجيل الحركة بنجاح.');
    }
  }

  String _movementTitle(MovementType type) => switch (type) {
        MovementType.purchase => 'شراء توريد',
        MovementType.waste => 'تسجيل هالك',
        MovementType.consumption => 'صرف لمناسبة',
        MovementType.issue => 'صرف صنف',
      };
}

class _InventorySheetResult {
  final bool itemCreated;
  final bool isError;
  final String message;

  const _InventorySheetResult({
    required this.itemCreated,
    required this.isError,
    required this.message,
  });
}

class _InventoryItemFormSheet extends StatefulWidget {
  final Future<InventoryItem> Function(InventoryItem item) onSave;

  const _InventoryItemFormSheet({required this.onSave});

  @override
  State<_InventoryItemFormSheet> createState() =>
      _InventoryItemFormSheetState();
}

class _InventoryItemFormSheetState extends State<_InventoryItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'مؤثرات');
  final _quantityController = TextEditingController(text: '0');
  final _unitController = TextEditingController(text: 'قطعة');
  final _minimumController = TextEditingController(text: '5');
  final _costController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _minimumController.dispose();
    _costController.dispose();
    super.dispose();
  }

  String? _validateNonNegative(String? value, String label) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0
        ? 'أدخل $label صحيحاً (صفر أو أكثر).'
        : null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final item = InventoryItem(
      id: '',
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      unit: _unitController.text.trim(),
      minAlertQuantity: int.parse(_minimumController.text.trim()),
      unitCost: int.parse(_costController.text.trim()),
    );
    try {
      await widget.onSave(item);
      if (mounted) {
        Navigator.of(context).pop(
          const _InventorySheetResult(
            itemCreated: true,
            isError: false,
            message: 'تم حفظ الصنف ورصيده بنجاح.',
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException &&
          (error.code == 'inventory_item_created_without_id' ||
              error.code == 'inventory_initial_stock_failed')) {
        Navigator.of(context).pop(
          _InventorySheetResult(
            itemCreated: true,
            isError: true,
            message: error.message,
          ),
        );
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = error is ApiException
            ? error.message
            : 'تعذر حفظ الصنف. تحقق من الاتصال وحاول مجدداً.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'اسم الصنف',
            controller: _nameController,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل اسم الصنف.'
                : null,
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: 'التصنيف',
            controller: _categoryController,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل تصنيف الصنف.'
                : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'الكمية الابتدائية',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  validator: (value) => _validateNonNegative(value, 'الكمية'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'الوحدة (علبة/كرتونة)',
                  controller: _unitController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل وحدة الصنف.'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'حد التنبيه الأدنى',
                  controller: _minimumController,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      _validateNonNegative(value, 'حد التنبيه'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'تكلفة الوحدة (ج.م)',
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      _validateNonNegative(value, 'تكلفة الوحدة'),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 16),
          AppPrimaryButton(
            text: 'حفظ الصنف',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _InventoryMovementFormSheet extends StatefulWidget {
  final InventoryItem item;
  final MovementType type;
  final Future<void> Function(StockMovement movement) onSave;

  const _InventoryMovementFormSheet({
    required this.item,
    required this.type,
    required this.onSave,
  });

  @override
  State<_InventoryMovementFormSheet> createState() =>
      _InventoryMovementFormSheetState();
}

class _InventoryMovementFormSheetState
    extends State<_InventoryMovementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isPurchase => widget.type == MovementType.purchase;
  String get _reasonLabel => switch (widget.type) {
        MovementType.consumption => 'اسم المناسبة / الحجز',
        MovementType.waste => 'سبب الهالك',
        MovementType.purchase => 'ملاحظة الشراء (اختياري)',
        MovementType.issue => 'سبب الصرف',
      };

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final movement = StockMovement(
      id: '',
      itemId: widget.item.id,
      itemName: widget.item.name,
      type: widget.type,
      quantity: int.parse(_quantityController.text.trim()),
      date: DateTime.now(),
      reason: _reasonController.text.trim().isEmpty && _isPurchase
          ? 'شراء توريد'
          : _reasonController.text.trim(),
    );
    try {
      await widget.onSave(movement);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error is ApiException
            ? error.message
            : 'تعذر تسجيل الحركة. تحقق من الاتصال وحاول مجدداً.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('الصنف: ${widget.item.name}', style: AppTextStyles.body),
          const SizedBox(height: 10),
          AppTextField(
            label: 'الكمية (${widget.item.unit})',
            controller: _quantityController,
            keyboardType: TextInputType.number,
            validator: (value) {
              final quantity = int.tryParse(value?.trim() ?? '');
              if (quantity == null || quantity <= 0) {
                return 'أدخل كمية صحيحة أكبر من صفر.';
              }
              if (!_isPurchase && quantity > widget.item.quantity) {
                return 'الكمية أكبر من الرصيد المتاح (${widget.item.quantity}).';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: _reasonLabel,
            controller: _reasonController,
            validator: !_isPurchase
                ? (value) => value == null || value.trim().isEmpty
                    ? 'أدخل المناسبة أو سبب الهالك.'
                    : null
                : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  text: 'إلغاء',
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppPrimaryButton(
                  text: 'تأكيد',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

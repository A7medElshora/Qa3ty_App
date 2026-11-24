import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import 'package:qa3ty_app/features/auth/data/models/user_model.dart';
import 'package:qa3ty_app/features/sub_accounts/data/models/sub_account_model.dart';

class SubAccountsListScreen extends StatefulWidget {
  const SubAccountsListScreen({super.key});

  @override
  State<SubAccountsListScreen> createState() => _SubAccountsListScreenState();
}

class _SubAccountsListScreenState extends State<SubAccountsListScreen> {
  List<SubAccountModel> _accounts = [];
  final Set<String> _busyAccounts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (PermissionGuard.canManageSubAccounts) {
      _loadAccounts();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final accounts =
          await ServicesLocator.subAccountsService.getSubAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = PermissionGuard.canManageSubAccounts;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isPrimary
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : () => _editAccount(),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('إضافة حساب موظف جديد'),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 52,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: AppHeader(
                title: 'الحسابات والصلاحيات',
                subtitle: 'إدارة وصول الموظفين إلى أقسام التطبيق',
                showBackButton: true,
                onBackTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: !isPrimary
                  ? const Center(
                      child: Text(
                        'هذه الصفحة متاحة لصاحب المنشأة فقط.',
                        style: AppTextStyles.body,
                      ),
                    )
                  : _isLoading
                      ? const AppListSkeleton(itemCount: 4)
                      : _error != null
                          ? ErrorState(
                              message: _error!,
                              onRetry: _loadAccounts,
                            )
                          : _accounts.isEmpty
                              ? const EmptyState(
                                  title: 'لا توجد حسابات موظفين',
                                  subtitle:
                                      'أضف حساباً لموظف وحدد الأقسام التي يمكنه الوصول إليها.',
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadAccounts,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      100,
                                    ),
                                    itemCount: _accounts.length,
                                    itemBuilder: (context, index) =>
                                        _buildAccountCard(_accounts[index]),
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(SubAccountModel account) {
    final isBusy = _busyAccounts.contains(account.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.fullName, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text('@${account.username}', style: AppTextStyles.muted),
                    if (account.phone?.isNotEmpty == true)
                      Text(account.phone!, style: AppTextStyles.muted),
                  ],
                ),
              ),
              if (!account.isPrimary)
                PopupMenuButton<String>(
                  enabled: !isBusy,
                  onSelected: (action) => _onAccountAction(account, action),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('تعديل الصلاحيات والبيانات'),
                    ),
                    PopupMenuItem(
                      value: 'password',
                      child: Text('إعادة تعيين كلمة المرور'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف الحساب'),
                    ),
                  ],
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  account.isActive ? 'الحساب نشط' : 'الحساب متوقف',
                  style: AppTextStyles.body.copyWith(
                    color: account.isActive ? AppColors.green : AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch.adaptive(
                value: account.isActive,
                onChanged: account.isPrimary || isBusy
                    ? null
                    : (value) => _setActive(account, value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _permissionChip(
                  'الحجوزات', account.permissions.canManageBookings),
              _permissionChip('التقارير', account.permissions.canViewReports),
              _permissionChip(
                'المصروفات',
                account.permissions.canManageExpenses,
              ),
              _permissionChip(
                'المخزون',
                account.permissions.canManageInventory,
              ),
              _permissionChip('العمال', account.permissions.canManageWorkers),
            ],
          ),
        ],
      ),
    );
  }

  Widget _permissionChip(String label, bool enabled) {
    final color = enabled ? AppColors.green : AppColors.muted;
    return Chip(
      avatar: Icon(
        enabled ? Icons.check_circle : Icons.remove_circle_outline,
        size: 16,
        color: color,
      ),
      label: Text(label),
      backgroundColor: color.withValues(alpha: enabled ? 0.12 : 0.08),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: color,
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _editAccount({SubAccountModel? account}) async {
    final form = await showDialog<SubAccountFormData>(
      context: context,
      builder: (_) => AddEditSubAccountDialog(account: account),
    );
    if (form == null || !mounted) return;

    final username = form.username.toLowerCase();
    final duplicateUsername = _accounts.any(
      (existing) =>
          existing.id != account?.id &&
          existing.username.trim().toLowerCase() == username,
    );
    if (duplicateUsername) {
      _showMessage('اسم المستخدم مستخدم بالفعل، اختر اسماً آخر.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (account == null) {
        await ServicesLocator.subAccountsService.createSubAccount(
          username: form.username,
          password: form.password!,
          fullName: form.fullName,
          phone: form.phone,
          permissions: form.permissions,
        );
      } else {
        await ServicesLocator.subAccountsService.updateSubAccount(
          id: account.id,
          fullName: form.fullName,
          phone: form.phone,
          permissions: form.permissions,
        );
      }
      await _loadAccounts();
      _showMessage(
        account == null ? 'تم إنشاء الحساب بنجاح.' : 'تم تحديث الحساب بنجاح.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('تعذر حفظ الحساب: ${_errorMessage(error)}');
    }
  }

  Future<void> _setActive(SubAccountModel account, bool isActive) async {
    setState(() => _busyAccounts.add(account.id));
    try {
      await ServicesLocator.subAccountsService.updateSubAccount(
        id: account.id,
        isActive: isActive,
      );
      await _loadAccounts();
      _showMessage(isActive ? 'تم تفعيل الحساب.' : 'تم إيقاف الحساب.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('تعذر تحديث حالة الحساب: ${_errorMessage(error)}');
    } finally {
      if (mounted) setState(() => _busyAccounts.remove(account.id));
    }
  }

  Future<void> _onAccountAction(
    SubAccountModel account,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        await _editAccount(account: account);
        return;
      case 'password':
        await _resetPassword(account);
        return;
      case 'delete':
        await _deleteAccount(account);
        return;
    }
  }

  Future<void> _resetPassword(SubAccountModel account) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _ResetSubAccountPasswordDialog(),
    );
    if (password == null || !mounted) return;

    setState(() => _busyAccounts.add(account.id));
    try {
      await ServicesLocator.subAccountsService.resetPassword(
        account.id,
        password,
      );
      _showMessage('تمت إعادة تعيين كلمة المرور.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('تعذر إعادة تعيين كلمة المرور: ${_errorMessage(error)}');
    } finally {
      if (mounted) setState(() => _busyAccounts.remove(account.id));
    }
  }

  Future<void> _deleteAccount(SubAccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Text('هل تريد حذف حساب ${account.fullName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyAccounts.add(account.id));
    try {
      await ServicesLocator.subAccountsService.deleteSubAccount(account.id);
      await _loadAccounts();
      _showMessage('تم حذف الحساب.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('تعذر حذف الحساب: ${_errorMessage(error)}');
    } finally {
      if (mounted) setState(() => _busyAccounts.remove(account.id));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) =>
      error is ApiException ? error.message : error.toString();
}

class AddEditSubAccountDialog extends StatefulWidget {
  final SubAccountModel? account;

  const AddEditSubAccountDialog({super.key, this.account});

  @override
  State<AddEditSubAccountDialog> createState() =>
      _AddEditSubAccountDialogState();
}

class _AddEditSubAccountDialogState extends State<AddEditSubAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late bool _canManageBookings;
  late bool _canViewReports;
  late bool _canManageExpenses;
  late bool _canManageInventory;
  late bool _canManageWorkers;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.fullName ?? '');
    _usernameController = TextEditingController(text: account?.username ?? '');
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: account?.phone ?? '');
    _canManageBookings = account?.permissions.canManageBookings ?? true;
    _canViewReports = account?.permissions.canViewReports ?? false;
    _canManageExpenses = account?.permissions.canManageExpenses ?? false;
    _canManageInventory = account?.permissions.canManageInventory ?? false;
    _canManageWorkers = account?.permissions.canManageWorkers ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEditing ? 'تعديل حساب الموظف' : 'إضافة حساب موظف'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل الاسم الكامل.'
                      : null,
                ),
                TextFormField(
                  controller: _usernameController,
                  readOnly: _isEditing,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    helperText: 'حروف إنجليزية ونقاط فقط',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'أدخل اسم المستخدم.';
                    }
                    if (!RegExp(r'^[A-Za-z.]+$').hasMatch(value)) {
                      return 'استخدم الحروف الإنجليزية والنقاط فقط.';
                    }
                    return null;
                  },
                ),
                if (!_isEditing)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'أدخل كلمة المرور.'
                        : null,
                  ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'الصلاحيات الممنوحة',
                    style: AppTextStyles.cardTitle,
                  ),
                ),
                _permissionSwitch(
                  'إدارة الحجوزات',
                  _canManageBookings,
                  (value) => _canManageBookings = value,
                ),
                _permissionSwitch(
                  'التقارير المالية والأرباح',
                  _canViewReports,
                  (value) => _canViewReports = value,
                ),
                _permissionSwitch(
                  'المصروفات والمشتريات',
                  _canManageExpenses,
                  (value) => _canManageExpenses = value,
                ),
                _permissionSwitch(
                  'المخزون والأصناف',
                  _canManageInventory,
                  (value) => _canManageInventory = value,
                ),
                _permissionSwitch(
                  'العمال والرواتب',
                  _canManageWorkers,
                  (value) => _canManageWorkers = value,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء الحساب'),
        ),
      ],
    );
  }

  Widget _permissionSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.body),
      value: value,
      activeTrackColor: AppColors.primary,
      onChanged: (value) => setState(() => onChanged(value)),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      SubAccountFormData(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _isEditing ? null : _passwordController.text,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        permissions: UserPermissions(
          canManageBookings: _canManageBookings,
          canViewReports: _canViewReports,
          canManageExpenses: _canManageExpenses,
          canManageInventory: _canManageInventory,
          canManageWorkers: _canManageWorkers,
          canManageSubAccounts:
              widget.account?.permissions.canManageSubAccounts ?? false,
        ),
      ),
    );
  }
}

class SubAccountFormData {
  final String fullName;
  final String username;
  final String? password;
  final String? phone;
  final UserPermissions permissions;

  const SubAccountFormData({
    required this.fullName,
    required this.username,
    required this.password,
    required this.phone,
    required this.permissions,
  });
}

class _ResetSubAccountPasswordDialog extends StatefulWidget {
  const _ResetSubAccountPasswordDialog();

  @override
  State<_ResetSubAccountPasswordDialog> createState() =>
      _ResetSubAccountPasswordDialogState();
}

class _ResetSubAccountPasswordDialogState
    extends State<_ResetSubAccountPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعادة تعيين كلمة المرور'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isEmpty) return;
            Navigator.pop(context, _controller.text);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

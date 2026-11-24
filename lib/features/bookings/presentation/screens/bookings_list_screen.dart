import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../../data/models/booking_model.dart';

class BookingsListScreen extends StatefulWidget {
  final String? initialFilter;

  const BookingsListScreen({super.key, this.initialFilter});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<Booking> _allBookings = [];
  bool _isLoading = true;
  final String _selectedHallFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialFilter == 'due') {
      _tabController.index = 3; // 'عليها متبقي'
    }
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final bookings = await ServicesLocator.bookingsRepo.getBookings();
    setState(() {
      _allBookings = bookings;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Booking> _getFilteredBookings(int tabIndex) {
    var list = _allBookings;

    // Search query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((b) {
        return b.customerName.toLowerCase().contains(query) ||
            b.customerPhone.contains(query) ||
            b.id.toString().contains(query);
      }).toList();
    }

    // Hall filter
    if (_selectedHallFilter != 'الكل') {
      list = list.where((b) => b.hallName == _selectedHallFilter).toList();
    }

    // Tab filter: 0: القادمة, 1: المكتملة, 2: الملغاة, 3: عليها متبقي
    switch (tabIndex) {
      case 0:
        return list
            .where((b) => b.status == BookingLifecycleStatus.confirmed)
            .toList();
      case 1:
        return list
            .where((b) => b.status == BookingLifecycleStatus.completed)
            .toList();
      case 2:
        return list
            .where((b) => b.status == BookingLifecycleStatus.cancelled)
            .toList();
      case 3:
        return list
            .where((b) =>
                b.status != BookingLifecycleStatus.cancelled &&
                b.remainingAmount > 0)
            .toList();
      default:
        return list;
    }
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
                title: 'إدارة الحجوزات',
                subtitle: 'استعراض وبحث وتصفية كافة الحجوزات',
                actions: [
                  if (PermissionGuard.canManageBookings)
                    CircleIconButton.primary(
                      icon: const Icon(LucideIcons.plus,
                          size: 20, color: AppColors.white),
                      onTap: () => context.push('/bookings/new'),
                    ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: AppTextField(
                hint: 'بحث باسم العميل، الهاتف، أو رقم الحجز...',
                controller: _searchController,
                prefixIcon: const Icon(LucideIcons.search,
                    size: 18, color: AppColors.muted),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Tabs: القادمة, المكتملة, الملغاة, عليها متبقي
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
                  Tab(text: 'القادمة'),
                  Tab(text: 'المكتملة'),
                  Tab(text: 'الملغاة'),
                  Tab(text: 'عليها متبقي'),
                ],
              ),
            ),

            // List of bookings
            Expanded(
              child: _isLoading
                  ? const AppListSkeleton(itemCount: 4)
                  : TabBarView(
                      controller: _tabController,
                      children: List.generate(4, (index) {
                        final bookings = _getFilteredBookings(index);
                        if (bookings.isEmpty) {
                          return EmptyState(
                            title: 'لا توجد حجوزات في هذا التبويب',
                            subtitle: PermissionGuard.canManageBookings
                                ? 'يمكنك إضافة حجز جديد أو تغيير معايير البحث والفلترة.'
                                : 'يمكنك تغيير معايير البحث والفلترة لعرض الحجوزات.',
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _fetchBookings,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 80, top: 8),
                            itemCount: bookings.length,
                            itemBuilder: (context, i) {
                              final b = bookings[i];
                              return _buildBookingCard(context, b);
                            },
                          ),
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final wasCancelled =
                await context.push<bool>('/bookings/${booking.id}');
            if (wasCancelled == true && mounted) {
              await _fetchBookings();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حجز #${booking.id.toArabicDigits()}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    StatusChip(
                      label: booking.remainingAmount == 0
                          ? 'مدفوع بالكامل'
                          : 'عربون متبقي',
                      backgroundColor: booking.remainingAmount == 0
                          ? AppColors.greenBg
                          : AppColors.amberBg,
                      textColor: booking.remainingAmount == 0
                          ? AppColors.green
                          : AppColors.amberText,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${booking.customerName} · ${booking.eventType}',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.hallName} · ${AppFormatters.formatDayMonth(booking.eventDate)} · ${booking.timeRange}',
                  style: AppTextStyles.muted,
                ),
                const Divider(color: AppColors.line, height: 16, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجمالي: ${AppFormatters.formatMoney(booking.totalAmount)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (booking.remainingAmount > 0)
                      Text(
                        'متبقي ${AppFormatters.formatMoney(booking.remainingAmount)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberText,
                        ),
                      )
                    else
                      const Text(
                        'تم السداد بالكامل',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

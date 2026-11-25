import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import '../../data/models/calendar_day_model.dart';
import '../../data/repos/calendar_repository.dart';

Future<DateTime?> showHallAvailabilityDatePicker({
  required BuildContext context,
  required String hallId,
  required DateTime initialDate,
  required CalendarRepository repository,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _HallAvailabilityDatePicker(
      hallId: hallId,
      initialDate: initialDate,
      repository: repository,
    ),
  );
}

class _HallAvailabilityDatePicker extends StatefulWidget {
  final String hallId;
  final DateTime initialDate;
  final CalendarRepository repository;

  const _HallAvailabilityDatePicker({
    required this.hallId,
    required this.initialDate,
    required this.repository,
  });

  @override
  State<_HallAvailabilityDatePicker> createState() =>
      _HallAvailabilityDatePickerState();
}

class _HallAvailabilityDatePickerState
    extends State<_HallAvailabilityDatePicker> {
  late DateTime _month;
  late DateTime _selectedDate;
  Map<int, CalendarDayModel> _days = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final days = await widget.repository.getCalendarDays(
        hallId: widget.hallId,
        month: _month,
      );
      if (!mounted) return;
      setState(() {
        _days = {for (final day in days) day.dayNumber: day};
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : 'تعذر تحميل حالة القاعة في هذا الشهر.';
        _isLoading = false;
      });
    }
  }

  bool _isSelectable(int day) {
    final date = DateTime(_month.year, _month.month, day);
    final today = DateTime.now();
    final firstAvailableDate = DateTime(today.year, today.month, today.day);
    return !date.isBefore(firstAvailableDate) &&
        _days[day]?.status == DayStatus.available;
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(_month.year, _month.month + offset);
    final today = DateTime.now();
    final lastMonth = DateTime(2028, 12);
    if (nextMonth.isBefore(DateTime(today.year, today.month)) ||
        nextMonth.isAfter(lastMonth)) {
      return;
    }
    setState(() {
      _month = nextMonth;
      _selectedDate = DateTime(nextMonth.year, nextMonth.month, 1);
    });
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final weekdayOffset = DateTime(_month.year, _month.month, 1).weekday % 7;
    final dayCount = DateTime(_month.year, _month.month + 1, 0).day;

    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        'اختيار يوم متاح · ${_month.year.toArabicDigits()}',
        textAlign: TextAlign.center,
        style: AppTextStyles.cardTitle,
      ),
      content: SizedBox(
        width: 360,
        child: _isLoading
            ? const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            : _errorMessage != null
                ? SizedBox(
                    height: 220,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _loadMonth,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'الشهر السابق',
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                            Text(
                              AppFormatters.formatMonthYear(_month),
                              style: AppTextStyles.body,
                            ),
                            IconButton(
                              tooltip: 'الشهر التالي',
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                          ],
                        ),
                        Row(
                          children: AppFormatters.arabicWeekdaysShort
                              .map(
                                (name) => Expanded(
                                  child: Center(
                                    child: Text(
                                      name,
                                      style: AppTextStyles.muted,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: weekdayOffset + dayCount,
                          itemBuilder: (context, index) {
                            if (index < weekdayOffset) {
                              return const SizedBox.shrink();
                            }
                            final dayNumber = index - weekdayOffset + 1;
                            final day = _days[dayNumber];
                            final available = _isSelectable(dayNumber);
                            final isSelected =
                                _selectedDate.year == _month.year &&
                                    _selectedDate.month == _month.month &&
                                    _selectedDate.day == dayNumber;
                            return Center(
                              child: Opacity(
                                opacity: available ? 1 : 0.3,
                                child: DayCircle(
                                  dayNumber: dayNumber,
                                  status: day?.status ?? DayStatus.blocked,
                                  size: 36,
                                  isSelected: isSelected,
                                  onTap: available
                                      ? () => setState(
                                            () => _selectedDate = DateTime(
                                              _month.year,
                                              _month.month,
                                              dayNumber,
                                            ),
                                          )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: [
                            _AvailabilityLegend(
                              status: DayStatus.available,
                              label: 'متاح',
                            ),
                            _AvailabilityLegend(
                              status: DayStatus.deposit,
                              label: 'محجوز',
                            ),
                            _AvailabilityLegend(
                              status: DayStatus.tentative,
                              label: 'مؤقت',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: !_isLoading &&
                  _errorMessage == null &&
                  _isSelectable(_selectedDate.day)
              ? () => Navigator.of(context).pop(_selectedDate)
              : null,
          child: const Text('اختيار'),
        ),
      ],
    );
  }
}

class _AvailabilityLegend extends StatelessWidget {
  final DayStatus status;
  final String label;

  const _AvailabilityLegend({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DayCircle(status: status, size: 12),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.muted),
      ],
    );
  }
}

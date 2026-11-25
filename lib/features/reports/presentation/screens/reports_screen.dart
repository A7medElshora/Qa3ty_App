import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import 'package:qa3ty_app/core/utils/widgets/key_value_row.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../../data/report_export.dart';
import '../../data/models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'شهر';
  FinancialSummary? _summary;
  List<HallComparison> _comparisons = [];
  bool _isLoading = true;
  String? _loadError;
  DateTime _customStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _customEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final summary = await ServicesLocator.reportsRepo.getSummary(
        period: _selectedPeriod,
        startDate: _selectedPeriod == 'مخصص' ? _customStartDate : null,
        endDate: _selectedPeriod == 'مخصص' ? _customEndDate : null,
      );
      final comparisons =
          await ServicesLocator.reportsRepo.getHallsComparison();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _comparisons = comparisons;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPeriod(String period) async {
    if (period == 'مخصص') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: _customStartDate,
          end: _customEndDate.isAfter(DateTime.now())
              ? DateTime.now()
              : _customEndDate,
        ),
      );
      if (range == null || !mounted) return;
      setState(() {
        _customStartDate = range.start;
        _customEndDate = range.end;
        _selectedPeriod = period;
      });
    } else {
      setState(() => _selectedPeriod = period);
    }
    _fetchReports();
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
                title: 'التقارير المالية والأرباح',
                subtitle: 'تحليل الإيرادات، المصروفات، وصافي الأرباح',
                actions: [
                  CircleIconButton.white(
                    icon: const Icon(LucideIcons.fileSpreadsheet,
                        size: 20, color: AppColors.green),
                    onTap: _showExportExcelDialog,
                  ),
                ],
              ),
            ),

            // Period selector: شهر / سنة / مخصص
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ['شهر', 'سنة', 'مخصص'].map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AppChip(
                      label: p,
                      isSelected: _selectedPeriod == p,
                      onTap: () => _selectPeriod(p),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_selectedPeriod == 'مخصص')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _selectPeriod('مخصص'),
                    icon: const Icon(LucideIcons.calendarDays, size: 16),
                    label: Text(
                      '${AppFormatters.formatDayMonth(_customStartDate)} - ${AppFormatters.formatDayMonth(_customEndDate)}',
                    ),
                  ),
                ),
              ),

            Expanded(
              child: _isLoading
                  ? const AppSkeletonizer(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 80,
                          top: 8,
                        ),
                        child: Column(
                          children: [
                            AppSkeletonPanel(height: 110, lineCount: 1),
                            SizedBox(height: 14),
                            AppSkeletonPanel(height: 250, lineCount: 5),
                            SizedBox(height: 14),
                            AppSkeletonPanel(height: 240, lineCount: 4),
                          ],
                        ),
                      ),
                    )
                  : _loadError != null
                      ? ErrorState(
                          message: _loadError!,
                          onRetry: _fetchReports,
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 80, top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1) Net profit highlighted card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'صافي الأرباح المحققة',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13,
                                        color: AppColors.primarySoftText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppFormatters.formatMoney(
                                          _summary?.netProfit ?? 0),
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // 2) Financial Breakdown Card
                              SectionCard(
                                title: 'ملخص الحسابات المالية',
                                child: Column(
                                  children: [
                                    KeyValueRow(
                                      label: 'إجمالي الإيرادات التعاقدية',
                                      value: AppFormatters.formatMoney(
                                          _summary?.totalRevenue ?? 0),
                                    ),
                                    KeyValueRow(
                                      label: 'المبالغ المُحصَّلة فعلياً',
                                      value: AppFormatters.formatMoney(
                                          _summary?.totalCollected ?? 0),
                                      valueStyle: const TextStyle(
                                          color: AppColors.green,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    KeyValueRow(
                                      label: 'المبالغ المستحقة المتبقية',
                                      value: AppFormatters.formatMoney(
                                          _summary?.totalDue ?? 0),
                                      valueStyle: const TextStyle(
                                          color: AppColors.amberText,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Divider(
                                        color: AppColors.line, height: 16),
                                    KeyValueRow(
                                      label: 'المصروفات التشغيلية',
                                      value: AppFormatters.formatMoney(
                                          _summary?.totalExpenses ?? 0),
                                      valueStyle: const TextStyle(
                                          color: AppColors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    KeyValueRow(
                                      label: 'أجور ورواتب العمال',
                                      value: AppFormatters.formatMoney(
                                          _summary?.totalWages ?? 0),
                                      valueStyle: const TextStyle(
                                          color: AppColors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    KeyValueRow(
                                      label: 'مشتريات المخزون',
                                      value: AppFormatters.formatMoney(
                                          _summary?.totalStockPurchases ?? 0),
                                    ),
                                    KeyValueRow(
                                      label: 'قيمة الهالك والتالف',
                                      value: AppFormatters.formatMoney(
                                          _summary?.totalStockWaste ?? 0),
                                      valueStyle:
                                          const TextStyle(color: AppColors.red),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // 3) Comparison Chart with fl_chart
                              SectionCard(
                                title: 'مقارنة إيرادات القاعات',
                                child: _comparisons.isEmpty
                                    ? const SizedBox(
                                        height: 96,
                                        child: Center(
                                          child: Text(
                                              'لا توجد بيانات مقارنة للقاعات'),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 230,
                                        child: BarChart(
                                          BarChartData(
                                            alignment:
                                                BarChartAlignment.spaceAround,
                                            maxY: _chartMaxY,
                                            minY: 0,
                                            barTouchData: const BarTouchData(
                                                enabled: true),
                                            titlesData: FlTitlesData(
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 42,
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    final idx = value.toInt();
                                                    if (idx >= 0 &&
                                                        idx <
                                                            _comparisons
                                                                .length) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8),
                                                        child: Text(
                                                          _comparisons[idx]
                                                              .hallName,
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              fontFamily:
                                                                  AppTextStyles
                                                                      .fontFamily,
                                                              fontSize: 11),
                                                        ),
                                                      );
                                                    }
                                                    return const SizedBox
                                                        .shrink();
                                                  },
                                                ),
                                              ),
                                              leftTitles: const AxisTitles(
                                                  sideTitles: SideTitles(
                                                      showTitles: false)),
                                              topTitles: const AxisTitles(
                                                  sideTitles: SideTitles(
                                                      showTitles: false)),
                                              rightTitles: const AxisTitles(
                                                  sideTitles: SideTitles(
                                                      showTitles: false)),
                                            ),
                                            gridData:
                                                const FlGridData(show: false),
                                            borderData:
                                                FlBorderData(show: false),
                                            barGroups: _comparisons
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final index = entry.key;
                                              final comparison = entry.value;
                                              return BarChartGroupData(
                                                x: index,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: comparison.revenue
                                                        .toDouble(),
                                                    color: index == 0
                                                        ? AppColors.primary
                                                        : AppColors.gold,
                                                    width: 24,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  double get _chartMaxY {
    final highestRevenue = _comparisons.fold<int>(
      0,
      (highest, comparison) =>
          comparison.revenue > highest ? comparison.revenue : highest,
    );
    return highestRevenue <= 0 ? 1 : highestRevenue * 1.2;
  }

  void _showExportExcelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تصدير كشف الحساب Excel',
            style: AppTextStyles.cardTitle),
        content: const Text(
          'سيتم إنشاء ملف CSV متوافق مع Excel وقابل للتحرير، ويحتوي على ملخص الحسابات ومقارنة إيرادات القاعات المتاحة.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري تجهيز التقرير للمشاركة...')),
              );
              try {
                final summary = _summary;
                if (summary == null) {
                  throw StateError('لا توجد بيانات مالية لتصديرها');
                }
                final now = DateTime.now();
                final directory = await getApplicationDocumentsDirectory();
                final file = File(
                  '${directory.path}${Platform.pathSeparator}'
                  'qa3aty_report_${now.year}_${now.month}_${now.day}.csv',
                );
                await file.writeAsBytes(
                  buildFinancialReportCsv(
                    period: _selectedPeriod == 'مخصص'
                        ? '${AppFormatters.formatDayMonth(_customStartDate)} - ${AppFormatters.formatDayMonth(_customEndDate)}'
                        : _selectedPeriod,
                    generatedAt: now,
                    summary: summary,
                    comparisons: _comparisons,
                  ),
                  flush: true,
                );
                if (!mounted) return;
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path)],
                    text: 'تقرير قعطي المالي',
                    subject: 'تقرير قعطي المالي',
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('فشل تصدير التقرير: $e'),
                        backgroundColor: AppColors.red),
                  );
                }
              }
            },
            child:
                const Text('تصدير الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

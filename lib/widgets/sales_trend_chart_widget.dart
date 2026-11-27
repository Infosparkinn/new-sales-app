import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/invoice.dart';

class SalesDayData {
  final DateTime date;
  final String dayName;
  final double amount;
  final int invoiceCount;

  SalesDayData({
    required this.date,
    required this.dayName,
    required this.amount,
    required this.invoiceCount,
  });
}

class SalesTrendChartWidget extends StatefulWidget {
  final List<Invoice> invoices;

  const SalesTrendChartWidget({super.key, required this.invoices});

  @override
  State<SalesTrendChartWidget> createState() => _SalesTrendChartWidgetState();
}

class _SalesTrendChartWidgetState extends State<SalesTrendChartWidget> {
  int? _hoveredIndex;

  List<SalesDayData> _calculateLast7DaysSales() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<SalesDayData> list = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayInvoices = widget.invoices.where((inv) {
        return inv.invoiceDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            inv.invoiceDate.isBefore(dayEnd);
      }).toList();

      final total = dayInvoices.fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);
      final dayName = i == 0 ? 'Today' : DateFormat('E').format(date);

      list.add(SalesDayData(
        date: date,
        dayName: dayName,
        amount: total,
        invoiceCount: dayInvoices.length,
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final data = _calculateLast7DaysSales();
    final total7Days = data.fold<double>(0.0, (sum, d) => sum + d.amount);
    final avgDaily = total7Days / 7.0;
    final maxAmount = data.fold<double>(0.0, (max, d) => d.amount > max ? d.amount : max);
    final effectiveMax = maxAmount == 0 ? 1000.0 : maxAmount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Sales Trend',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Last 7 Days Revenue Analytics',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  AppTheme.shortCurrency.format(total7Days),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bar Chart Visualizer
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(data.length, (index) {
                final item = data[index];
                final ratio = (item.amount / effectiveMax).clamp(0.04, 1.0);
                final isSelected = _hoveredIndex == index;
                final isToday = index == data.length - 1;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _hoveredIndex = _hoveredIndex == index ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Amount tooltip or value
                          if (isSelected || item.amount > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppTheme.shortCurrency.format(item.amount),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? AppTheme.accent : AppTheme.primary,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 14),
                          const SizedBox(height: 4),

                          // Visual Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            height: 80 * ratio,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: isToday
                                  ? AppTheme.accentGradient
                                  : (isSelected
                                      ? AppTheme.primaryGradient
                                      : LinearGradient(
                                          colors: [
                                            AppTheme.primary.withOpacity(0.75),
                                            AppTheme.primaryLight.withOpacity(0.9),
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        )),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Day Label
                          Text(
                            item.dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday ? AppTheme.accent : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Bottom Quick Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Daily Avg: ${AppTheme.shortCurrency.format(avgDaily)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Today Highlighted',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../models/service_reminder.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';

class ServiceRemindersScreen extends StatefulWidget {
  const ServiceRemindersScreen({super.key});

  @override
  State<ServiceRemindersScreen> createState() => _ServiceRemindersScreenState();
}

class _ServiceRemindersScreenState extends State<ServiceRemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reminders = provider.reminders;

    final upcoming = reminders.where((r) => r.status != 'completed' && !r.isOverdue).toList();
    final overdue = reminders.where((r) => r.status != 'completed' && r.isOverdue).toList();
    final completed = reminders.where((r) => r.status == 'completed').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service & Payment Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded),
            tooltip: 'Add Reminder',
            onPressed: () => _showAddReminderDialog(context, provider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'UPCOMING (${upcoming.length})'),
            Tab(text: 'OVERDUE (${overdue.length})'),
            Tab(text: 'COMPLETED (${completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersList(upcoming, provider, 'No upcoming reminders', 'Scheduled maintenance, warranties, and service renewals will show here.'),
          _buildRemindersList(overdue, provider, 'No overdue reminders', 'All customer reminders and payments are up to date!'),
          _buildRemindersList(completed, provider, 'No completed reminders', 'Reminders marked as completed will be archived here.'),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_alert_rounded),
          label: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showAddReminderDialog(context, provider),
        ),
      ),
    );
  }

  Widget _buildRemindersList(List<ServiceReminder> list, AppProvider provider, String emptyTitle, String emptySubtitle) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_outlined, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Text(emptyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(emptySubtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Reminder'),
                onPressed: () => _showAddReminderDialog(context, provider),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rem = list[index];
        final isDone = rem.status == 'completed';
        final isOverdue = rem.isOverdue && !isDone;

        return Container(
          decoration: AppTheme.modernCardDecoration(
            borderRadius: 14,
            borderColor: isOverdue ? AppTheme.accent.withOpacity(0.4) : AppTheme.border.withOpacity(0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.grey.shade100
                        : (isOverdue ? Colors.red.shade50 : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone ? Colors.grey.shade300 : (isOverdue ? Colors.red.shade200 : Colors.blue.shade200),
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle_rounded : (isOverdue ? Icons.warning_amber_rounded : Icons.alarm_rounded),
                    color: isDone ? Colors.grey : (isOverdue ? AppTheme.accent : AppTheme.primary),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rem.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDone ? Colors.grey : AppTheme.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Customer: ${rem.customerName} • Due: ${AppTheme.dateFormat.format(rem.dueDate)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      if (rem.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(rem.description, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDone)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                        tooltip: 'Send WhatsApp Reminder',
                        onPressed: () {
                          ShareService.shareServiceReminder(
                            business: provider.business,
                            customerName: rem.customerName,
                            serviceTitle: rem.title,
                            dueDate: rem.dueDate,
                            customerPhone: rem.customerPhone,
                            description: rem.description,
                          );
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                        color: isDone ? Colors.grey : AppTheme.successGreen,
                        size: 22,
                      ),
                      tooltip: isDone ? 'Mark as Pending' : 'Mark as Completed',
                      onPressed: () {
                        provider.toggleReminderStatus(rem.id, isDone ? 'pending' : 'completed');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddReminderDialog(BuildContext context, AppProvider provider) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Party? selectedCustomer = provider.customers.isNotEmpty ? provider.customers.first : null;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Service Reminder'),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<Party>(
                          value: selectedCustomer,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Customer *'),
                          items: provider.customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setDialogState(() => selectedCustomer = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Reminder Title *', hintText: 'e.g. Filter Maintenance / Balance Followup'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(labelText: 'Notes / Details'),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: dueDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setDialogState(() => dueDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Due Date'),
                            child: Text(AppTheme.dateFormat.format(dueDate)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    final reminder = ServiceReminder(
                      id: const Uuid().v4(),
                      firmId: provider.activeFirm.id,
                      customerId: selectedCustomer?.id,
                      customerName: selectedCustomer?.name ?? 'Customer',
                      customerPhone: selectedCustomer?.phone ?? '',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      dueDate: dueDate,
                    );
                    await provider.saveReminder(reminder);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Reminder'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

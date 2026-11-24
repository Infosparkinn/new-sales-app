import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/party.dart';
import '../../models/service_reminder.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';

class ServiceRemindersScreen extends StatelessWidget {
  const ServiceRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service & Payment Reminders'),
      ),
      body: reminders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No reminders scheduled', style: TextStyle(color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  Text('Set service, maintenance, and payment follow-ups', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final rem = reminders[index];
                final isDone = rem.status == 'completed';

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDone ? Colors.grey.shade200 : (rem.isOverdue ? Colors.red.shade50 : Colors.blue.shade50),
                      child: Icon(
                        isDone ? Icons.check_circle : (rem.isOverdue ? Icons.warning_amber_rounded : Icons.alarm),
                        color: isDone ? Colors.grey : (rem.isOverdue ? AppTheme.accent : AppTheme.primary),
                      ),
                    ),
                    title: Text(
                      rem.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${rem.customerName} • Due: ${AppTheme.dateFormat.format(rem.dueDate)}'),
                        if (rem.description.isNotEmpty) Text(rem.description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDone)
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
                            tooltip: 'Send Reminder on WhatsApp',
                            onPressed: () {
                              ShareService.sharePartyReminder(
                                business: provider.business,
                                partyName: rem.customerName,
                                balanceAmount: 0.0,
                              );
                            },
                          ),
                        IconButton(
                          icon: Icon(isDone ? Icons.undo_rounded : Icons.check_circle_outline, color: isDone ? Colors.grey : AppTheme.successGreen),
                          tooltip: isDone ? 'Mark Pending' : 'Mark Completed',
                          onPressed: () {
                            provider.toggleReminderStatus(rem.id, isDone ? 'pending' : 'completed');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('New Reminder'),
        onPressed: () => _showAddReminderDialog(context, provider),
      ),
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
          builder: (ctx, setState) {
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
                          decoration: const InputDecoration(labelText: 'Customer *'),
                          items: provider.customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                          onChanged: (v) => setState(() => selectedCustomer = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Reminder Title *', hintText: 'e.g. RO Filter Service / Balance Payment'),
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
                            if (picked != null) setState(() => dueDate = picked);
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

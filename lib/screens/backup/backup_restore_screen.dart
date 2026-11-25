import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/share_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _autoBackupEnabled = true;
  bool _isBackingUp = false;
  String? _lastBackupPath;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Back up / Restore Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto Backup Switch (Image 9)
            Card(
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.12),
                  child: const Icon(Icons.cloud_upload_rounded, color: Colors.teal),
                ),
                title: const Text('Auto Back up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Automatically save encrypted daily local backups', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                value: _autoBackupEnabled,
                onChanged: (val) => setState(() => _autoBackupEnabled = val),
              ),
            ),
            const SizedBox(height: 16),

            const Text('MANUAL BACKUP OPTIONS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),

            // Back up to phone (Image 9)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: const Icon(Icons.smartphone_rounded, color: AppTheme.primary),
                ),
                title: const Text('Back up to phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Save offline backup file (.json) to Documents directory', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: _isBackingUp ? null : () => _backupToPhone(context, provider),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Back up', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Back up to e-mail (Image 9)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.withOpacity(0.12),
                  child: const Icon(Icons.email_rounded, color: Colors.indigo),
                ),
                title: const Text('Back up to e-mail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Send database backup bundle to your registered email', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () => _backupToEmail(context, provider),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Email', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('RESTORE DATA',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),

            // Restore back up (Image 9)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.12),
                  child: const Icon(Icons.restore_page_rounded, color: Colors.orange),
                ),
                title: const Text('Restore back up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Load previously exported backup to restore firms, bills & stock', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                  onPressed: () => _showRestoreDialog(context, provider),
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('Restore', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_lastBackupPath != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Last Backup: $_lastBackupPath',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupToPhone(BuildContext context, AppProvider provider) async {
    setState(() => _isBackingUp = true);
    try {
      final jsonStr = await provider.exportBackupJson();
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = 'vyapar_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${docsDir.path}/$fileName');
      await file.writeAsString(jsonStr);

      setState(() => _lastBackupPath = file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup successfully saved to ${file.path}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  Future<void> _backupToEmail(BuildContext context, AppProvider provider) async {
    try {
      final jsonStr = await provider.exportBackupJson();
      final firm = provider.activeFirm;
      final subject = 'Vyapar App Backup - ${firm.name} (${DateTime.now().toIso8601String().substring(0, 10)})';
      final text = 'Attached is the complete Vyapar accounting & sales backup file for ${firm.name}.\n\nBackup Data Preview:\n$jsonStr';

      ShareService.shareText(text: text, subject: subject);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email share failed: $e')));
    }
  }

  void _showRestoreDialog(BuildContext context, AppProvider provider) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste the JSON backup content below to restore all items, parties, bills, and accounts:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{\n  "version": 3,\n  "firms": [...]\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            onPressed: () async {
              final content = textController.text.trim();
              if (content.isEmpty) return;
              try {
                await provider.restoreBackupJson(content);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database successfully restored from backup!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
              }
            },
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );
  }
}

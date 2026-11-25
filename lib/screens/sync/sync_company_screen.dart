import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class SyncCompanyScreen extends StatefulWidget {
  const SyncCompanyScreen({super.key});

  @override
  State<SyncCompanyScreen> createState() => _SyncCompanyScreenState();
}

class _SyncCompanyScreenState extends State<SyncCompanyScreen> {
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final syncInfo = provider.syncCompanyInfo;
    final companyName = syncInfo['companyName'] ?? 'Sivan sports pro';
    final lastSynced = syncInfo['lastSyncedAt'] ?? DateTime.now().toIso8601String();
    final parsedDate = DateTime.tryParse(lastSynced) ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Company & Cross-Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync_rounded),
            tooltip: 'Sync Now',
            onPressed: _isSyncing ? null : () => _performSync(provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Status Card (Image 8 requirement: Sivan sports pro)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_rounded, color: Colors.greenAccent, size: 14),
                            SizedBox(width: 6),
                            Text('SYNCED & ONLINE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Icon(Icons.sync_rounded, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('CONNECTED SYNC COMPANY', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(companyName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Last Synced: ${AppTheme.dateFormat.format(parsedDate)} ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const Text('Cloud Storage: Active', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sync Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSyncing ? null : () => _performSync(provider),
                icon: _isSyncing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.sync_rounded),
                label: Text(_isSyncing ? 'SYNCING DATA ACROSS DEVICES...' : 'SYNC ALL DATA NOW',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // Sync Settings & Switches
            const Text('SYNC SETTINGS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Automatic Background Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Synchronize transactions automatically when network is available', style: TextStyle(fontSize: 11)),
                    value: _autoSyncEnabled,
                    onChanged: (val) => setState(() => _autoSyncEnabled = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.devices_rounded, color: AppTheme.primary),
                    title: const Text('Registered Devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Desktop POS Terminal, Mobile Tablet, Store Counter', style: TextStyle(fontSize: 11)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                      child: const Text('3 Devices', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: Colors.green),
                    title: const Text('End-to-End Encryption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('AES-256 local-first encrypted database sync', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Connected Entities
            const Text('COMPANIES IN SYNC ROSTER',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.12),
                      child: const Icon(Icons.business_rounded, color: Colors.teal),
                    ),
                    title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Primary Sync Partner • All Sales & Purchases Synced', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.cloud_done_rounded, color: Colors.teal),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: const Icon(Icons.store_rounded, color: AppTheme.primary),
                    ),
                    title: Text(provider.activeFirm.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Local Host Firm • Master Database', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.cloud_done_rounded, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSync(AppProvider provider) async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    await provider.triggerCompanySync();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('All local records successfully synced with Sivan sports pro!'),
            ],
          ),
          backgroundColor: Color(0xFF0F766E),
        ),
      );
    }
  }
}

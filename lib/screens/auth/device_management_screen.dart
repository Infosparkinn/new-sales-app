import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/app_provider.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.appUsers;
    final sessions = provider.deviceSessions;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Device & Session Manager'),
        backgroundColor: const Color(0xFFC62828),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Multi-Device Status Card
                _buildSummaryCard(provider),
                const SizedBox(height: 20),

                // Device Allocation Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CONNECTED TERMINALS (4/4 SLOTS ALLOCATED)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${provider.activeDeviceCount} of 4 Online',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Device Cards List
                if (sessions.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  ...sessions.map((session) {
                    final matchingUser = users.firstWhere(
                      (u) => u.id == session.userId,
                      orElse: () => AppUser(
                        id: session.userId,
                        name: session.userName,
                        phone: '',
                        role: 'salesman',
                        deviceType: session.deviceType,
                        deviceSlot: session.deviceSlot,
                      ),
                    );
                    return _buildDeviceSessionCard(session, matchingUser, provider);
                  }),

                const SizedBox(height: 24),

                // Role Permissions Matrix
                _buildRolePermissionsTable(),
                const SizedBox(height: 24),

                // License Info
                _buildLicenseNotice(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.devices, color: Color(0xFFC62828)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Multi-Device Enterprise License',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Synchronizing with ${provider.activeFirm.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: const Text(
                  'SYNC ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Desktop Station',
                  value: '1 / 1 Terminal',
                  sub: 'Windows Desktop POS',
                  icon: Icons.desktop_windows,
                  color: const Color(0xFF1565C0),
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade200),
              Expanded(
                child: _buildMetricTile(
                  label: 'Mobile Stations',
                  value: '3 / 3 Terminals',
                  sub: 'Android Handhelds',
                  icon: Icons.phone_android,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade200),
              Expanded(
                child: _buildMetricTile(
                  label: 'Total Allocated',
                  value: '4 Terminals',
                  sub: '100% Utilized',
                  icon: Icons.check_circle,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSessionCard(
    DeviceSession session,
    AppUser user,
    AppProvider provider,
  ) {
    final isDesktop = session.deviceType == 'desktop';
    final cardColor = isDesktop
        ? const Color(0xFF1565C0)
        : (user.role == 'salesman'
            ? const Color(0xFF2E7D32)
            : (user.role == 'delivery'
                ? const Color(0xFFE65100)
                : const Color(0xFF6A1B9A)));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cardColor.withOpacity(0.12),
                  child: Icon(
                    isDesktop ? Icons.desktop_windows : Icons.phone_android,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              session.deviceName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDesktop
                                  ? const Color(0xFFE3F2FD)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              session.deviceSlot.toUpperCase().replaceAll('_', ' '),
                              style: TextStyle(
                                color: isDesktop
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'User: ${user.name} (${user.role.toUpperCase()})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: session.isOnline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            session.isOnline ? 'Online' : 'Offline / Disconnected',
                            style: TextStyle(
                              fontSize: 11,
                              color: session.isOnline
                                  ? Colors.green.shade800
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'IP: ${session.ipAddress}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Change PIN & Toggle Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.key, size: 14),
                      label: const Text('Change PIN', style: TextStyle(fontSize: 11)),
                      onPressed: () => _promptChangePinDialog(user, provider),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        provider.toggleDeviceSession(
                            session.id, !session.isOnline);
                      },
                      child: Text(
                        session.isOnline ? 'Disconnect' : 'Reconnect',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: session.isOnline ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _promptChangePinDialog(AppUser user, AppProvider provider) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Reset PIN: ${user.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current PIN',
                      hintText: 'Default 1234',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New 4-Digit PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        error,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (newPinController.text.length != 4) {
                      setDialogState(() {
                        error = 'PIN must be exactly 4 digits';
                      });
                      return;
                    }
                    final ok = await provider.updatePin(
                      user.id,
                      currentPinController.text,
                      newPinController.text,
                    );
                    if (ok) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('PIN updated successfully for ${user.name}'),
                        ),
                      );
                    } else {
                      setDialogState(() {
                        error = 'Current PIN is incorrect!';
                      });
                    }
                  },
                  child: const Text('Update PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRolePermissionsTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Role Permissions Matrix',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Role / Device')),
                DataColumn(label: Text('View Reports')),
                DataColumn(label: Text('Edit Rates')),
                DataColumn(label: Text('Delete Bills')),
                DataColumn(label: Text('View Profit')),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('1. Desktop Admin (POS 1)',
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                ]),
                DataRow(cells: [
                  DataCell(Text('2. Mobile Sales Exec (Slot 1)')),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                ]),
                DataRow(cells: [
                  DataCell(Text('3. Mobile Delivery (Slot 2)')),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                ]),
                DataRow(cells: [
                  DataCell(Text('4. Mobile Assistant (Slot 3)')),
                  DataCell(Icon(Icons.check, color: Colors.green, size: 18)),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                  DataCell(Icon(Icons.close, color: Colors.red, size: 18)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your subscription includes 1 Desktop Windows Terminal and 3 Mobile Android logins. All 4 terminals are actively synchronized.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
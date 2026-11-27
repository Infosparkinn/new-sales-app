import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/app_provider.dart';
import 'device_management_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isSwitchingUser;
  final bool? forceDesktopOnly;

  const LoginScreen({
    super.key,
    this.isSwitchingUser = false,
    this.forceDesktopOnly,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _enteredPin = '';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final desktopUser = provider.desktopUser;
    final mobileUsers = provider.mobileUsers;

    final bool isDesktopVersion = widget.forceDesktopOnly ??
        (kIsWeb ||
            (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ||
            MediaQuery.of(context).size.width >= 800);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(isDesktopVersion ? 'Desktop Version Login' : 'Mobile Staff Login'),
        backgroundColor: const Color(0xFFC62828),
        leading: widget.isSwitchingUser
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.devices_other),
            tooltip: isDesktopVersion ? 'Desktop Terminal System' : 'Device Manager (4 Devices)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeviceManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Branding Banner
                _buildHeader(provider, isDesktopVersion: isDesktopVersion),
                const SizedBox(height: 20),

                // License Allocation Pill
                _buildLicensePill(provider, isDesktopVersion: isDesktopVersion),
                const SizedBox(height: 24),

                if (isDesktopVersion) ...[
                  // DESKTOP ONLY: Show ONLY Desktop Master Admin (No Mobile section!)
                  _buildSectionHeader(
                    title: 'DESKTOP VERSION (MASTER POS COUNTER)',
                    icon: Icons.computer,
                    color: const Color(0xFF1565C0),
                    tag: 'Full Administrator Rights',
                  ),
                  const SizedBox(height: 10),
                  if (desktopUser != null)
                    _buildUserCard(
                      user: desktopUser,
                      isDesktop: true,
                      isCurrent: provider.currentUser?.id == desktopUser.id,
                    ),
                ] else ...[
                  // MOBILE VERSION: Show Mobile Android staff logins
                  _buildSectionHeader(
                    title: 'MOBILE STAFF LOGINS (Field & Staff)',
                    icon: Icons.phone_android,
                    color: const Color(0xFF2E7D32),
                    tag: 'Role-Based Access',
                  ),
                  const SizedBox(height: 10),
                  if (mobileUsers.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Loading mobile profiles...'),
                      ),
                    )
                  else
                    ...mobileUsers.map((u) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildUserCard(
                            user: u,
                            isDesktop: false,
                            isCurrent: provider.currentUser?.id == u.id,
                          ),
                        )),
                ],
                const SizedBox(height: 24),

                // Security footer
                _buildSecurityFooter(provider, isDesktopVersion: isDesktopVersion),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider, {required bool isDesktopVersion}) {
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/testing_sales_app_logo.jpg',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Color(0xFFC62828),
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.activeFirm.name.isNotEmpty
                      ? provider.activeFirm.name
                      : 'Testing Sales App',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDesktopVersion
                      ? 'Testing Sales App • Desktop Version'
                      : 'Testing Sales App • Mobile Version',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (provider.currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  Text(
                    'Active: ${provider.currentUser!.name.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLicensePill(AppProvider provider, {required bool isDesktopVersion}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDesktopVersion ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDesktopVersion ? const Color(0xFFBFDBFE) : const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user,
            color: isDesktopVersion ? const Color(0xFF1D4ED8) : const Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDesktopVersion
                      ? 'Desktop Version • Licensed Master POS Terminal'
                      : 'Mobile Field Terminals • Role-Based Access',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDesktopVersion ? const Color(0xFF1E40AF) : const Color(0xFF92400E),
                  ),
                ),
                Text(
                  isDesktopVersion
                      ? 'Full Administrator Rights • High-Performance Counter POS Active'
                      : '3 Android Mobile field terminals active & ready',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDesktopVersion ? const Color(0xFF1E3A8A) : Colors.brown.shade800,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeviceManagementScreen(),
                ),
              );
            },
            icon: Icon(Icons.settings, size: 16, color: isDesktopVersion ? const Color(0xFF1D4ED8) : const Color(0xFF92400E)),
            label: Text(
              'Manage',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDesktopVersion ? const Color(0xFF1D4ED8) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required String tag,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard({
    required AppUser user,
    required bool isDesktop,
    required bool isCurrent,
  }) {
    final roleColor = isDesktop
        ? const Color(0xFF1565C0)
        : (user.role == 'salesman'
            ? const Color(0xFF2E7D32)
            : (user.role == 'delivery'
                ? const Color(0xFFE65100)
                : const Color(0xFF6A1B9A)));

    final roleLabel = isDesktop
        ? 'Desktop Master Admin'
        : (user.role == 'salesman'
            ? 'Mobile Sales Executive'
            : (user.role == 'delivery'
                ? 'Mobile Delivery Agent'
                : 'Mobile Billing Assistant'));

    final deviceSlotLabel = isDesktop
        ? 'DESKTOP SLOT 1'
        : (user.deviceSlot == 'mobile_1'
            ? 'MOBILE SLOT 1'
            : (user.deviceSlot == 'mobile_2'
                ? 'MOBILE SLOT 2'
                : 'MOBILE SLOT 3'));

    return Card(
      elevation: isCurrent ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrent ? roleColor : Colors.grey.shade300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _promptPinDialog(user),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar with slot badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: roleColor.withOpacity(0.12),
                    child: Icon(
                      isDesktop ? Icons.desktop_windows : Icons.phone_android,
                      color: roleColor,
                      size: 28,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const SizedBox(width: 6, height: 6),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC62828),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LOGGED IN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          deviceSlotLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Permissions: ${_formatPermissions(user)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action button
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _promptPinDialog(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_open, size: 16),
                    SizedBox(width: 6),
                    Text('Login / PIN'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPermissions(AppUser user) {
    List<String> perms = [];
    if (user.canViewReports) perms.add('Reports');
    if (user.canEditPrices) perms.add('Edit Rates');
    if (user.canDeleteBills) perms.add('Delete Bills');
    if (user.canViewProfits) perms.add('View Profit');
    if (perms.isEmpty) return 'Create Sales & Payments';
    return perms.join(', ');
  }

  void _promptPinDialog(AppUser user) {
    _enteredPin = '';
    _hasError = false;
    _errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDesktop = user.deviceType == 'desktop';
            final primaryColor = isDesktop
                ? const Color(0xFF1565C0)
                : const Color(0xFF2E7D32);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.all(20),
              title: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryColor.withOpacity(0.12),
                    child: Icon(
                      isDesktop ? Icons.desktop_windows : Icons.phone_android,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Enter 4-Digit Security PIN',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 4 PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? primaryColor : Colors.grey.shade300,
                          border: Border.all(
                            color: isFilled ? primaryColor : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),

                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline, size: 14, color: Colors.brown),
                        SizedBox(width: 6),
                        Text(
                          'Default PIN is 1234',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Numeric Keypad
                  _buildKeypad(setDialogState, user, ctx),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Quick Demo Login bypass
                    await _executeLogin(user.deviceSlot, user.pin, ctx);
                  },
                  child: const Text(
                    'Quick Login (1234)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKeypad(
      StateSetter setDialogState, AppUser user, BuildContext dialogContext) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3']
                .map((d) => _buildKey(d, setDialogState, user, dialogContext))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6']
                .map((d) => _buildKey(d, setDialogState, user, dialogContext))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9']
                .map((d) => _buildKey(d, setDialogState, user, dialogContext))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Clear
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  setDialogState(() {
                    _enteredPin = '';
                    _hasError = false;
                  });
                },
              ),
              _buildKey('0', setDialogState, user, dialogContext),
              // Backspace
              IconButton(
                icon: const Icon(Icons.backspace_outlined, color: Colors.grey),
                onPressed: () {
                  if (_enteredPin.isNotEmpty) {
                    setDialogState(() {
                      _enteredPin =
                          _enteredPin.substring(0, _enteredPin.length - 1);
                      _hasError = false;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit, StateSetter setDialogState, AppUser user,
      BuildContext dialogContext) {
    return SizedBox(
      width: 55,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        onPressed: () async {
          if (_enteredPin.length < 4) {
            setDialogState(() {
              _enteredPin += digit;
            });
            if (_enteredPin.length == 4) {
              await _executeLogin(user.deviceSlot, _enteredPin, dialogContext,
                  setDialogState);
            }
          }
        },
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Future<void> _executeLogin(
    String slot,
    String pin,
    BuildContext dialogContext, [
    StateSetter? setDialogState,
  ]) async {
    final provider = context.read<AppProvider>();
    final success = await provider.loginUser(slot, pin);

    if (success) {
      if (mounted) {
        Navigator.pop(dialogContext); // Close PIN dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Logged in as ${provider.currentUser?.name}'),
              ],
            ),
          ),
        );
        if (widget.isSwitchingUser) {
          Navigator.pop(context); // Return to previous screen
        }
      }
    } else {
      if (setDialogState != null) {
        setDialogState(() {
          _hasError = true;
          _errorMessage = 'Incorrect PIN! Try 1234';
          _enteredPin = '';
        });
      }
    }
  }

  Widget _buildSecurityFooter(AppProvider provider, {required bool isDesktopVersion}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 18, color: isDesktopVersion ? const Color(0xFF1565C0) : const Color(0xFFC62828)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDesktopVersion ? 'Enterprise Desktop POS Terminal' : 'Enterprise Role-Based Access Control',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isDesktopVersion
                ? '• Desktop Version includes master counter POS, barcode scanning, thermal printing, and multi-firm ledger.\n'
                  '• Complete financial controls: audit trails, GST filing summaries, and balance sheet reporting.\n'
                  '• Offline-first SQLite database with automatic local and cloud backup synchronization.'
                : '• 3 Mobile Android logins are restricted by role (Salesman, Delivery Agent, and Counter Assistant) to safeguard sensitive finances.\n'
                  '• Data synchronizes continuously across all devices via local SQLite and Vyapar Cloud sync.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
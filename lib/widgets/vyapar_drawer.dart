import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import '../screens/firms/firms_management_screen.dart';
import '../screens/billing/sales_history_screen.dart';
import '../screens/billing/mobile_pos_screen.dart';
import '../screens/billing/orders_challans_screen.dart';
import '../screens/transactions/add_payment_in_dialog.dart';
import '../screens/transactions/add_expense_dialog.dart';
import '../screens/purchase/purchase_management_screen.dart';
import '../screens/purchase/add_payment_out_dialog.dart';
import '../screens/cash_bank/cash_bank_screen.dart';
import '../screens/online_store/online_store_screen.dart';
import '../screens/loyalty/loyalty_points_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/sync/sync_company_screen.dart';
import '../screens/backup/backup_restore_screen.dart';
import '../screens/utilities/utilities_screen.dart';
import '../screens/utilities/calculator_dialog.dart';
import '../screens/recycle_bin/recycle_bin_screen.dart';
import '../screens/reports/reports_hub_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/device_management_screen.dart';

class VyaparDrawer extends StatelessWidget {
  const VyaparDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final firm = provider.activeFirm;
    final syncInfo = provider.syncCompanyInfo;
    final syncCompanyName = syncInfo['companyName'] ?? 'Sivan sports pro';
    final bool isDesktop = kIsWeb ||
        (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ||
        MediaQuery.of(context).size.width >= 800;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/testing_sales_app_logo.jpg',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            child: Text(
                              firm.name.isNotEmpty ? firm.name[0] : 'T',
                              style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(firm.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('+91 ${firm.phone.isNotEmpty ? firm.phone : "9876543210"}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                        tooltip: 'Switch Firm',
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmsManagementScreen()));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sync Company Badge (Image 8: Sivan sports pro)
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncCompanyScreen()));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sync: $syncCompanyName (Online)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Logged In User Profile Pill
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(isSwitchingUser: true),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            provider.currentUser?.isDesktop == true
                                ? Icons.desktop_windows
                                : Icons.phone_android,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.currentUser != null
                                  ? 'User: ${provider.currentUser!.name}'
                                  : 'Select Device Profile',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              provider.currentUser?.deviceSlot.toUpperCase().replaceAll('_', ' ') ?? 'LOGIN',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
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

            // Scrollable Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 1. SALE (Sheet 1 & 4)
                  _buildSectionHeader('SALE'),
                  _drawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Sale Invoice',
                    subtitle: 'Sales Bills & Invoicing',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen()));
                    },
                  ),
                  _drawerItem(
                    icon: Icons.point_of_sale_rounded,
                    title: isDesktop ? 'Desktop POS Counter' : 'Mobile POS',
                    subtitle: isDesktop ? 'Fast Touch-Grid Counter Billing' : 'Fast Touch-Grid Billing',
                    color: Colors.teal,
                    trailingBadge: 'NEW',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePosScreen()));
                    },
                  ),
                  _drawerItem(
                    icon: Icons.arrow_downward_rounded,
                    title: 'Payment In',
                    subtitle: 'Collect Customer Payment',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const AddPaymentInDialog());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.assignment_rounded,
                    title: 'Orders, Challan & Quotations',
                    subtitle: 'Estimates, Proformas, Challans',
                    color: Colors.orange.shade800,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersChallansScreen()));
                    },
                  ),

                  // 2. PURCHASE (Sheet 1 & 8)
                  _buildSectionHeader('PURCHASE'),
                  _drawerItem(
                    icon: Icons.shopping_bag_rounded,
                    title: 'Purchase Bills',
                    subtitle: 'Record Inward Stock Bills',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseManagementScreen(initialTabIndex: 0)));
                    },
                  ),
                  _drawerItem(
                    icon: Icons.arrow_upward_rounded,
                    title: 'Payment Out',
                    subtitle: 'Pay Vendors & Suppliers',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const AddPaymentOutDialog());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.replay_rounded,
                    title: 'Purchase Return (Debit Note)',
                    subtitle: 'Goods Return to Supplier',
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseManagementScreen(initialTabIndex: 2)));
                    },
                  ),

                  // 3. EXPENSES (Sheet 1 & 8)
                  _buildSectionHeader('EXPENSES'),
                  _drawerItem(
                    icon: Icons.money_off_rounded,
                    title: 'Expenses',
                    subtitle: 'Manufacturing, Petrol, Rent, Salary, Tea',
                    color: Colors.orange.shade900,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const AddExpenseDialog());
                    },
                  ),

                  // 4. CASH AND BANK (Sheet 1)
                  _buildSectionHeader('CASH AND BANK'),
                  _drawerItem(
                    icon: Icons.account_balance_rounded,
                    title: 'Cash & Bank Management',
                    subtitle: 'Bank, Cash in hand, GPay, Credit Card',
                    color: Colors.blue.shade800,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CashBankScreen()));
                    },
                  ),

                  // 5. MY ONLINE STORE (Sheet 1)
                  _buildSectionHeader('MY ONLINE STORE'),
                  _drawerItem(
                    icon: Icons.storefront_rounded,
                    title: 'My Online Store',
                    subtitle: 'Digital Catalog & WhatsApp Orders',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineStoreScreen()));
                    },
                  ),

                  // 6. REPORTS (Sheet 2, 3, 5, 6, 7)
                  _buildSectionHeader('REPORTS'),
                  _drawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'All Reports Hub',
                    subtitle: 'Day Book, GSTR 1/2/3B, P&L, Balance Sheet',
                    color: Colors.indigo,
                    trailingBadge: '40+ REPORTS',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen()));
                    },
                  ),

                  // 7. LOYALTY POINTS (Sheet 1)
                  _buildSectionHeader('LOYALTY POINTS'),
                  _drawerItem(
                    icon: Icons.star_rounded,
                    title: 'Customer Loyalty Points',
                    subtitle: 'Reward Points & Redemptions',
                    color: Colors.purple.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyPointsScreen()));
                    },
                  ),

                  // 8. LOANS (Sheet 5)
                  _drawerItem(
                    icon: Icons.request_quote_rounded,
                    title: 'Loans & Liabilities',
                    subtitle: 'Term loans, EMIs, repayments',
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen()));
                    },
                  ),

                  // 9. SYNC COMPANY (Sheet 8)
                  _buildSectionHeader('SYNC COMPANY'),
                  _drawerItem(
                    icon: Icons.cloud_sync_rounded,
                    title: 'Sync Company',
                    subtitle: 'Sync with Sivan sports pro',
                    color: const Color(0xFF0F766E),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncCompanyScreen()));
                    },
                  ),

                  // 10. BACK UP / RESTORE (Sheet 9)
                  _buildSectionHeader('BACK UP / RESTORE'),
                  _drawerItem(
                    icon: Icons.backup_rounded,
                    title: 'Back up / Restore',
                    subtitle: 'Auto backup, Phone, E-mail, Restore',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
                    },
                  ),

                  // 11. UTILITIES (Sheet 9)
                  _buildSectionHeader('UTILITIES'),
                  _drawerItem(
                    icon: Icons.build_circle_rounded,
                    title: 'Utilities & Business Tools',
                    subtitle: 'Verify Data, Calculator, Import, Tax Slab',
                    color: Colors.blueGrey.shade800,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilitiesScreen()));
                    },
                  ),
                  _drawerItem(
                    icon: Icons.calculate_rounded,
                    title: 'Quick Calculator',
                    subtitle: 'Open popup calculator',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const CalculatorDialog());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Recycle Bin',
                    subtitle: 'Restore deleted transactions',
                    color: Colors.red.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RecycleBinScreen()));
                    },
                  ),

                  // 12. MULTI-DEVICE LOGINS (Desktop Terminal vs Mobile Terminals)
                  _buildSectionHeader(isDesktop ? 'DESKTOP TERMINAL ACCESS' : 'MULTI-DEVICE ACCESS'),
                  _drawerItem(
                    icon: Icons.switch_account_rounded,
                    title: isDesktop ? 'Desktop Profile / PIN' : 'Switch Profile / Login',
                    subtitle: isDesktop ? 'Desktop Master Admin (Licensed Counter)' : '1 Desktop Admin + 3 Mobile Android Logins',
                    color: const Color(0xFFC62828),
                    trailingBadge: isDesktop ? 'DESKTOP' : '4 USERS',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen(isSwitchingUser: true)));
                    },
                  ),
                  _drawerItem(
                    icon: Icons.devices_other_rounded,
                    title: isDesktop ? 'Desktop Terminal System' : 'Device & Session Manager',
                    subtitle: isDesktop ? 'Licensed Master Counter Terminal' : '4 of 4 active licensed terminals',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceManagementScreen()));
                    },
                  ),

                  const Divider(),
                  _drawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'Company profile & tax configurations',
                    color: Colors.grey.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.8),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? trailingBadge,
  }) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      trailing: trailingBadge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              child: Text(trailingBadge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            )
          : null,
      onTap: onTap,
    );
  }
}

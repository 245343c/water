import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/month_year_wheel_picker.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/notifications/notifications_screen.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/dashboard/widgets/dashboard_home_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _month;
  static final _countFmt = NumberFormat('#,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  Future<void> _pickAdminImage(WaterPlantRepository repo) async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Update Profile Photo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Use camera',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF16A34A),
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Select existing photo',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (repo.adminImagePath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  title: Text(
                    'Remove Photo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await repo.clearAdminPhoto();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: choice,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null || !mounted) return;

    // Copy to app documents so the path persists through restarts
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/admin_profile.jpg');
    await dest.writeAsBytes(await picked.readAsBytes());

    if (mounted) await repo.uploadAdminPhoto(dest.path);
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearWheelPicker(
      context,
      initial: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _month) {
      setState(() => _month = picked);
      if (!mounted) return;
      final repo = context.read<WaterPlantRepository>();
      await repo.fetchDashboardStats(picked);
      await repo.refreshMonthlyBills(picked);
    }
  }

  void _showCustomerPicker(BuildContext context, WaterPlantRepository repo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CustomersColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Customer',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: repo.customers.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: CustomersColors.divider),
                itemBuilder: (_, i) {
                  final c = repo.customers[i];
                  final bg = CustomersColors
                      .avatarBgs[i % CustomersColors.avatarBgs.length];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: bg,
                      child: Text(
                        c.initials,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      c.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: CustomersColors.labelGrey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/customers/${c.id}/delivery');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WaterPlantRepository, NotificationRepository>(
      builder: (context, repo, notifications, _) {
        final ownerName =
            context.watch<AuthRepository>().currentUser?.ownerName ?? 'Owner';
        final stats = repo.dashboardStats(_month);
        final business = repo.settings.businessName;
        final today = DateTime.now();
        final todayDeliveries = repo.deliveriesOnDate(today);
        final todayUnits = todayDeliveries.fold<int>(
          0,
          (sum, d) => sum + d.normalQty + d.coolQty + d.bottleQty,
        );
        final pendingOrders = repo
            .ordersNewestFirst()
            .where((o) => o.status == OrderStatus.pending)
            .toList();
        final driverActivities =
            repo.drivers.map((driver) {
              final deliveries = todayDeliveries
                  .where((d) => d.driverId == driver.id)
                  .toList();
              final units = deliveries.fold<int>(
                0,
                (sum, d) => sum + d.normalQty + d.coolQty + d.bottleQty,
              );
              return DashboardDriverActivity(
                name: driver.name,
                deliveries: deliveries.length,
                units: units,
                active: driver.active,
              );
            }).toList()..sort((a, b) {
              final byDeliveries = b.deliveries.compareTo(a.deliveries);
              if (byDeliveries != 0) return byDeliveries;
              if (a.active != b.active) return a.active ? -1 : 1;
              return a.name.compareTo(b.name);
            });
        final pendingRequestCards = pendingOrders
            .map(
              (o) => DashboardPendingRequest(
                customerId: o.customerId,
                summary: o.cansSummary,
                createdAt: o.createdAt,
              ),
            )
            .toList();

        final overview = DashboardOverviewData(
          totalSales: CurrencyUtils.format(stats.totalSales),
          totalDeliveries: _countFmt.format(stats.totalDeliveries),
          totalUnits: _countFmt.format(stats.totalCans),
          activeCustomers: _countFmt.format(stats.activeCustomers),
          paidThisMonth: CurrencyUtils.format(stats.paidThisMonth),
          pendingAmount: CurrencyUtils.format(stats.pendingAmount),
        );

        void openAddDelivery() => _showCustomerPicker(context, repo);

        return Scaffold(
          backgroundColor: DashboardColors.bgTop,
          body: DashboardScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardHeader(
                    title: business,
                    ownerName: ownerName,
                    adminImagePath: repo.adminImagePath,
                    onAdminTap: () => _pickAdminImage(repo),
                    notificationCount: notifications.unreadCountForAdmin(),
                    onNotificationsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        DashboardQuickActions(
                          onAddDelivery: openAddDelivery,
                          onAddCustomer: () => context.push('/customers/add'),
                        ),
                        const SizedBox(height: 14),
                        DashboardOwnerSnapshot(
                          todayDeliveries: todayDeliveries.length,
                          todayUnits: todayUnits,
                          pendingRequests: pendingOrders.length,
                          onOrdersTap: () => context.go(AppRoutes.orders),
                        ),
                        const SizedBox(height: 14),
                        DashboardOperationsGrid(
                          left: DashboardPendingRequestsCard(
                            requests: pendingRequestCards,
                            onOpenOrders: () => context.go(AppRoutes.orders),
                            customerNameFor: (customerId) =>
                                repo.customerById(customerId)?.name ??
                                'Customer',
                          ),
                          right: DashboardDriverActivityCard(
                            activities: driverActivities,
                            activeDrivers: repo.drivers
                                .where((d) => d.active)
                                .length,
                            totalDrivers: repo.drivers.length,
                            onManageDrivers: () =>
                                context.push(AppRoutes.drivers),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DashboardOverviewCard(
                          month: _month,
                          onMonthTap: _pickMonth,
                          data: overview,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

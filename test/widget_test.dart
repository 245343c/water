import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sri_sai_ro_water/app.dart';
import 'package:sri_sai_ro_water/data/models/order_status.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/customer_home_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_shop_screen.dart';
import 'package:sri_sai_ro_water/features/shell/customer_shell.dart';

void main() {
  test('App widget can be created', () {
    expect(const SriSaiRoWaterApp(), isA<SriSaiRoWaterApp>());
  });

  testWidgets('Customer home renders linked mock shop', (tester) async {
    final auth = AuthRepository();
    final repo = WaterPlantRepository();
    auth.requestCustomerOtp('9876543210');
    final error = auth.verifyCustomerOtp(phone: '9876543210', otp: '123456');
    expect(error, isNull);

    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);
    auth.markCustomerOnboardingComplete(user.id, name: 'Lakshmi Devi');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: repo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const CustomerHomeScreen(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Sri Sai RO Water Plant'), findsOneWidget);
    expect(find.text('Lakshmi Devi'), findsOneWidget);
  });

  testWidgets('Customer shell renders home tab body', (tester) async {
    final auth = AuthRepository();
    final repo = WaterPlantRepository();
    auth.requestCustomerOtp('9876543210');
    final error = auth.verifyCustomerOtp(phone: '9876543210', otp: '123456');
    expect(error, isNull);

    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);
    auth.markCustomerOnboardingComplete(user.id, name: 'Lakshmi Devi');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: repo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    CustomerShell(location: Uri.parse('/customer/home')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(CustomerHomeScreen), findsOneWidget);
    expect(find.text('Lakshmi Devi'), findsOneWidget);
    expect(
      find.text('You can order only from your linked plant'),
      findsNothing,
    );
    expect(find.text('You can order from your linked plant'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pump();

    expect(find.text('Sri Sai RO Water Plant'), findsOneWidget);
  });

  testWidgets('Customer home renders multiple linked monthly plants', (
    tester,
  ) async {
    final auth = AuthRepository();
    final repo = WaterPlantRepository();
    auth.requestCustomerOtp('9632580741');
    final error = auth.verifyCustomerOtp(phone: '9632580741', otp: '123456');
    expect(error, isNull);

    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);
    auth.markCustomerOnboardingComplete(user.id, name: 'Abi');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: repo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const CustomerHomeScreen(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('4 linked water plants'), findsOneWidget);
    expect(find.text('You can order from your linked plants'), findsOneWidget);
    expect(find.text('Sri Sai RO Water Plant'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump();

    expect(find.text('Aqua Pure RO Center'), findsOneWidget);
  });

  testWidgets('Customer shop detail sends a water request', (tester) async {
    final auth = AuthRepository();
    final repo = WaterPlantRepository();
    final notifications = NotificationRepository();
    auth.requestCustomerOtp('9876543210');
    final error = auth.verifyCustomerOtp(phone: '9876543210', otp: '123456');
    expect(error, isNull);

    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);
    auth.markCustomerOnboardingComplete(user.id, name: 'Lakshmi Devi');
    final before = repo.ordersForAppUser(user.id).length;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: repo),
          ChangeNotifierProvider.value(value: notifications),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const CustomerShopScreen(shopId: 'shop-1'),
              ),
              GoRoute(
                path: '/customer/orders',
                builder: (context, state) =>
                    const Scaffold(body: Text('Requests page')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Add items'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Normal RO can'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(find.text('Send request'), findsOneWidget);

    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    final after = repo.ordersForAppUser(user.id).length;
    expect(after, before + 1);
    expect(repo.ordersForAppUser(user.id).first.normalQty, greaterThan(0));
    expect(find.text('Requests page'), findsOneWidget);
  });

  testWidgets('Monthly customer orders tab shows request status cards', (
    tester,
  ) async {
    final auth = AuthRepository();
    final repo = WaterPlantRepository();
    auth.requestCustomerOtp('9876543210');
    final error = auth.verifyCustomerOtp(phone: '9876543210', otp: '123456');
    expect(error, isNull);

    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);
    auth.markCustomerOnboardingComplete(user.id, name: 'Lakshmi Devi');
    final linkedCustomerId = repo.crmCustomerIdForAppUser(user.id)!;
    final month = DateTime(DateTime.now().year, DateTime.now().month);
    final beforeStats = repo.monthlyStatsForCustomer(linkedCustomerId, month);

    final order = await repo.placeAppOrder(
      shopId: 'shop-1',
      appUserId: user.id,
      normalQty: 2,
      coolQty: 0,
      customerNote: 'Deliver after 6 PM',
    );
    await repo.respondToOrder(
      order.id,
      OrderStatus.accepted,
      adminResponse: 'Confirmed for evening delivery',
    );
    await repo.addDelivery(
      customerId: order.customerId,
      date: DateTime.now(),
      normalQty: 2,
    );
    final afterStats = repo.monthlyStatsForCustomer(linkedCustomerId, month);
    expect(afterStats.normalCans, beforeStats.normalCans + 2);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: repo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    CustomerShell(location: Uri.parse('/customer/orders')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('WATER REQUESTS'), findsOneWidget);
    expect(find.text('Sri Sai RO Water Plant'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('2 Normal'), findsOneWidget);
    expect(
      find.text('Delivered and added to your monthly account.'),
      findsOneWidget,
    );
  });

  test('Multi-plant customer request stays with selected plant account', () async {
    final auth = AuthRepository();
    final repo = WaterPlantRepository();
    auth.requestCustomerOtp('9632580741');
    final error = auth.verifyCustomerOtp(phone: '9632580741', otp: '123456');
    expect(error, isNull);

    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);
    auth.markCustomerOnboardingComplete(user.id, name: 'Abi');

    final order = await repo.placeAppOrder(
      shopId: 'shop-2',
      appUserId: user.id,
      normalQty: 1,
      coolQty: 0,
    );

    expect(order.shopId, 'shop-2');
    expect(order.customerId, isNot('c1'));
    expect(repo.shopIdForCustomer(order.customerId), 'shop-2');
    expect(repo.ordersForAppUser(user.id).first.id, order.id);
  });

  test(
    'Pending customer request can be edited and cancelled before admin accepts',
    () {
      final auth = AuthRepository();
      final repo = WaterPlantRepository();
      auth.requestCustomerOtp('9876543210');
      final error = auth.verifyCustomerOtp(phone: '9876543210', otp: '123456');
      expect(error, isNull);

      final user = auth.currentUser!;
      repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);

      final order = repo.placeAppOrder(
        shopId: 'shop-1',
        appUserId: user.id,
        normalQty: 1,
        coolQty: 0,
      );
      repo.updatePendingAppOrder(
        orderId: order.id,
        appUserId: user.id,
        normalQty: 3,
        coolQty: 1,
        customerNote: 'Updated request',
      );

      final edited = repo.orderById(order.id)!;
      expect(edited.normalQty, 3);
      expect(edited.coolQty, 1);
      expect(edited.customerNote, 'Updated request');

      repo.cancelPendingAppOrder(orderId: order.id, appUserId: user.id);
      expect(repo.orderById(order.id)!.status, OrderStatus.cancelled);
    },
  );

  test('Driver accepted and started states are tracked for customer order', () {
    final auth = AuthRepository();
    final repo = WaterPlantRepository();
    auth.requestCustomerOtp('9876543210');
    final error = auth.verifyCustomerOtp(phone: '9876543210', otp: '123456');
    expect(error, isNull);

    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);
    final order = repo.placeAppOrder(
      shopId: 'shop-1',
      appUserId: user.id,
      normalQty: 1,
      coolQty: 0,
    );
    repo.respondToOrder(order.id, OrderStatus.accepted);

    repo.driverAcceptOrder(orderId: order.id, driverId: 'driver-1');
    expect(repo.orderById(order.id)!.isDriverAssigned, isTrue);
    expect(repo.orderById(order.id)!.isOutForDelivery, isFalse);

    repo.driverStartDelivery(orderId: order.id, driverId: 'driver-1');
    expect(repo.orderById(order.id)!.isOutForDelivery, isTrue);
  });
}

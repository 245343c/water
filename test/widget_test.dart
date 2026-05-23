import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sri_sai_ro_water/app.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/customer_home_screen.dart';
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
                    const CustomerShell(location: '/customer/home'),
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
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pump();

    expect(find.text('Sri Sai RO Water Plant'), findsOneWidget);
  });
}

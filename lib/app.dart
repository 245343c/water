import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/language_controller.dart';
import 'package:sri_sai_ro_water/core/services/delivery_recording_service.dart';
import 'package:sri_sai_ro_water/core/services/admin_dispatch_service.dart';
import 'package:sri_sai_ro_water/core/services/order_workflow_service.dart';
import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
import 'package:sri_sai_ro_water/core/theme/app_theme.dart';
import 'package:sri_sai_ro_water/data/models/app_user.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class SriSaiRoWaterApp extends StatefulWidget {
  const SriSaiRoWaterApp({super.key});

  @override
  State<SriSaiRoWaterApp> createState() => _SriSaiRoWaterAppState();
}

class _SriSaiRoWaterAppState extends State<SriSaiRoWaterApp> {
  late final AuthRepository _auth;
  late final WaterPlantRepository _repository;
  late final NotificationRepository _notifications;
  late final LanguageController _language;
  late final PushNotificationService _push;
  late final DeliveryRecordingService _deliveryRecording;
  late final OrderWorkflowService _orderWorkflow;
  late final AdminDispatchService _adminDispatch;
  late final GoRouter _router;
  String? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    _auth = AuthRepository();
    _repository = WaterPlantRepository();
    _notifications = NotificationRepository();
    _language = LanguageController();
    _push = PushNotificationService();
    _deliveryRecording = DeliveryRecordingService(
      plant: _repository,
      notifications: _notifications,
      push: _push,
      auth: _auth,
    );
    _orderWorkflow = OrderWorkflowService(
      plant: _repository,
      notifications: _notifications,
    );
    _adminDispatch = AdminDispatchService(
      plant: _repository,
      notifications: _notifications,
    );
    _router = createAppRouter(_auth);
    _push.initialize();
    _auth.addListener(_loadRepositoryForAuthUser);
    _loadRepositoryForAuthUser();
  }

  void _loadRepositoryForAuthUser() {
    final user = _auth.currentUser;
    final userId = user?.id;
    if (_lastLoadedUserId == userId) return;
    _lastLoadedUserId = userId;
    unawaited(_syncDataForUser(user));
  }

  Future<void> _syncDataForUser(AppUser? user) async {
    await _repository.loadFirebaseDataForUser(user);
    await _notifications.syncForUser(user, _repository);
    await _language.syncForUser(user);
    await _push.syncForUser(user);
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.removeListener(_loadRepositoryForAuthUser);
    _auth.dispose();
    _repository.dispose();
    _notifications.dispose();
    _language.dispose();
    _push.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _repository),
        ChangeNotifierProvider.value(value: _notifications),
        ChangeNotifierProvider.value(value: _language),
        Provider.value(value: _push),
        Provider.value(value: _deliveryRecording),
        Provider.value(value: _orderWorkflow),
        Provider.value(value: _adminDispatch),
      ],
      child: Consumer<LanguageController>(
        builder: (context, language, _) {
          return MaterialApp.router(
            title: 'Sri Sai RO Water',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: language.locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) {
              return Consumer<WaterPlantRepository>(
                builder: (context, repo, _) {
                  return Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      if (repo.isFirebaseLoading)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Colors.white,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

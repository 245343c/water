import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/api/api_config.dart';
import 'package:sri_sai_ro_water/core/services/delivery_recording_service.dart';
import 'package:sri_sai_ro_water/core/services/order_workflow_service.dart';
import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
import 'package:sri_sai_ro_water/core/theme/app_theme.dart';
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
  late final PushNotificationService _push;
  late final DeliveryRecordingService _deliveryRecording;
  late final OrderWorkflowService _orderWorkflow;
  late final GoRouter _router;
  bool _backendReady = !useBackend;

  @override
  void initState() {
    super.initState();
    _auth = AuthRepository();
    _repository = WaterPlantRepository();
    _notifications = NotificationRepository();
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
      push: _push,
    );
    _router = createAppRouter(_auth, _repository);
    _push.initialize();

    if (useBackend) {
      _auth.ensureSessionRestored().then((_) async {
        if (_auth.isAuthenticated) {
          await Future.wait([
            _repository.loadFromBackend(role: _auth.currentUser?.role),
            _notifications.loadFromBackend(),
          ]);
        }
        if (mounted) setState(() => _backendReady = true);
      }).catchError((_) {
        if (mounted) setState(() => _backendReady = true);
      });
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _repository.dispose();
    _notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_backendReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to server...'),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _repository),
        ChangeNotifierProvider.value(value: _notifications),
        Provider.value(value: _push),
        Provider.value(value: _deliveryRecording),
        Provider.value(value: _orderWorkflow),
      ],
      child: MaterialApp.router(
        title: 'Sri Sai RO Water',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}

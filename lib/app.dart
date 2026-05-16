import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/theme/app_theme.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class SriSaiRoWaterApp extends StatefulWidget {
  const SriSaiRoWaterApp({super.key});

  @override
  State<SriSaiRoWaterApp> createState() => _SriSaiRoWaterAppState();
}

class _SriSaiRoWaterAppState extends State<SriSaiRoWaterApp> {
  late final WaterPlantRepository _repository;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _repository = WaterPlantRepository();
    _router = createAppRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _repository,
      child: MaterialApp.router(
        title: 'Sri Sai RO Water',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}

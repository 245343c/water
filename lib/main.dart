import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sri_sai_ro_water/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SriSaiRoWaterApp());
}

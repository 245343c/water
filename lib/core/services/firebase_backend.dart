import 'package:cloud_functions/cloud_functions.dart';

abstract final class FirebaseBackend {
  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: 'asia-south1');
}

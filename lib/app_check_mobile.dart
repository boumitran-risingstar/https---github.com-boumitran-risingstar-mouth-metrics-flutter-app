import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> activateAppCheck() {
  return FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
}

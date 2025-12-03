
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_app_check_web/firebase_app_check_web.dart';

Future<void> activateAppCheck() async {
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaEnterpriseProvider('6LcrwQ8pAAAAAPB_454pL0Wk_2b20-c2dJ2e1g-8'),
  );
}

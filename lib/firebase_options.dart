// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9c2PLSy-QFV9L3TDTH7GtJS-gjlAdAhE',
    appId: '1:440615029186:android:f3461a4ff04a54816f2e5b',
    messagingSenderId: '440615029186',
    projectId: 'takenow-22ee7',
    storageBucket: 'takenow-22ee7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBA6rUdFkcSeXvKlFOHJlWCN4BUWoaM-94',
    appId: '1:440615029186:ios:7bea33df7d13592e6f2e5b',
    messagingSenderId: '440615029186',
    projectId: 'takenow-22ee7',
    storageBucket: 'takenow-22ee7.appspot.com',
    androidClientId:
        '440615029186-0sbu42ubbh4c25ien5nv08brotd833s0.apps.googleusercontent.com',
    iosClientId:
        '440615029186-2sthj3e3fo5epmj8beavrt0kn7e2d8on.apps.googleusercontent.com',
    iosBundleId: 'com.example.takenow',
  );
}

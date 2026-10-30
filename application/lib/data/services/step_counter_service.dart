import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';

enum StepPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

class StepCounterService {
  static const MethodChannel _permissionChannel =
      MethodChannel('nutriai/permissions');

  Future<StepPermissionStatus> requestPermission() async {
    if (kIsWeb) return StepPermissionStatus.unsupported;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await _permissionChannel
            .invokeMethod<String>('requestActivityRecognitionPermission');
        switch (status) {
          case 'granted':
            return StepPermissionStatus.granted;
          case 'permanentlyDenied':
            return StepPermissionStatus.permanentlyDenied;
          case 'denied':
            return StepPermissionStatus.denied;
          default:
            return StepPermissionStatus.denied;
        }
      } on PlatformException {
        return StepPermissionStatus.denied;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return StepPermissionStatus.granted;
    }

    return StepPermissionStatus.unsupported;
  }

  Stream<int> stepCountStream() {
    return Pedometer.stepCountStream.map((event) => event.steps);
  }
}

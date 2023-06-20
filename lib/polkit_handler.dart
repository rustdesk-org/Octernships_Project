import 'dart:async';
import 'package:flutter/services.dart';

Future<bool> executePolkitAction() async {
  const platform = MethodChannel('manglam');

  try {
    final result = await platform.invokeMethod('executePolkitAction');
    return result == 'success';
  } on PlatformException catch (e) {
    print('Failed to execute Polkit action: ${e.message}');
    return false;
  }
}

package com.example.flutter_rust_bridge_template

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
        private val CHANNEL = "manglam"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    if (call.method == "executePolkitAction") {
                        // Implement your Polkit action execution here
                        // Return 'success' if Polkit action succeeds, otherwise return 'failure'
                        result.success("success")
                    } else {
                        result.notImplemented()
                    }
                }
    }
}

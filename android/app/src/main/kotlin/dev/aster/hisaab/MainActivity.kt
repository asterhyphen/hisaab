package dev.aster.hisaab

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "hisaab/widget"
    private var pendingAction: String? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingAction = pendingAction ?: parseAction(intent)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialAction" -> {
                        result.success(pendingAction)
                        pendingAction = null
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = parseAction(intent)
        if (action == null) return
        if (methodChannel == null) {
            pendingAction = action
            return
        }
        methodChannel?.invokeMethod("onWidgetAction", action)
    }

    private fun parseAction(intent: Intent?): String? {
        val value = intent?.data?.lastPathSegment?.lowercase() ?: return null
        return when (value) {
            "add", "plus" -> "add"
            "subtract", "minus", "remove" -> "subtract"
            else -> null
        }
    }
}

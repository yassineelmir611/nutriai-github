package com.example.nutriai

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val permissionChannelName = "nutriai/permissions"
    private val activityRecognitionRequestCode = 2026
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permissionChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestActivityRecognitionPermission" -> requestActivityRecognitionPermission(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestActivityRecognitionPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success("granted")
            return
        }

        val permission = Manifest.permission.ACTIVITY_RECOGNITION
        val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            result.success("granted")
            return
        }

        if (pendingPermissionResult != null) {
            result.error("busy", "Another permission request is already running.", null)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(this, arrayOf(permission), activityRecognitionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != activityRecognitionRequestCode) return

        val callback = pendingPermissionResult ?: return
        pendingPermissionResult = null

        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            callback.success("granted")
            return
        }

        val canAskAgain = ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.ACTIVITY_RECOGNITION)
        callback.success(if (canAskAgain) "denied" else "permanentlyDenied")
    }
}

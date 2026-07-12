package app.dyshi.breathin

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity — требование audio_service: связывает Flutter-движок
// с медиа-сервисом (фоновое воспроизведение таймлайна сессии, ПЛАН §3.3).
// launchMode="singleTask" в манифесте обязателен для deep link dyshi://auth:
// иначе возврат из браузера создаёт второй инстанс и вход не завершается.
class MainActivity : AudioServiceActivity() {
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestNotifications" -> requestNotifications(result)
                    else -> result.notImplemented()
                }
            }
    }

    /// Разрешение на уведомления (Android 13+): без него медиа-уведомление
    /// сессии не показывается. До 13 разрешения не существует → true.
    private fun requestNotifications(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33) {
            result.success(true)
            return
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingResult?.success(false)
        pendingResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_NOTIFICATIONS)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_NOTIFICATIONS) {
            pendingResult?.success(
                grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED,
            )
            pendingResult = null
        }
    }

    private companion object {
        const val CHANNEL = "app.dyshi.breathin/permissions"
        const val REQ_NOTIFICATIONS = 4801
    }
}

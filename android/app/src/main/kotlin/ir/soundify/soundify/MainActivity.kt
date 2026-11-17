package ir.soundify.soundify

import android.os.Build
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceFragmentActivity() {
    private val channelName = "ir.soundify/device_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isRooted" -> result.success(isRooted())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isRooted(): Boolean {
        val tags = Build.TAGS
        if (tags != null && tags.contains("test-keys")) return true

        val suspiciousPaths = listOf(
            "/system/app/Superuser.apk",
            "/system/app/SuperSU.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/bin/su",
            "/data/local/xbin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/su/bin/su",
            "/magisk/.core/bin/su",
        )
        for (path in suspiciousPaths) {
            try {
                if (File(path).exists()) return true
            } catch (_: Exception) {
                // Ignore access errors; continue checking.
            }
        }

        val buildProps = listOf(
            "ro.debuggable",
            "ro.secure",
            "ro.build.selinux",
        )
        // A debuggable production build is a strong root/unsafe-ROM signal.
        try {
            val process = ProcessBuilder("/system/bin/getprop", "ro.debuggable").start()
            val value = process.inputStream.bufferedReader().use { it.readText() }.trim()
            process.waitFor()
            if (value == "1") return true
        } catch (_: Exception) {
            // Not available on all devices.
        }
        return buildProps.any { prop ->
            try {
                val process = ProcessBuilder("/system/bin/getprop", prop).start()
                val value = process.inputStream.bufferedReader().use { it.readText() }.trim()
                process.waitFor()
                prop == "ro.secure" && value == "0"
            } catch (_: Exception) {
                false
            }
        }
    }
}

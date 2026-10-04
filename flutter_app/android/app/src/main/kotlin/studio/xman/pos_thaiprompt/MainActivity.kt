package studio.xman.pos_thaiprompt

import android.app.Presentation
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.FileProvider
import java.io.File

/**
 * Thai Prompt POS — customer-facing second screen on dual-display Android POS
 * terminals (Sunmi T2/D2, iMin, …) via the standard Presentation API.
 *
 * Main engine channel "tp/second_screen":
 *   displays → [{id, name, w, h}] presentation-capable displays
 *   show {displayId} · hide · state {json}
 * The second display runs its own Flutter engine on the Dart entrypoint
 * `customerDisplayMain`, which reads snapshots from channel
 * "tp/customer_display" (getState + pushed "state" calls).
 *
 * Channel "tp/installer": installApk {filePath} — opens the system installer
 * for an update the Dart side already downloaded from xman4289.com and
 * verified (size + SHA-256), shared through the app's FileProvider.
 */
class MainActivity : FlutterActivity() {
    private var presentation: CustomerPresentation? = null
    private var secondEngine: FlutterEngine? = null
    private var secondChannel: MethodChannel? = null
    private var lastState: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tp/second_screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "displays" -> result.success(listDisplays())
                    "show" -> {
                        val id = call.argument<Int>("displayId")
                        result.success(show(id))
                    }
                    "hide" -> {
                        hide()
                        result.success(null)
                    }
                    "isShowing" -> result.success(presentation?.isShowing == true)
                    "state" -> {
                        lastState = (call.arguments as? String) ?: ""
                        secondChannel?.invokeMethod("state", lastState)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tp/installer")
            .setMethodCallHandler { call, result ->
                if (call.method != "installApk") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("filePath")
                if (path == null) {
                    result.error("INVALID_ARG", "filePath is required", null)
                    return@setMethodCallHandler
                }
                installApk(path, result)
            }
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            // only files this app wrote into its own cache
            if (!file.exists() || !file.canonicalPath.startsWith(cacheDir.canonicalPath)) {
                result.error("FILE_NOT_FOUND", "update file missing", null)
                return
            }
            val uri = FileProvider.getUriForFile(this, "$packageName.update_provider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }

    private fun displayManager(): DisplayManager =
        getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

    private fun listDisplays(): List<Map<String, Any>> =
        displayManager().getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION).map { d ->
            val m = android.util.DisplayMetrics()
            @Suppress("DEPRECATION")
            d.getRealMetrics(m)
            mapOf("id" to d.displayId, "name" to (d.name ?: "Display ${d.displayId}"),
                "w" to m.widthPixels, "h" to m.heightPixels)
        }

    private fun show(displayId: Int?): Boolean {
        val displays = displayManager().getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
        if (displays.isEmpty()) return false
        val target: Display = displays.firstOrNull { it.displayId == displayId } ?: displays[0]
        if (presentation?.isShowing == true && presentation?.display?.displayId == target.displayId) return true
        hide()

        val engine = secondEngine ?: FlutterEngine(applicationContext).also { e ->
            val loader = FlutterInjector.instance().flutterLoader()
            e.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "customerDisplayMain")
            )
            secondChannel = MethodChannel(e.dartExecutor.binaryMessenger, "tp/customer_display").also { ch ->
                ch.setMethodCallHandler { call, result ->
                    if (call.method == "getState") result.success(lastState) else result.notImplemented()
                }
            }
            secondEngine = e
        }
        return try {
            presentation = CustomerPresentation(this, target, engine).also { it.show() }
            engine.lifecycleChannel.appIsResumed()
            if (lastState.isNotEmpty()) secondChannel?.invokeMethod("state", lastState)
            true
        } catch (e: WindowManager.InvalidDisplayException) {
            presentation = null
            false
        }
    }

    private fun hide() {
        presentation?.dismiss()
        presentation = null
    }

    override fun onResume() {
        super.onResume()
        secondEngine?.lifecycleChannel?.appIsResumed()
    }

    override fun onDestroy() {
        hide()
        secondEngine?.destroy()
        secondEngine = null
        secondChannel = null
        super.onDestroy()
    }
}

/** A Presentation that hosts a FlutterView bound to the second engine. */
class CustomerPresentation(
    context: Context,
    display: Display,
    private val engine: FlutterEngine,
) : Presentation(context, display) {
    private var view: FlutterView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val v = FlutterView(context)
        v.attachToFlutterEngine(engine)
        view = v
        setContentView(v)
    }

    override fun onStop() {
        view?.detachFromFlutterEngine()
        view = null
        super.onStop()
    }
}

package com.restpod.hud

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.ArrayDeque
import java.time.Instant
import java.util.UUID

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UnityRuntimeBridge.METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(UnityRuntimeBridge.isAvailable())
                "prepare" -> result.success(UnityRuntimeBridge.prepare(this))
                "send" -> {
                    val encoded = call.arguments as? String
                    if (encoded == null) {
                        result.error("invalid_command", "Unity command must be a JSON string", null)
                    } else if (UnityRuntimeBridge.send(encoded)) {
                        result.success(null)
                    } else {
                        result.error("unity_unavailable", "Unity Library is not installed", null)
                    }
                }
                "dispose" -> {
                    UnityRuntimeBridge.disposeSession()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UnityRuntimeBridge.EVENT_CHANNEL,
        ).setStreamHandler(UnityRuntimeBridge)
    }
}

object UnityRuntimeBridge : EventChannel.StreamHandler {
    const val METHOD_CHANNEL = "com.restpod.hud/unity"
    const val EVENT_CHANNEL = "com.restpod.hud/unity_events"
    private const val UNITY_PLAYER_CLASS = "com.unity3d.player.UnityPlayer"
    private const val UNITY_HOST_ACTIVITY_CLASS =
        "com.restpod.hud.StopwatchUnityActivity"
    private const val BRIDGE_OBJECT = "StopwatchUnityBridge"
    private const val BRIDGE_METHOD = "HandleEnvelope"

    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingCommands = ArrayDeque<String>()
    private var eventSink: EventChannel.EventSink? = null
    @Volatile private var runtimeReady = false
    @Volatile private var activeSessionId = ""

    fun isAvailable(): Boolean {
        // The checked-in Unity export currently contains arm64 native code
        // only. The app also packages x86_64 Flutter libraries so UI tests can
        // run on the Android emulator, but launching Unity there would load
        // UnityPlayerActivity without libmain.so and later crash during its
        // native cleanup. Do not start the host unless this process can use
        // the exported runtime ABI.
        if (Build.SUPPORTED_ABIS.none { it == "arm64-v8a" }) return false
        return runCatching {
            Class.forName(UNITY_PLAYER_CLASS)
            Class.forName(UNITY_HOST_ACTIVITY_CLASS)
        }.isSuccess
    }

    fun prepare(activity: Activity): Boolean {
        if (!isAvailable()) return false
        return runCatching {
            // A warm Unity Activity may still be paused while it is reordered
            // to the foreground. Queue the next session snapshot until that
            // Activity explicitly re-announces readiness from onResume().
            runtimeReady = false
            val hostActivity = Class.forName(UNITY_HOST_ACTIVITY_CLASS)
            val intent = Intent(activity, hostActivity).apply {
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            activity.startActivity(intent)
        }.isSuccess
    }

    fun send(encoded: String): Boolean {
        if (!isAvailable()) return false
        runCatching {
            activeSessionId = JSONObject(encoded).optString("session_id", activeSessionId)
        }
        synchronized(pendingCommands) {
            if (!runtimeReady) {
                pendingCommands.addLast(encoded)
                return true
            }
        }
        return sendNow(encoded)
    }

    fun disposeSession() {
        synchronized(pendingCommands) { pendingCommands.clear() }
        activeSessionId = ""
        runCatching {
            Class.forName(UNITY_HOST_ACTIVITY_CLASS)
                .getMethod("requestReturnToFlutter")
                .invoke(null)
        }
    }

    @JvmStatic
    fun onRuntimeUnloaded() {
        runtimeReady = false
        activeSessionId = ""
        synchronized(pendingCommands) { pendingCommands.clear() }
    }

    @JvmStatic
    fun emitHostEvent(type: String) {
        val encoded = JSONObject().apply {
            put("event_id", UUID.randomUUID().toString().replace("-", ""))
            put("session_id", activeSessionId)
            put("occurred_at_utc", Instant.now().toString())
            put("protocol_version", "1.0")
            put("type", type)
            put("payload", JSONObject())
        }.toString()
        emitEvent(encoded)
    }

    @JvmStatic
    fun emitEvent(encoded: String) {
        mainHandler.post {
            if (runCatching { JSONObject(encoded).optString("type") }.getOrNull() == "unity_ready") {
                runtimeReady = true
                runCatching {
                    Class.forName(UNITY_HOST_ACTIVITY_CLASS)
                        .getMethod("onRuntimeReady")
                        .invoke(null)
                }
                flushPendingCommands()
            }
            eventSink?.success(encoded)
        }
    }

    private fun flushPendingCommands() {
        while (true) {
            val encoded = synchronized(pendingCommands) {
                if (pendingCommands.isEmpty()) null else pendingCommands.removeFirst()
            } ?: return
            if (!sendNow(encoded)) {
                synchronized(pendingCommands) { pendingCommands.addFirst(encoded) }
                runtimeReady = false
                return
            }
        }
    }

    private fun sendNow(encoded: String): Boolean = runCatching {
        val player = Class.forName(UNITY_PLAYER_CLASS)
        val sendMessage = player.getMethod(
            "UnitySendMessage",
            String::class.java,
            String::class.java,
            String::class.java,
        )
        sendMessage.invoke(null, BRIDGE_OBJECT, BRIDGE_METHOD, encoded)
    }.isSuccess

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}

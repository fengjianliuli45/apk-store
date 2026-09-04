package com.restpod.hud

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import com.unity3d.player.UnityPlayerActivity

/** Full-screen, single-instance host for the exported Unity runtime. */
class StopwatchUnityActivity : UnityPlayerActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var unloadRequested = false
    private var warmResumePending = false
    private var predictiveBackCallback: OnBackInvokedCallback? = null
    private val startupTimeout = Runnable {
        if (!unloadRequested) {
            UnityRuntimeBridge.emitHostEvent("render_fatal")
            unloadAndReturn()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        current = this
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            predictiveBackCallback = OnBackInvokedCallback { handleBack() }.also {
                onBackInvokedDispatcher.registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_OVERLAY,
                    it,
                )
            }
        }
        mainHandler.postDelayed(startupTimeout, STARTUP_TIMEOUT_MS)
    }

    override fun onNewIntent(intent: Intent) {
        current = this
        unloadRequested = false
        warmResumePending = runtimeInitialized
        super.onNewIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        if (!warmResumePending) return
        warmResumePending = false
        // UnityPlayerActivity resumes the player in super.onResume(). Give its
        // render thread one UI-loop turn before Flutter flushes queued
        // UnitySendMessage calls for the new session.
        mainHandler.postDelayed(
            { UnityRuntimeBridge.emitHostEvent("unity_ready") },
            WARM_RESUME_READY_DELAY_MS,
        )
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onBackPressed() {
        handleBack()
    }

    override fun onPause() {
        if (!unloadRequested) UnityRuntimeBridge.emitHostEvent("host_interrupted")
        super.onPause()
    }

    override fun onUnityPlayerUnloaded() {
        runtimeInitialized = false
        UnityRuntimeBridge.onRuntimeUnloaded()
        showFlutter()
        finish()
    }

    override fun onUnityPlayerQuitted() {
        runtimeInitialized = false
        UnityRuntimeBridge.onRuntimeUnloaded()
        showFlutter()
        finish()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(startupTimeout)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            predictiveBackCallback?.let {
                onBackInvokedDispatcher.unregisterOnBackInvokedCallback(it)
            }
            predictiveBackCallback = null
        }
        if (current === this) current = null
        super.onDestroy()
    }

    private fun handleBack() {
        showFlutter()
        UnityRuntimeBridge.emitHostEvent("host_back")
    }

    private fun unloadAndReturn() {
        if (unloadRequested) return
        unloadRequested = true
        showFlutter()
        mUnityPlayer.unload()
    }

    private fun showFlutter() {
        startActivity(Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        })
    }

    companion object {
        @Volatile private var current: StopwatchUnityActivity? = null
        @Volatile private var runtimeInitialized = false

        /** Called reflectively so Flutter-only builds do not link Unity classes. */
        @JvmStatic
        fun requestReturnToFlutter(): Boolean {
            val activity = current ?: return false
            // Keep the Unity player warm between training route entries.
            // Calling UnityPlayer.unload() and immediately reordering the same
            // Activity can make UnityPlayer terminate the shared app process.
            activity.runOnUiThread { activity.showFlutter() }
            return true
        }

        @JvmStatic
        fun onRuntimeReady() {
            val activity = current ?: return
            runtimeInitialized = true
            activity.mainHandler.removeCallbacks(activity.startupTimeout)
        }

        private const val STARTUP_TIMEOUT_MS = 20_000L
        private const val WARM_RESUME_READY_DELAY_MS = 750L
    }
}

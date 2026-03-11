package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val SCREEN_LOCK_CHANNEL = "com.example.expense_tracker/screen_lock"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var screenReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_LOCK_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    registerScreenReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterScreenReceiver()
                    eventSink = null
                }
            })
    }

    private fun registerScreenReceiver() {
        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    // Screen turned OFF (power button pressed / phone went to sleep)
                    Intent.ACTION_SCREEN_OFF -> eventSink?.success("screen_locked")
                    // User actively unlocked the device (dismissed lock screen)
                    Intent.ACTION_USER_PRESENT -> eventSink?.success("screen_unlocked")
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)
    }

    private fun unregisterScreenReceiver() {
        screenReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        screenReceiver = null
    }

    override fun onDestroy() {
        unregisterScreenReceiver()
        super.onDestroy()
    }
}

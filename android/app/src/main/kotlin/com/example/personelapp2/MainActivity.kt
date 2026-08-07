package com.example.personelapp2

import android.app.Activity
import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "NizamBackup"
        private const val CHANNEL = "nizam/backup_files"
        private const val CREATE_BACKUP_REQUEST = 7101
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "saveBackup") {
            result.notImplemented()
            return
        }
        if (pendingResult != null) {
            result.error("SAVE_IN_PROGRESS", "Başka bir yedek kaydetme işlemi sürüyor.", null)
            return
        }
        val name = call.argument<String>("name")
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
        val bytes = call.argument<ByteArray>("bytes")
        if (name.isNullOrBlank() || bytes == null) {
            result.error("INVALID_ARGUMENTS", "Yedek dosyası bilgileri eksik.", null)
            return
        }

        pendingResult = result
        pendingBytes = bytes
        Log.d(TAG, "Opening save dialog for ${bytes.size} backup bytes")
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, name)
        }
        try {
            startActivityForResult(intent, CREATE_BACKUP_REQUEST)
        } catch (error: Exception) {
            clearPending()
            result.error("SAVE_DIALOG_FAILED", error.message, null)
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != CREATE_BACKUP_REQUEST) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult
        val bytes = pendingBytes
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            clearPending()
            result?.success(false)
            return
        }
        try {
            val bytesToWrite = requireNotNull(bytes) { "Yedek verisi bulunamadı." }
            contentResolver.openOutputStream(data.data!!, "w").use { stream ->
                requireNotNull(stream) { "Seçilen dosya açılamadı." }
                stream.write(bytesToWrite)
                stream.flush()
            }
            Log.d(TAG, "Wrote ${bytesToWrite.size} backup bytes to ${data.data}")
            clearPending()
            result?.success(true)
        } catch (error: Exception) {
            clearPending()
            result?.error("WRITE_FAILED", error.message, null)
        }
    }

    private fun clearPending() {
        pendingResult = null
        pendingBytes = null
    }
}

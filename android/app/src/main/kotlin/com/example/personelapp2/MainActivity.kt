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
        private const val OPEN_BACKUP_REQUEST = 7102
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("OPERATION_IN_PROGRESS", "Başka bir işlem sürdürülüyor.", null)
            return
        }

        when (call.method) {
            "saveBackup" -> {
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
            "openBackup" -> {
                pendingResult = result
                Log.d(TAG, "Opening file picker for reading backup")
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                }
                try {
                    startActivityForResult(intent, OPEN_BACKUP_REQUEST)
                } catch (error: Exception) {
                    clearPending()
                    result.error("OPEN_DIALOG_FAILED", error.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            CREATE_BACKUP_REQUEST -> {
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
            OPEN_BACKUP_REQUEST -> {
                val result = pendingResult
                if (resultCode != Activity.RESULT_OK || data?.data == null) {
                    clearPending()
                    result?.success(null)
                    return
                }
                try {
                    val uri = data.data!!
                    val content = contentResolver.openInputStream(uri).use { stream ->
                        requireNotNull(stream) { "Seçilen dosya okunamadı." }
                        stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
                    }
                    Log.d(TAG, "Read ${content.length} backup characters from $uri")
                    clearPending()
                    result?.success(content)
                } catch (error: Exception) {
                    clearPending()
                    result?.error("READ_FAILED", error.message, null)
                }
            }
            else -> super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private fun clearPending() {
        pendingResult = null
        pendingBytes = null
    }
}

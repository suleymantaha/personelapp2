package com.example.personelapp2

import android.app.Activity
import android.app.ProgressDialog
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "NizamNative"
        private const val BACKUP_CHANNEL = "nizam/backup_files"
        private const val OCR_CHANNEL = "nizam/ocr"
        private const val CREATE_BACKUP_REQUEST = 7101
        private const val OPEN_BACKUP_REQUEST = 7102
        private const val OPEN_OCR_IMAGE_REQUEST = 7103
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var ocrProgressDialog: ProgressDialog? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
            .setMethodCallHandler(::handleBackupMethodCall)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OCR_CHANNEL)
            .setMethodCallHandler(::handleOcrMethodCall)
    }

    private fun handleOcrMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("OPERATION_IN_PROGRESS", "Baska bir islem surduruluyor.", null)
            return
        }

        when (call.method) {
            "pickAndRecognizeLatinText" -> {
                pendingResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "image/*"
                }
                try {
                    startActivityForResult(intent, OPEN_OCR_IMAGE_REQUEST)
                } catch (error: Exception) {
                    clearPending()
                    result.error("OCR_PICK_FAILED", error.message, error.toString())
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun handleBackupMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("OPERATION_IN_PROGRESS", "Baska bir islem surduruluyor.", null)
            return
        }

        when (call.method) {
            "saveBackup" -> {
                val name = call.argument<String>("name")
                val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                val bytes = call.argument<ByteArray>("bytes")
                if (name.isNullOrBlank() || bytes == null) {
                    result.error("INVALID_ARGUMENTS", "Yedek dosyasi bilgileri eksik.", null)
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
            CREATE_BACKUP_REQUEST -> handleCreateBackupResult(resultCode, data)
            OPEN_BACKUP_REQUEST -> handleOpenBackupResult(resultCode, data)
            OPEN_OCR_IMAGE_REQUEST -> handleOcrImageResult(resultCode, data)
            else -> super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private fun handleCreateBackupResult(resultCode: Int, data: Intent?) {
        val result = pendingResult
        val bytes = pendingBytes
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            clearPending()
            result?.success(false)
            return
        }
        try {
            val bytesToWrite = requireNotNull(bytes) { "Yedek verisi bulunamadi." }
            contentResolver.openOutputStream(data.data!!, "w").use { stream ->
                requireNotNull(stream) { "Secilen dosya acilamadi." }
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

    private fun handleOpenBackupResult(resultCode: Int, data: Intent?) {
        val result = pendingResult
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            clearPending()
            result?.success(null)
            return
        }
        try {
            val uri = data.data!!
            val content = contentResolver.openInputStream(uri).use { stream ->
                requireNotNull(stream) { "Secilen dosya okunamadi." }
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

    private fun handleOcrImageResult(resultCode: Int, data: Intent?) {
        val result = pendingResult
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            clearPending()
            result?.success(null)
            return
        }
        try {
            showOcrProgress()
            val bitmap = decodeBitmapFromUri(data.data!!)
            if (bitmap == null) {
                hideOcrProgress()
                clearPending()
                result?.error("IMAGE_DECODE_FAILED", "Gorsel dosyasi okunamadi.", null)
                return
            }
            clearPending()
            result?.let { recognizeLatinText(bitmap, it) }
        } catch (error: Exception) {
            hideOcrProgress()
            clearPending()
            result?.error("OCR_READ_FAILED", error.message, error.toString())
        }
    }

    private fun recognizeLatinText(bitmap: Bitmap, result: MethodChannel.Result) {
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        val image = InputImage.fromBitmap(bitmap, 0)
        recognizer.process(image)
            .addOnSuccessListener { text ->
                recognizer.close()
                hideOcrProgress()
                result.success(text.text)
            }
            .addOnFailureListener { error ->
                recognizer.close()
                hideOcrProgress()
                result.error("OCR_FAILED", error.message, error.toString())
            }
    }

    @Suppress("DEPRECATION")
    private fun showOcrProgress() {
        runOnUiThread {
            if (ocrProgressDialog?.isShowing == true) return@runOnUiThread
            ocrProgressDialog = ProgressDialog(this).apply {
                setMessage("Gorsel okunuyor...")
                setCancelable(false)
                show()
            }
        }
    }

    private fun hideOcrProgress() {
        runOnUiThread {
            ocrProgressDialog?.dismiss()
            ocrProgressDialog = null
        }
    }

    private fun decodeBitmapFromUri(uri: Uri): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        contentResolver.openInputStream(uri).use { stream ->
            if (stream == null) return null
            BitmapFactory.decodeStream(stream, null, bounds)
        }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        val options = BitmapFactory.Options().apply {
            inSampleSize = calculateInSampleSize(bounds.outWidth, bounds.outHeight, 2400)
        }
        return contentResolver.openInputStream(uri).use { stream ->
            if (stream == null) null else BitmapFactory.decodeStream(stream, null, options)
        }
    }

    private fun calculateInSampleSize(width: Int, height: Int, maxSize: Int): Int {
        var sampleSize = 1
        var scaledWidth = width
        var scaledHeight = height
        while (scaledWidth > maxSize || scaledHeight > maxSize) {
            sampleSize *= 2
            scaledWidth /= 2
            scaledHeight /= 2
        }
        return sampleSize
    }

    private fun clearPending() {
        pendingResult = null
        pendingBytes = null
    }
}

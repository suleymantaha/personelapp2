package com.example.personelapp2

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Keeps the generated PDF intact and supplies only the initial print settings. */
internal object RosterPrintBridge {
    private val writer = Executors.newFixedThreadPool(2)

    fun print(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "printPdf") {
            result.notImplemented()
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.error("UNSUPPORTED", "Duplex defaults require Android 6 or newer.", null)
            return
        }

        val name = call.argument<String>("name")
        val bytes = call.argument<ByteArray>("bytes")
        val pageCount = call.argument<Int>("pageCount")
        if (name.isNullOrBlank() || bytes == null || pageCount == null || pageCount < 1 ||
            bytes.size < 5 || bytes[0] != '%'.code.toByte() ||
            bytes[1] != 'P'.code.toByte() || bytes[2] != 'D'.code.toByte() ||
            bytes[3] != 'F'.code.toByte() || bytes[4] != '-'.code.toByte()
        ) {
            result.error("INVALID_ARGUMENTS", "A valid PDF, name and page count are required.", null)
            return
        }

        val manager = activity.getSystemService(Context.PRINT_SERVICE) as? PrintManager
        if (manager == null) {
            result.error("UNSUPPORTED", "Android printing is unavailable.", null)
            return
        }
        val attributes = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            .setDuplexMode(
                if (pageCount == 1) PrintAttributes.DUPLEX_MODE_NONE
                else PrintAttributes.DUPLEX_MODE_LONG_EDGE
            )
            .build()
        try {
            manager.print(name, PdfPrintAdapter(name, bytes, pageCount), attributes)
            result.success(null)
        } catch (error: RuntimeException) {
            result.error("PRINT_FAILED", error.message, null)
        }
    }

    private class PdfPrintAdapter(
        private val name: String,
        private val bytes: ByteArray,
        private val pageCount: Int,
    ) : PrintDocumentAdapter() {
        override fun onLayout(
            oldAttributes: PrintAttributes?,
            newAttributes: PrintAttributes?,
            cancellationSignal: CancellationSignal,
            callback: LayoutResultCallback,
            extras: Bundle?,
        ) {
            if (cancellationSignal.isCanceled) {
                callback.onLayoutCancelled()
                return
            }
            val info = PrintDocumentInfo.Builder(name)
                .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
                .setPageCount(pageCount)
                .build()
            callback.onLayoutFinished(info, false)
        }

        override fun onWrite(
            pages: Array<out PageRange>,
            destination: ParcelFileDescriptor,
            cancellationSignal: CancellationSignal,
            callback: WriteResultCallback,
        ) {
            // The PDF contains all pages. AOSP PrintSpooler maps requested page
            // ranges to this full file when the actual written pages are reported.
            writer.execute {
                var failure: Exception? = null
                try {
                    ParcelFileDescriptor.AutoCloseOutputStream(destination).use { stream ->
                        var offset = 0
                        while (offset < bytes.size) {
                            if (cancellationSignal.isCanceled) break
                            val count = minOf(16 * 1024, bytes.size - offset)
                            stream.write(bytes, offset, count)
                            offset += count
                        }
                    }
                } catch (error: Exception) {
                    failure = error
                }
                // Report once, after the descriptor has been closed.
                if (cancellationSignal.isCanceled) callback.onWriteCancelled()
                else if (failure != null) callback.onWriteFailed(failure.message)
                else callback.onWriteFinished(arrayOf(PageRange(0, pageCount - 1)))
            }
        }
    }
}

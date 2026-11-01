package com.example.personelapp2

import java.io.InputStream
import java.io.IOException
import java.io.InterruptedIOException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

internal object BoundedBackupReader {
    const val MAX_BYTES = 50 * 1024 * 1024

    fun read(stream: InputStream): String = stream.use {
        LimitedStream(it).bufferedReader(Charsets.UTF_8).readText()
    }

    // Limit bytes before the UTF-8 decoder or String builder can consume them.
    // The one-byte probe distinguishes exact-limit EOF from an oversized input.
    private class LimitedStream(private val source: InputStream) : InputStream() {
        private var remaining = MAX_BYTES

        override fun read(): Int {
            checkInterrupted()
            if (remaining == 0) return checkEnd()
            return source.read().also { if (it >= 0) remaining-- }
        }

        override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
            checkInterrupted()
            if (length == 0) return 0
            if (remaining == 0) return checkEnd()
            return source.read(buffer, offset, minOf(length, remaining)).also {
                if (it > 0) remaining -= it
            }
        }

        private fun checkEnd(): Int {
            if (source.read() == -1) return -1
            throw IOException("Yedek dosyasi 50 MiB sinirini asiyor.")
        }

        private fun checkInterrupted() {
            if (Thread.currentThread().isInterrupted) {
                throw InterruptedIOException("Yedek okuma iptal edildi.")
            }
        }
    }
}

internal class BackupReadOperation(
    private val open: () -> InputStream,
    private val cancelOpen: () -> Unit = {},
) {
    private val cancelled = AtomicBoolean(false)
    private val activeStream = AtomicReference<InputStream?>(null)

    fun read(): String {
        checkCancelled()
        val stream = CloseOnceStream(open())
        activeStream.set(stream)
        try {
            // Cancellation may have raced the provider open or stream publication.
            checkCancelled()
            return BoundedBackupReader.read(stream)
        } finally {
            activeStream.compareAndSet(stream, null)
            stream.close()
        }
    }

    fun cancel() {
        cancelled.set(true)
        try {
            cancelOpen()
        } finally {
            activeStream.getAndSet(null)?.close()
        }
    }

    private fun checkCancelled() {
        if (cancelled.get()) throw InterruptedIOException("Yedek okuma iptal edildi.")
    }

    private class CloseOnceStream(private val source: InputStream) : InputStream() {
        private val closed = AtomicBoolean(false)
        override fun read(): Int = source.read()
        override fun read(buffer: ByteArray, offset: Int, length: Int): Int = source.read(buffer, offset, length)
        override fun close() {
            if (closed.compareAndSet(false, true)) source.close()
        }
    }
}

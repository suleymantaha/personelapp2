package com.example.personelapp2

import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.io.InterruptedIOException
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

// Standalone JVM regression suite; no Android runtime or JUnit dependency required.
object BoundedBackupReaderTest {
    @JvmStatic
    fun main(args: Array<String>) {
        val tests = listOf(
            "empty" to { check(BoundedBackupReader.read(ByteArrayInputStream(byteArrayOf())) == "") },
            "UTF-8" to {
                val text = "Türkçe İışğüöç 😀"
                check(BoundedBackupReader.read(ByteArrayInputStream(text.toByteArray())) == text)
            },
            "malformed UTF-8 replacement" to {
                check(BoundedBackupReader.read(ByteArrayInputStream(byteArrayOf(0xC3.toByte()))) == "\uFFFD")
            },
            "exact 50 MiB accepted and closed" to {
                val stream = GeneratedStream(BoundedBackupReader.MAX_BYTES)
                check(BoundedBackupReader.read(stream).length == BoundedBackupReader.MAX_BYTES)
                check(stream.closed)
            },
            "50 MiB plus one rejected and closed" to {
                val stream = GeneratedStream(BoundedBackupReader.MAX_BYTES + 1)
                expect<IOException> { BoundedBackupReader.read(stream) }
                check(stream.bytesRead == BoundedBackupReader.MAX_BYTES + 1)
                check(stream.closed)
            },
            "unending stream stops at one overflow byte" to {
                val stream = GeneratedStream(Int.MAX_VALUE)
                expect<IOException> { BoundedBackupReader.read(stream) }
                check(stream.bytesRead == BoundedBackupReader.MAX_BYTES + 1)
                check(stream.closed)
            },
            "UTF-8 limit counts bytes rather than characters" to {
                val stream = GeneratedStream(BoundedBackupReader.MAX_BYTES + 2, multibyte = true)
                expect<IOException> { BoundedBackupReader.read(stream) }
                check(stream.bytesRead == BoundedBackupReader.MAX_BYTES + 1)
            },
            "read error closes stream" to {
                val stream = object : InputStream() {
                    var closed = false
                    override fun read(): Int = throw IOException("synthetic failure")
                    override fun close() { closed = true }
                }
                val error = expect<IOException> { BoundedBackupReader.read(stream) }
                check(error.message == "synthetic failure")
                check(stream.closed)
            },
            "interrupt cancels read and closes stream" to {
                val stream = GeneratedStream(100)
                Thread.currentThread().interrupt()
                try {
                    expect<InterruptedIOException> { BoundedBackupReader.read(stream) }
                    check(stream.bytesRead == 0)
                    check(stream.closed)
                } finally {
                    Thread.interrupted()
                }
            },
            "slow read on worker can be interrupted" to {
                val started = java.util.concurrent.CountDownLatch(1)
                val closed = java.util.concurrent.CountDownLatch(1)
                val executor = Executors.newSingleThreadExecutor()
                val stream = object : InputStream() {
                    override fun read(): Int {
                        started.countDown()
                        try {
                            java.util.concurrent.CountDownLatch(1).await()
                        } catch (_: InterruptedException) {
                            throw InterruptedIOException("cancelled")
                        }
                        return -1
                    }
                    override fun close() { closed.countDown() }
                }
                try {
                    val future = executor.submit { BoundedBackupReader.read(stream) }
                    check(started.await(2, TimeUnit.SECONDS))
                    future.cancel(true)
                    check(closed.await(2, TimeUnit.SECONDS))
                } finally {
                    executor.shutdownNow()
                }
            },
            "cancel closes a provider read that ignores interruption" to {
                val started = java.util.concurrent.CountDownLatch(1)
                val closed = java.util.concurrent.CountDownLatch(1)
                val finished = java.util.concurrent.CountDownLatch(1)
                val executor = Executors.newSingleThreadExecutor()
                val stream = object : InputStream() {
                    override fun read(): Int {
                        started.countDown()
                        while (closed.count > 0) {
                            try { closed.await() } catch (_: InterruptedException) { /* provider ignores */ }
                        }
                        throw IOException("closed")
                    }
                    override fun close() { closed.countDown() }
                }
                val operation = BackupReadOperation({ stream })
                try {
                    val future = executor.submit {
                        try { operation.read() } catch (_: IOException) { } finally { finished.countDown() }
                    }
                    check(started.await(2, TimeUnit.SECONDS))
                    future.cancel(true)
                    check(!finished.await(50, TimeUnit.MILLISECONDS))
                    operation.cancel()
                    check(closed.await(2, TimeUnit.SECONDS))
                    check(finished.await(2, TimeUnit.SECONDS))
                } finally {
                    stream.close()
                    executor.shutdownNow()
                }
            },
            "cancel during open closes returned stream before reading" to {
                val stream = GeneratedStream(100)
                lateinit var operation: BackupReadOperation
                operation = BackupReadOperation({ operation.cancel(); stream })
                expect<InterruptedIOException> { operation.read() }
                check(stream.closed && stream.bytesRead == 0)
            },
            "cancel before open prevents provider access" to {
                var opened = false
                var cancelledOpen = false
                val operation = BackupReadOperation(
                    { opened = true; GeneratedStream(100) },
                    { cancelledOpen = true },
                )
                operation.cancel()
                expect<InterruptedIOException> { operation.read() }
                check(!opened && cancelledOpen)
            },
        )
        tests.forEach { (name, test) ->
            test()
            println("PASS: $name")
        }
        println("${tests.size} tests passed")
    }

    private inline fun <reified T : Throwable> expect(block: () -> Unit): T {
        try {
            block()
        } catch (error: Throwable) {
            check(error is T) { "Expected ${T::class.java.simpleName}, got $error" }
            return error
        }
        error("Expected ${T::class.java.simpleName}")
    }

    private class GeneratedStream(private val size: Int, private val multibyte: Boolean = false) : InputStream() {
        var bytesRead = 0
        var closed = false
        override fun read(): Int {
            if (bytesRead == size) return -1
            val value = if (multibyte) { if (bytesRead % 2 == 0) 0xC3 else 0xBC } else 0x61
            bytesRead++
            return value
        }
        override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
            if (bytesRead == size) return -1
            val count = minOf(length, size - bytesRead)
            for (index in 0 until count) buffer[offset + index] = read().toByte()
            return count
        }
        override fun close() { closed = true }
    }
}

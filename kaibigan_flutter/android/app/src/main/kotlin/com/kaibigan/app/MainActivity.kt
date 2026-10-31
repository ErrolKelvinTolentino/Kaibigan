package com.kaibigan.app

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val LIFECYCLE_CHANNEL = "com.kaibigan.app/app_lifecycle"
    private val PDF_CHANNEL = "com.kaibigan.app/pdf_export"
    private val PDF_REQUEST = 19280
    private var pendingPdfResult: MethodChannel.Result? = null
    private var pendingPdfBytes: ByteArray? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIFECYCLE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendToBackground") {
                    val moved = moveTaskToBack(true)
                    result.success(moved)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdf") {
                    result.notImplemented()
                } else if (pendingPdfResult != null) {
                    result.error("EXPORT_IN_PROGRESS", "Finish the current PDF export first.", null)
                } else {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null || bytes.size < 5 ||
                        String(bytes.copyOfRange(0, 5), Charsets.US_ASCII) != "%PDF-") {
                        result.error("INVALID_PDF", "The PDF could not be created.", null)
                    } else {
                        val proposed = (call.argument<String>("filename") ?: "Kaibigan.pdf")
                            .replace(Regex("[^\\p{L}\\p{N} ._()-]"), "_")
                            .trim().take(120).ifBlank { "Kaibigan.pdf" }
                        val filename = if (proposed.endsWith(".pdf", ignoreCase = true)) proposed else "$proposed.pdf"
                        pendingPdfResult = result
                        pendingPdfBytes = bytes
                        try {
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/pdf"
                                putExtra(Intent.EXTRA_TITLE, filename)
                            }
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, PDF_REQUEST)
                        } catch (_: Exception) {
                            pendingPdfResult = null
                            pendingPdfBytes = null
                            result.error("SAVE_UNAVAILABLE", "The PDF save dialog could not be opened.", null)
                        }
                    }
                }
            }
    }

    @Deprecated("Android activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PDF_REQUEST) return
        val result = pendingPdfResult ?: return
        val bytes = pendingPdfBytes
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) {
            pendingPdfResult = null
            pendingPdfBytes = null
            result.success(false)
            return
        }
        // Large journals must not block Flutter's UI thread while being saved.
        Thread {
            try {
                val output = contentResolver.openOutputStream(uri, "wt")
                    ?: throw java.io.IOException("Destination is unavailable")
                output.use { it.write(bytes); it.flush() }
                runOnUiThread {
                    pendingPdfResult = null
                    pendingPdfBytes = null
                    result.success(true)
                }
            } catch (_: Exception) {
                runOnUiThread {
                    pendingPdfResult = null
                    pendingPdfBytes = null
                    result.error("WRITE_FAILED", "The PDF could not be saved at that location.", null)
                }
            }
        }.start()
    }
}

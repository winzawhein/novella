package com.example.novella

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val rendererQueue = Executors.newSingleThreadExecutor()
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "novella/page_images")
            .setMethodCallHandler { call, result ->
                if (call.method != "render") {
                    result.notImplemented()
                } else {
                    val path = call.argument<String>("path")!!
                    val index = call.argument<Int>("page") ?: 0
                    rendererQueue.execute {
                        try {
                            val output = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                                PdfRenderer(descriptor).use { renderer ->
                                    renderer.openPage(index.coerceIn(0, renderer.pageCount - 1)).use { page ->
                                        val width = 1200
                                        val height = (width.toDouble() * page.height / page.width).toInt()
                                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                                        try {
                                            bitmap.eraseColor(Color.WHITE)
                                            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                            val stream = ByteArrayOutputStream()
                                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                            mapOf("count" to renderer.pageCount, "bytes" to stream.toByteArray())
                                        } finally { bitmap.recycle() }
                                    }
                                }
                            }
                            runOnUiThread { result.success(output) }
                        } catch (error: Exception) {
                            runOnUiThread { result.error("PDF_RENDER", error.message, null) }
                        }
                    }
                }
            }
    }
}

package com.example.mobile_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "nextgen/version").setMethodCallHandler { call, result ->
            when (call.method) {
                "codigoInstalado" -> {
                    val info = packageManager.getPackageInfo(packageName, 0)
                    @Suppress("DEPRECATION")
                    result.success(if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong())
                }
                "abrirDescarga" -> {
                    val pagina = Uri.parse("https://nextgen-motors-3xcw.onrender.com/descargar-app")
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, pagina))
                        result.success(null)
                    } catch (e: android.content.ActivityNotFoundException) {
                        result.error("sin_navegador", "No hay un navegador disponible", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

package com.example.localdrop

import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            multicastLock = wifi?.createMulticastLock("localdrop_multicast_lock")?.apply {
                setReferenceCounted(true)
                acquire()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Request storage permissions on Android M-Q if not yet granted
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) {
            val writePerm = checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
            val readPerm = checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE)
            if (writePerm != PackageManager.PERMISSION_GRANTED || readPerm != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(
                    arrayOf(
                        android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
                        android.Manifest.permission.READ_EXTERNAL_STORAGE
                    ),
                    101
                )
            }
        }
    }

    override fun onDestroy() {
        try {
            multicastLock?.release()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        super.onDestroy()
    }
}

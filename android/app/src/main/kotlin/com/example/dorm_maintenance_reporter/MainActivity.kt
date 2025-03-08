package com.example.dorm_maintenance_reporter

import android.os.Bundle
import android.util.Log
import com.google.android.gms.security.ProviderInstaller
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.google.android.gms.common.GooglePlayServicesNotAvailableException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.providerinstaller/provider"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installProvider") {
                installSecurityProvider(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun installSecurityProvider(result: MethodChannel.Result) {
        try {
            // Install the up-to-date security provider if needed
            ProviderInstaller.installIfNeeded(applicationContext)
            Log.i("ProviderInstaller", "Security provider installed successfully.")
            result.success(null)
        } catch (e: GooglePlayServicesRepairableException) {
            // Google Play Services is available but needs updating
            Log.e("ProviderInstaller", "Google Play Services requires user action: " + e.message)
            GoogleApiAvailability.getInstance().showErrorNotification(this, e.connectionStatusCode)
            result.error("REPAIRABLE", "Google Play Services repairable issue", e.message)
        } catch (e: GooglePlayServicesNotAvailableException) {
            // Google Play Services is not available
            Log.e("ProviderInstaller", "Google Play Services is not available: " + e.message)
            result.error("NOT_AVAILABLE", "Google Play Services not available", e.message)
        } catch (e: Exception) {
            // Other unexpected exceptions
            Log.e("ProviderInstaller", "Failed to install security provider: " + e.message)
            result.error("UNAVAILABLE", "Failed to install provider", e.message)
        }
    }
}
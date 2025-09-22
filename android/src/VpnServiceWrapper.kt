package com.raccoonline.vpnapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import io.nekohasekai.libbox.*
import kotlinx.coroutines.*
import java.io.File

/**
 * Complete VPN Service with sing-box functionality
 */
class VpnServiceWrapper : VpnService(), PlatformInterfaceWrapper {

    companion object {
        private const val TAG = "VpnServiceWrapper"
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "vpn_channel"

        @Volatile
        private var _isRunning = false  // Changed name to avoid conflict

        // Public property to expose the running state
        val isRunning: Boolean
            get() = _isRunning

        fun startVpn(context: Context, config: String): Boolean {
            if (_isRunning) {
                Log.w(TAG, "VPN already running")
                return false
            }

            val intent = Intent(context, VpnServiceWrapper::class.java).apply {
                action = "START_VPN"
                putExtra("config", config)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }

            return true
        }

        fun stopVpn(context: Context): Boolean {
            if (!_isRunning) {
                Log.w(TAG, "VPN not running")
                return false
            }

            val intent = Intent(context, VpnServiceWrapper::class.java).apply {
                action = "STOP_VPN"
            }
            context.startService(intent)
            return true
        }
    }

    private var fileDescriptor: ParcelFileDescriptor? = null
    // Note: Don't confuse with io.nekohasekai.libbox.BoxService
    private var libboxService: io.nekohasekai.libbox.BoxService? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    // This is our custom BoxService handler
    private lateinit var boxServiceHandler: BoxService

    // PlatformInterfaceWrapper implementation
    override fun getContext(): Context = this

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "VPN Service created")

        // Initialize our custom BoxService handler
        boxServiceHandler = BoxService(this, this)

        // Initialize network monitoring components
        DefaultNetworkListener.initialize(this)
        DefaultNetworkMonitor.initialize(this)

        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: ${intent?.action}")

        when (intent?.action) {
            "START_VPN" -> {
                val config = intent.getStringExtra("config")
                if (config != null) {
                    startForeground(NOTIFICATION_ID, createNotification("Connecting..."))
                    scope.launch {
                        startVpnWithConfig(config)
                    }
                }
            }
            "STOP_VPN" -> {
                stopVpn()
            }
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "VPN Service destroyed")
        stopVpn()
        scope.cancel()
        super.onDestroy()
    }

    override fun onRevoke() {
        Log.d(TAG, "VPN permission revoked")
        boxServiceHandler.onRevoke()
        super.onRevoke()
    }

    private suspend fun startVpnWithConfig(configJson: String) = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Starting VPN with config")

            // Use the BoxService to start sing-box
            val success = boxServiceHandler.startService(configJson)

            if (success) {
                _isRunning = true
                withContext(Dispatchers.Main) {
                    updateNotification("Connected")
                }
                Log.i(TAG, "VPN started successfully")
            } else {
                throw Exception("Failed to start BoxService")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN", e)
            _isRunning = false

            withContext(Dispatchers.Main) {
                updateNotification("Failed: ${e.message}")
                delay(2000)
                stopSelf()
            }
        }
    }

    private fun stopVpn() {
        Log.d(TAG, "Stopping VPN")

        boxServiceHandler.onDestroy()

        fileDescriptor?.close()
        fileDescriptor = null

        _isRunning = false

//        stopForeground(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    // PlatformInterface implementation
    override fun autoDetectInterfaceControl(fd: Int) {
        protect(fd)
    }

    override fun openTun(options: TunOptions): Int {
        if (prepare(this) != null) {
            throw IllegalStateException("VPN permission not granted")
        }

        val builder = Builder()
            .setSession("VPN Client")
            .setMtu(options.mtu)

        // Add IPv4 addresses
        val inet4Address = options.inet4Address
        while (inet4Address?.hasNext() == true) {
            val addr = inet4Address.next()
            builder.addAddress(addr.address(), addr.prefix())
        }

        // Add IPv6 addresses
        val inet6Address = options.inet6Address
        while (inet6Address?.hasNext() == true) {
            val addr = inet6Address.next()
            builder.addAddress(addr.address(), addr.prefix())
        }

        if (options.autoRoute) {
            // Handle DNS server - it returns StringBox type
            try {
                val dnsBox = options.dnsServerAddress
                if (dnsBox != null) {
                    // StringBox has a value property
                    val dnsValue = dnsBox.value
                    if (!dnsValue.isNullOrEmpty()) {
                        builder.addDnsServer(dnsValue)
                    } else {
                        builder.addDnsServer("8.8.8.8")
                    }
                } else {
                    builder.addDnsServer("8.8.8.8")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to get DNS, using default", e)
                builder.addDnsServer("8.8.8.8")
            }

            // Add routes based on Android version
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Android 13+ route handling
                val inet4Routes = options.inet4RouteAddress
                if (inet4Routes?.hasNext() == true) {
                    while (inet4Routes.hasNext()) {
                        val route = inet4Routes.next()
                        builder.addRoute(route.address(), route.prefix())
                    }
                } else {
                    builder.addRoute("0.0.0.0", 0)
                }

                val inet6Routes = options.inet6RouteAddress
                if (inet6Routes?.hasNext() == true) {
                    while (inet6Routes.hasNext()) {
                        val route = inet6Routes.next()
                        builder.addRoute(route.address(), route.prefix())
                    }
                }
            } else {
                // Legacy route handling
                val inet4Routes = options.inet4RouteRange
                if (inet4Routes?.hasNext() == true) {
                    while (inet4Routes.hasNext()) {
                        val route = inet4Routes.next()
                        builder.addRoute(route.address(), route.prefix())
                    }
                } else {
                    builder.addRoute("0.0.0.0", 0)
                }

                val inet6Routes = options.inet6RouteRange
                if (inet6Routes?.hasNext() == true) {
                    while (inet6Routes.hasNext()) {
                        val route = inet6Routes.next()
                        builder.addRoute(route.address(), route.prefix())
                    }
                }
            }

            // Handle include/exclude packages
            val includePackage = options.includePackage
            while (includePackage?.hasNext() == true) {
                try {
                    builder.addAllowedApplication(includePackage.next())
                } catch (_: PackageManager.NameNotFoundException) {
                    // Ignore missing packages
                }
            }

            val excludePackage = options.excludePackage
            while (excludePackage?.hasNext() == true) {
                try {
                    builder.addDisallowedApplication(excludePackage.next())
                } catch (_: PackageManager.NameNotFoundException) {
                    // Ignore missing packages
                }
            }
        }

        // Establish VPN
        fileDescriptor?.close()
        val pfd = builder.establish()
            ?: throw IllegalStateException("Failed to establish VPN")

        fileDescriptor = pfd
        boxServiceHandler.fileDescriptor = pfd

        return pfd.fd
    }

    override fun writeLog(message: String) {
        Log.d(TAG, "libbox: $message")
        boxServiceHandler.writeLog(message)
    }

    override fun sendNotification(notification: Notification) {
        updateNotification(notification.title)
        boxServiceHandler.sendNotification(notification)
    }

    // Notification handling
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "VPN connection status"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(message: String): android.app.Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationCompat.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            NotificationCompat.Builder(this)
        }

        return builder
            .setContentTitle("VPN Status")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(message: String) {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.notify(NOTIFICATION_ID, createNotification(message))
    }

    override fun onBind(intent: Intent?): IBinder? {
        val binder = super.onBind(intent)
        if (binder != null) {
            return binder
        }
        return boxServiceHandler.onBind()
    }
}

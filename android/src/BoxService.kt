package com.raccoonline.vpnapp

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.lifecycle.MutableLiveData
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.Notification
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.SetupOptions
import io.nekohasekai.libbox.SystemProxyStatus
import kotlinx.coroutines.*
import java.io.File

// Simple constants to replace R resources
object ServiceConstants {
    const val ACTION_SERVICE_CLOSE = "com.yourcompany.vpnclient.ACTION_SERVICE_CLOSE"
    const val STATUS_STARTING = "Starting..."
    const val STATUS_STARTED = "Connected"
    const val STATUS_STOPPING = "Stopping..."
    const val STATUS_STOPPED = "Disconnected"
}

// Simple status enum
enum class ServiceStatus {
    Stopped, Starting, Started, Stopping
}

// Simple alert types
enum class AlertType {
    EmptyConfiguration,
    CreateService,
    StartService,
    StartCommandServer,
    RequestLocationPermission
}

class BoxService(
    private val service: Service,
    private val platformInterface: PlatformInterface
) : CommandServerHandler {

    companion object {
        private const val TAG = "BoxService"
        private var initializeOnce = false

        private fun initialize(context: Context) {
            if (initializeOnce) return
            val baseDir = context.filesDir
            baseDir.mkdirs()
            val workingDir = context.getExternalFilesDir(null) ?: context.filesDir
            workingDir.mkdirs()
            val tempDir = context.cacheDir
            tempDir.mkdirs()

            Libbox.setup(SetupOptions().also {
                it.basePath = baseDir.path
                it.workingPath = workingDir.path
                it.tempPath = tempDir.path
            })

            Libbox.redirectStderr(File(workingDir, "stderr.log").path)
            initializeOnce = true
        }
    }

    var fileDescriptor: ParcelFileDescriptor? = null
    val status = MutableLiveData(ServiceStatus.Stopped)

    private var boxService: BoxService? = null
    private var commandServer: CommandServer? = null
    private var receiverRegistered = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ServiceConstants.ACTION_SERVICE_CLOSE -> {
                    stopService()
                }
                PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        serviceUpdateIdleMode()
                    }
                }
            }
        }
    }

    private fun startCommandServer() {
        val commandServer = CommandServer(this, 300)
        commandServer.start()
        this.commandServer = commandServer
    }

    suspend fun startService(configJson: String): Boolean = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Starting service with config")

            // Initialize if needed
            initialize(service)

            // Register network monitoring
            DefaultNetworkMonitor.start()

            // Register local DNS
            Libbox.registerLocalDNSTransport(LocalResolver)
            Libbox.setMemoryLimit(false)

            // Create new service
            val newService = try {
                Libbox.newService(configJson, platformInterface)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to create service", e)
                stopAndAlert(AlertType.CreateService, e.message)
                return@withContext false
            }

            // Start the service
            newService.start()

            // Check if WIFI state is needed
            if (newService.needWIFIState()) {
                val wifiPermission = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    android.Manifest.permission.ACCESS_FINE_LOCATION
                } else {
                    android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
                }

                // Check permission
                if (service.checkSelfPermission(wifiPermission) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    newService.close()
                    stopAndAlert(AlertType.RequestLocationPermission)
                    return@withContext false
                }
            }

            boxService = newService
            commandServer?.setService(boxService)
            status.postValue(ServiceStatus.Started)

            Log.i(TAG, "Service started successfully")
            true

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service", e)
            stopAndAlert(AlertType.StartService, e.message)
            false
        }
    }

    override fun serviceReload() {
        status.postValue(ServiceStatus.Starting)
        val pfd = fileDescriptor
        if (pfd != null) {
            pfd.close()
            fileDescriptor = null
        }
        boxService?.apply {
            runCatching {
                close()
            }.onFailure {
                Log.e(TAG, "Error closing service: $it")
            }
        }
        commandServer?.setService(null)
        commandServer?.resetLog()
        boxService = null

        // You need to restart with config here
        // This is simplified - you'd need to store the config
        runBlocking {
            // startService(lastConfig)
        }
    }

    override fun postServiceClose() {
        // Not used on Android
    }

    override fun getSystemProxyStatus(): SystemProxyStatus {
        val status = SystemProxyStatus()
        status.available = false
        status.enabled = false
        return status
    }

    override fun setSystemProxyEnabled(isEnabled: Boolean) {
        serviceReload()
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun serviceUpdateIdleMode() {
        val powerManager = service.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (powerManager.isDeviceIdleMode) {
            boxService?.pause()
        } else {
            boxService?.wake()
        }
    }

    @OptIn(DelicateCoroutinesApi::class)
    private fun stopService() {
        if (status.value != ServiceStatus.Started) return
        status.value = ServiceStatus.Stopping

        if (receiverRegistered) {
            service.unregisterReceiver(receiver)
            receiverRegistered = false
        }

        GlobalScope.launch(Dispatchers.IO) {
            val pfd = fileDescriptor
            if (pfd != null) {
                pfd.close()
                fileDescriptor = null
            }

            boxService?.apply {
                runCatching {
                    close()
                }.onFailure {
                    Log.e(TAG, "Error closing service: $it")
                }
            }

            commandServer?.setService(null)
            boxService = null
            Libbox.registerLocalDNSTransport(null)
            DefaultNetworkMonitor.stop()

            commandServer?.apply {
                close()
            }
            commandServer = null

            withContext(Dispatchers.Main) {
                status.value = ServiceStatus.Stopped
                service.stopSelf()
            }
        }
    }

    private suspend fun stopAndAlert(type: AlertType, message: String? = null) {
        withContext(Dispatchers.Main) {
            if (receiverRegistered) {
                service.unregisterReceiver(receiver)
                receiverRegistered = false
            }

            Log.e(TAG, "Alert: $type - $message")
            status.value = ServiceStatus.Stopped
        }
    }

    @OptIn(DelicateCoroutinesApi::class)
    internal fun onStartCommand(): Int {
        if (status.value != ServiceStatus.Stopped) return Service.START_NOT_STICKY
        status.value = ServiceStatus.Starting

        if (!receiverRegistered) {
            ContextCompat.registerReceiver(service, receiver, IntentFilter().apply {
                addAction(ServiceConstants.ACTION_SERVICE_CLOSE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
                }
            }, ContextCompat.RECEIVER_NOT_EXPORTED)
            receiverRegistered = true
        }

        GlobalScope.launch(Dispatchers.IO) {
            initialize(service)
            try {
                startCommandServer()
            } catch (e: Exception) {
                stopAndAlert(AlertType.StartCommandServer, e.message)
                return@launch
            }
            // Note: You need to get the config from somewhere
            // This is where you'd integrate with your Qt app
        }

        return Service.START_NOT_STICKY
    }

    internal fun onBind(): IBinder? {
        return null
    }

    internal fun onDestroy() {
        stopService()
    }

    internal fun onRevoke() {
        stopService()
    }

    internal fun writeLog(message: String) {
        commandServer?.writeMessage(message)
    }

    internal fun sendNotification(notification: Notification) {
        Log.d(TAG, "Notification: ${notification.title}")
    }
}

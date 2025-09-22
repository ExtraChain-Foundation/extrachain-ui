package com.raccoonline.vpnapp

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.os.Build
import io.nekohasekai.libbox.InterfaceUpdateListener
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.net.NetworkInterface

object DefaultNetworkMonitor {

    var defaultNetwork: Network? = null
    private var listener: InterfaceUpdateListener? = null
    private var connectivity: ConnectivityManager? = null

    fun initialize(context: Context) {
        connectivity = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }

    suspend fun start() {
        DefaultNetworkListener.start(this) {
            defaultNetwork = it
            checkDefaultInterfaceUpdate(it)
        }
        defaultNetwork = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            connectivity?.activeNetwork
        } else {
            DefaultNetworkListener.get()
        }
    }

    suspend fun stop() {
        DefaultNetworkListener.stop(this)
    }

    suspend fun require(): Network {
        val network = defaultNetwork
        if (network != null) {
            return network
        }
        return DefaultNetworkListener.get()
    }

    fun setListener(listener: InterfaceUpdateListener?) {
        this.listener = listener
        checkDefaultInterfaceUpdate(defaultNetwork)
    }

    private fun checkDefaultInterfaceUpdate(
        newNetwork: Network?
    ) {
        val listener = listener ?: return
        val connectivity = connectivity ?: return

        if (newNetwork != null) {
            val interfaceName =
                (connectivity.getLinkProperties(newNetwork) ?: return).interfaceName
            for (times in 0 until 10) {
                var interfaceIndex: Int
                try {
                    interfaceIndex = NetworkInterface.getByName(interfaceName).index
                } catch (e: Exception) {
                    Thread.sleep(100)
                    continue
                }
                // Always use coroutine for thread safety
                GlobalScope.launch(Dispatchers.IO) {
                    listener.updateDefaultInterface(interfaceName, interfaceIndex, false, false)
                }
                break
            }
        } else {
            GlobalScope.launch(Dispatchers.IO) {
                listener.updateDefaultInterface("", -1, false, false)
            }
        }
    }
}

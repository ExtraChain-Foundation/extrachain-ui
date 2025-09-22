package com.raccoonline.vpnapp

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Process
import android.system.OsConstants
import android.util.Log
import androidx.annotation.RequiresApi
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet6Address
import java.net.InetSocketAddress
import java.net.InterfaceAddress
import java.net.NetworkInterface
import io.nekohasekai.libbox.NetworkInterface as LibboxNetworkInterface

interface PlatformInterfaceWrapper : PlatformInterface {

    fun getContext(): Context

    override fun usePlatformAutoDetectInterfaceControl(): Boolean {
        return true
    }

    override fun autoDetectInterfaceControl(fd: Int) {
        // Will be implemented by VpnService
    }

    override fun openTun(options: TunOptions): Int {
        error("invalid argument - should be implemented by VpnService")
    }

    override fun useProcFS(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int
    ): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return -1
        }

        try {
            val connectivity = getContext().getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val uid = connectivity.getConnectionOwnerUid(
                ipProtocol,
                InetSocketAddress(sourceAddress, sourcePort),
                InetSocketAddress(destinationAddress, destinationPort)
            )
            if (uid == Process.INVALID_UID) error("android: connection owner not found")
            return uid
        } catch (e: Exception) {
            Log.e("PlatformInterface", "getConnectionOwnerUid", e)
            e.printStackTrace(System.err)
            throw e
        }
    }

    override fun packageNameByUid(uid: Int): String {
        val packages = getContext().packageManager.getPackagesForUid(uid)
        if (packages.isNullOrEmpty()) error("android: package not found")
        return packages[0]
    }

    @Suppress("DEPRECATION")
    override fun uidByPackageName(packageName: String): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                getContext().packageManager.getPackageUid(
                    packageName, PackageManager.PackageInfoFlags.of(0)
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                getContext().packageManager.getPackageUid(packageName, 0)
            } else {
                getContext().packageManager.getApplicationInfo(packageName, 0).uid
            }
        } catch (e: PackageManager.NameNotFoundException) {
            error("android: package not found")
        }
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(listener)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        DefaultNetworkMonitor.setListener(null)
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        val connectivity = getContext().getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
//        val networks = connectivity.allNetworks
        val networks = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            connectivity.allNetworks
        } else {
            @Suppress("DEPRECATION")
            connectivity.allNetworks
        }
        val networkInterfaces = NetworkInterface.getNetworkInterfaces().toList()
        val interfaces = mutableListOf<LibboxNetworkInterface>()

        for (network in networks) {
            val boxInterface = LibboxNetworkInterface()
            val linkProperties = connectivity.getLinkProperties(network) ?: continue
            val networkCapabilities = connectivity.getNetworkCapabilities(network) ?: continue

            boxInterface.name = linkProperties.interfaceName
            val networkInterface = networkInterfaces.find { it.name == boxInterface.name } ?: continue

            boxInterface.dnsServer = StringArray(linkProperties.dnsServers.mapNotNull { it.hostAddress }.iterator())
            boxInterface.type = when {
                networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> Libbox.InterfaceTypeWIFI
                networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> Libbox.InterfaceTypeCellular
                networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> Libbox.InterfaceTypeEthernet
                else -> Libbox.InterfaceTypeOther
            }
            boxInterface.index = networkInterface.index

            runCatching {
                boxInterface.mtu = networkInterface.mtu
            }.onFailure {
                Log.e("PlatformInterface", "failed to get mtu for interface ${boxInterface.name}", it)
            }

            boxInterface.addresses = StringArray(networkInterface.interfaceAddresses.mapTo(mutableListOf()) { it.toPrefix() }.iterator())

            var dumpFlags = 0
            if (networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                dumpFlags = OsConstants.IFF_UP or OsConstants.IFF_RUNNING
            }
            if (networkInterface.isLoopback) {
                dumpFlags = dumpFlags or OsConstants.IFF_LOOPBACK
            }
            if (networkInterface.isPointToPoint) {
                dumpFlags = dumpFlags or OsConstants.IFF_POINTOPOINT
            }
            if (networkInterface.supportsMulticast()) {
                dumpFlags = dumpFlags or OsConstants.IFF_MULTICAST
            }
            boxInterface.flags = dumpFlags
            boxInterface.metered = !networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
            interfaces.add(boxInterface)
        }
        return InterfaceArray(interfaces.iterator())
    }

    override fun underNetworkExtension(): Boolean {
        return false
    }

    override fun includeAllNetworks(): Boolean {
        return false
    }

    override fun clearDNSCache() {
        // Not needed for basic functionality
    }

    override fun readWIFIState(): WIFIState? {
        val wifiManager = getContext().applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return null
        @Suppress("DEPRECATION")
        val wifiInfo = wifiManager.connectionInfo ?: return null

        var ssid = wifiInfo.ssid
        if (ssid == "<unknown ssid>") {
            return WIFIState("", "")
        }
        if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
            ssid = ssid.substring(1, ssid.length - 1)
        }
        return WIFIState(ssid, wifiInfo.bssid)
    }

    private class InterfaceArray(private val iterator: Iterator<LibboxNetworkInterface>) :
        NetworkInterfaceIterator {

        override fun hasNext(): Boolean {
            return iterator.hasNext()
        }

        override fun next(): LibboxNetworkInterface {
            return iterator.next()
        }
    }

    private class StringArray(private val iterator: Iterator<String>) : StringIterator {

        override fun len(): Int {
            // not used by core
            return 0
        }

        override fun hasNext(): Boolean {
            return iterator.hasNext()
        }

        override fun next(): String {
            return iterator.next()
        }
    }

    private fun InterfaceAddress.toPrefix(): String {
        return if (address is Inet6Address) {
            "${Inet6Address.getByAddress(address.address).hostAddress}/${networkPrefixLength}"
        } else {
            "${address.hostAddress}/${networkPrefixLength}"
        }
    }

    private val NetworkInterface.flags: Int
        @SuppressLint("SoonBlockedPrivateApi") get() {
            val getFlagsMethod = NetworkInterface::class.java.getDeclaredMethod("getFlags")
            return getFlagsMethod.invoke(this) as Int
        }
}

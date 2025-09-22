package com.raccoonline.vpnapp;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.Uri;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;
import android.util.Log;
import androidx.core.content.FileProvider;
import android.content.res.Resources;
import android.view.View;
import android.view.Window;
import android.graphics.Color;
import android.view.WindowManager;
import android.view.WindowInsetsController;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

import java.io.File;

public class AndroidUtils {
    private static final String TAG = "AndroidUtils";
    private static PowerManager.WakeLock wakeLock;
    private static ConnectivityManager.NetworkCallback networkCallback;
    private static WifiManager.WifiLock wifiLock;

    // Existing method for sharing files
    public static void shareFile(Context context, String filePath) {
        File file = new File(filePath);
        Uri uri = FileProvider.getUriForFile(context, context.getPackageName() + ".qtprovider", file);

        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("*/*");
        intent.putExtra(Intent.EXTRA_STREAM, uri);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        Intent chooser = Intent.createChooser(intent, "Profile Export");
        chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(chooser);
    }

    /**
     * Sets or releases WakeLock to keep the processor running
     * even when the screen is off. This is important for maintaining VPN connections in the background.
     *
     * @param context Application context
     * @param active Set (true) or release (false) the lock
     */
    public static void setWakeLock(Context context, boolean active) {
        if (context == null) {
            Log.e(TAG, "setWakeLock: Context is null");
            return;
        }

        try {
            if (active) {
                if (wakeLock == null || !wakeLock.isHeld()) {
                    PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
                    wakeLock = pm.newWakeLock(
                        PowerManager.PARTIAL_WAKE_LOCK | PowerManager.ON_AFTER_RELEASE,
                        "RaccoonLine:VpnWakeLock");
                    wakeLock.setReferenceCounted(false);
                    // Acquire indefinitely
                    wakeLock.acquire();
                    Log.d(TAG, "WakeLock acquired successfully");
                }

                // Also acquire WiFi lock
                acquireWifiLock(context);
            } else {
                if (wakeLock != null && wakeLock.isHeld()) {
                    wakeLock.release();
                    Log.d(TAG, "WakeLock released");
                    wakeLock = null;
                }

                // Release WiFi lock
                releaseWifiLock();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error working with wake lock: " + e.getMessage());
        }
    }

    /**
     * Acquires WiFi lock to maintain active state of WiFi radio.
     * This is important for maintaining WebSocket connections in the background.
     */
    public static void acquireWifiLock(Context context) {
        if (context == null) {
            return;
        }

        try {
            if (wifiLock == null || !wifiLock.isHeld()) {
                WifiManager wifiManager = (WifiManager) context.getApplicationContext()
                    .getSystemService(Context.WIFI_SERVICE);

                wifiLock = wifiManager.createWifiLock(
                    WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                    "RaccoonLine:WebSocketWifiLock");
                wifiLock.setReferenceCounted(false);
                wifiLock.acquire();
                Log.d(TAG, "WiFi lock acquired successfully");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error acquiring WiFi lock: " + e.getMessage());
        }
    }

    /**
     * Releases WiFi lock when it's no longer needed
     */
    public static void releaseWifiLock() {
        try {
            if (wifiLock != null && wifiLock.isHeld()) {
                wifiLock.release();
                wifiLock = null;
                Log.d(TAG, "WiFi lock released");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error releasing WiFi lock: " + e.getMessage());
        }
    }

    /**
     * Maintains WebSocket connections by registering a special
     * network callback and configuring socket parameters
     *
     * @param context Application context
     */
    public static void enableWebSocketKeepAlive(Context context) {
        if (context == null) {
            return;
        }

        // Keep WiFi in active state
        acquireWifiLock(context);

        // Register special network callback for WebSocket
        registerNetworkCallbackForWebSockets(context);

        // Set socket parameters
        try {
            // Set system properties to enable keepalive support
            System.setProperty("http.keepAlive", "true");
            System.setProperty("http.maxConnections", "5");
        } catch (Exception e) {
            Log.e(TAG, "Error setting properties for WebSocket keepalive: " + e.getMessage());
        }
    }

    /**
     * Registers a network callback that specifically helps
     * with WebSocket connections
     */
    private static void registerNetworkCallbackForWebSockets(Context context) {
        try {
            ConnectivityManager connectivityManager =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Create a more specific request for WebSockets
                NetworkRequest.Builder builder = new NetworkRequest.Builder();
                builder.addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);
                builder.addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED);
                builder.addCapability(NetworkCapabilities.NET_CAPABILITY_TRUSTED);
                builder.addTransportType(NetworkCapabilities.TRANSPORT_WIFI);
                builder.addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR);

                ConnectivityManager.NetworkCallback wsNetworkCallback = new ConnectivityManager.NetworkCallback() {
                    @Override
                    public void onAvailable(Network network) {
                        super.onAvailable(network);
                        Log.d(TAG, "WebSocket network available");

                        // This is the key part: bind the process to this network
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            connectivityManager.bindProcessToNetwork(network);
                            Log.d(TAG, "Process bound to network for WebSockets");
                        } else {
                            // For older versions
                            ConnectivityManager.setProcessDefaultNetwork(network);
                        }
                    }

                    @Override
                    public void onLost(Network network) {
                        super.onLost(network);
                        Log.d(TAG, "WebSocket network lost");
                    }
                };

                // Register callback - use requestNetwork instead of registerNetworkCallback
                // This actively requests a network connection that meets our requirements
                connectivityManager.requestNetwork(builder.build(), wsNetworkCallback);
                Log.d(TAG, "WebSocket network callback registered with requestNetwork");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error registering network callback for WebSocket: " + e.getMessage());
        }
    }

    /**
     * Requests exemption from battery optimization for the application.
     * This is critically important for proper operation of VPN applications in the background.
     *
     * @param activity Current activity
     * @return true if already exempted or request sent, false otherwise
     */
    public static boolean requestBatteryOptimizationExemption(Activity activity) {
        if (activity == null) {
            Log.e(TAG, "requestBatteryOptimizationExemption: Activity is null");
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                String packageName = activity.getPackageName();
                PowerManager pm = (PowerManager) activity.getSystemService(Context.POWER_SERVICE);

                if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                    Intent intent = new Intent();
                    intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                    intent.setData(Uri.parse("package:" + packageName));
                    activity.startActivity(intent);
                    return true;
                } else {
                    // Already exempted from battery optimization
                    return true;
                }
            } catch (Exception e) {
                Log.e(TAG, "Error requesting battery optimization exemption: " + e.getMessage());
                return false;
            }
        }
        return false;
    }

    /**
     * Checks if the application is exempted from battery optimization
     *
     * @param context Application context
     * @return true if exempted, false otherwise
     */
    public static boolean isBatteryOptimizationExempted(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            return pm.isIgnoringBatteryOptimizations(context.getPackageName());
        }
        return true; // Not an issue on older versions
    }

    /**
     * Registers a network callback to maintain network connection.
     * This is especially important for Android 14/15, which aggressively
     * restrict background network usage.
     *
     * @param context Application context
     */
    public static void registerNetworkCallback(Context context) {
        if (context == null) {
            Log.e(TAG, "registerNetworkCallback: Context is null");
            return;
        }

        if (networkCallback != null) {
            // Already registered
            return;
        }

        try {
            ConnectivityManager connectivityManager =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NetworkRequest.Builder builder = new NetworkRequest.Builder();
                builder.addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);

                networkCallback = new ConnectivityManager.NetworkCallback() {
                    @Override
                    public void onAvailable(Network network) {
                        super.onAvailable(network);
                        Log.d(TAG, "Network available");
                    }

                    @Override
                    public void onLost(Network network) {
                        super.onLost(network);
                        Log.d(TAG, "Network lost");
                    }
                };

                connectivityManager.registerNetworkCallback(builder.build(), networkCallback);
                Log.d(TAG, "Network callback registered");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error registering network callback: " + e.getMessage());
        }
    }

    /**
     * Unregisters network callback when it's no longer needed
     *
     * @param context Application context
     */
    public static void unregisterNetworkCallback(Context context) {
        if (context == null || networkCallback == null) {
            return;
        }

        try {
            ConnectivityManager connectivityManager =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            connectivityManager.unregisterNetworkCallback(networkCallback);
            networkCallback = null;
            Log.d(TAG, "Network callback unregistered");
        } catch (Exception e) {
            Log.e(TAG, "Error unregistering network callback: " + e.getMessage());
        }
    }

    // Simplified method for determining MIUI
    private static boolean isMIUI() {
        return Build.MANUFACTURER.equalsIgnoreCase("Xiaomi");
    }

    // Method for setting up status bar on all devices
    public static void setupStatusBar(final Activity activity) {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Window window = activity.getWindow();
                boolean isMiuiDevice = isMIUI();

                Log.d("AndroidUtils", "Setting up status bar, MIUI: " + isMiuiDevice);

                // Common settings for all versions
                window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
                window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);

                // Set status bar color
                if (isMiuiDevice && Build.VERSION.SDK_INT < 30) {
                    // For MIUI, set slightly opaque background for better support of white icons
                    window.setStatusBarColor(Color.parseColor("#20000000")); // 12% opacity

                    // Try to set white icons via system flags
                    View decorView = window.getDecorView();
                    int flags = decorView.getSystemUiVisibility();
                    flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR; // Remove light icons flag
                    decorView.setSystemUiVisibility(flags);

                    // Try to use MIUI API via reflection with error handling
                    try {
                        Class<?> clazz = window.getClass();
                        Class<?> layoutParams = Class.forName("android.view.MiuiWindowManager$LayoutParams");
                        Field field = layoutParams.getField("EXTRA_FLAG_STATUS_BAR_DARK_MODE");
                        int darkModeFlag = field.getInt(layoutParams);
                        Method extraFlagField = clazz.getMethod("setExtraFlags", int.class, int.class);
                        extraFlagField.invoke(window, 0, darkModeFlag); // 0 = not dark mode (white icons)
                    } catch (Exception e) {
                        Log.e("AndroidUtils", "Failed to set MIUI status bar: " + e.getMessage());
                    }
                } else {
                    // For non-MIUI devices, set fully transparent status bar
                    window.setStatusBarColor(Color.TRANSPARENT);
                }

                // Set white icons depending on Android version
                if (Build.VERSION.SDK_INT >= 30) {
                    // Android 11+ (API 30+)
                    View decorView = window.getDecorView();
                    if (decorView.getWindowInsetsController() != null) {
                        window.setDecorFitsSystemWindows(false);
                        decorView.getWindowInsetsController().setSystemBarsAppearance(
                            0, // Reset all flags
                            WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS // Mask for light icons
                        );
                    }
                } else {
                    // Android 9-10 (API 28-29)
                    View decorView = window.getDecorView();
                    int uiOptions = decorView.getSystemUiVisibility();

                    // Add flags for display under status bar
                    uiOptions |= View.SYSTEM_UI_FLAG_LAYOUT_STABLE;
                    uiOptions |= View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;

                    // Remove light icons flag (will be white icons)
                    uiOptions &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;

                    decorView.setSystemUiVisibility(uiOptions);
                }

                int statusBarHeight = getStatusBarHeight(activity);
                Log.d("AndroidUtils", "Status bar height: " + statusBarHeight);
            }
        });
    }

    // Method for getting status bar height
    public static int getStatusBarHeight(Activity activity) {
        if (activity == null) return 0;

        Resources resources = activity.getResources();
        int resourceId = resources.getIdentifier("status_bar_height", "dimen", "android");

        if (resourceId > 0) {
            return resources.getDimensionPixelSize(resourceId);
        }

        // Return approximate value if unable to get from resources
        return (int)(24 * resources.getDisplayMetrics().density);
    }
}
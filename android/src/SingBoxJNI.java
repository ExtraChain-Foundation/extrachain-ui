package com.raccoonline.vpnapp;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.util.Log;
import org.json.JSONObject;
import android.net.VpnService;
import java.util.ArrayList;
import java.util.List;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.content.pm.PackageManager;
import android.os.Build;
import android.app.AlertDialog;

public class SingBoxJNI {
    private static final String TAG = "SingBoxJNI";
    private Context context;
    private TrafficMonitor trafficMonitor;
    private static final int VPN_REQUEST_CODE = 1001;
    private static final int PERMISSIONS_REQUEST_CODE = 1002;

    // Define required permissions based on Android version
    private static final String[] BASE_PERMISSIONS = new String[] {
        // android.Manifest.permission.INTERNET,
        // android.Manifest.permission.ACCESS_NETWORK_STATE,
        // android.Manifest.permission.FOREGROUND_SERVICE,
        // android.Manifest.permission.WAKE_LOCK,
        // android.Manifest.permission.ACCESS_WIFI_STATE
    };

    // Location permissions (needed for WiFi state on Android 10+)
    private static final String[] LOCATION_PERMISSIONS = new String[] {
        // android.Manifest.permission.ACCESS_FINE_LOCATION,
        // android.Manifest.permission.ACCESS_COARSE_LOCATION
    };

    // Additional permissions for Android 10+ (API 29+)
    private static final String[] ANDROID_10_PERMISSIONS = new String[] {
        // android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
    };

    // Additional permissions for Android 13+ (API 33+)
    private static final String[] ANDROID_13_PERMISSIONS = new String[] {
        // android.Manifest.permission.POST_NOTIFICATIONS
    };

    public void initialize(Context ctx) {
        Log.d(TAG, "Initializing SingBoxJNI with libbox support");
        this.context = ctx.getApplicationContext();

        // Initialize traffic monitor with app UID
        try {
            int uid = ctx.getApplicationInfo().uid;
            trafficMonitor = new TrafficMonitor(uid);
            Log.d(TAG, "Traffic monitor initialized for UID: " + uid);
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize traffic monitor", e);
        }
    }

    public boolean hasVpnPermission(Context ctx) {
        // First check VPN permission
        Intent intent = android.net.VpnService.prepare(ctx);
        boolean hasVpnPermission = (intent == null);

        if (!hasVpnPermission) {
            Log.d(TAG, "VPN permission not granted");
            return false;
        }

        // Then check all other permissions
        return checkAllPermissions(ctx);
    }

    public boolean requestVpnPermission(Activity activity) {
        Log.d(TAG, "Checking and requesting all permissions");

        // Get only the permissions we actually need based on Android version
        String[] missingPermissions = getMissingPermissions(activity);

        if (missingPermissions.length > 0) {
            Log.d(TAG, "Requesting " + missingPermissions.length + " missing permissions:");
            for (String perm : missingPermissions) {
                Log.d(TAG, "  - " + perm);
            }

            // Check if we should show rationale
            boolean shouldShowRationale = false;
            for (String permission : missingPermissions) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
                    shouldShowRationale = true;
                    break;
                }
            }

            if (shouldShowRationale) {
                // Show explanation dialog
                new AlertDialog.Builder(activity)
                    .setTitle("Permissions Required")
                    .setMessage("This VPN app needs the following permissions:\n\n" +
                               "• Location: Required to access WiFi network information\n" +
                               "• Notifications: To show VPN connection status\n\n" +
                               "Please grant these permissions to use the VPN.")
                    .setPositiveButton("OK", (dialog, which) -> {
                        // Reset the result flag before requesting
                        if (activity instanceof QtActivityExtension) {
                            QtActivityExtension.resetPermissionResult();
                        }
                        ActivityCompat.requestPermissions(activity, missingPermissions, PERMISSIONS_REQUEST_CODE);
                    })
                    .setNegativeButton("Cancel", null)
                    .show();
            } else {
                // Reset the result flag before requesting
                if (activity instanceof QtActivityExtension) {
                    QtActivityExtension.resetPermissionResult();
                }
                // Request permissions directly
                ActivityCompat.requestPermissions(activity, missingPermissions, PERMISSIONS_REQUEST_CODE);
            }
            return true;
        }

        // If all regular permissions are granted, check VPN permission
        Intent intent = VpnService.prepare(activity);
        if (intent != null) {
            Log.d(TAG, "Requesting VPN permission");
            if (activity instanceof QtActivityExtension) {
                QtActivityExtension.resetPermissionResult();
            }
            activity.startActivityForResult(intent, VPN_REQUEST_CODE);
            return true;
        }

        // All permissions already granted
        Log.d(TAG, "All permissions including VPN already granted");
        return false;
    }

    // Check if we're waiting for permission result (for polling from C++)
    public boolean isWaitingForPermissionResult() {
        return QtActivityExtension.isWaitingForResult();
    }

    // Get the last permission result (for polling from C++)
    public boolean getLastPermissionResult() {
        return QtActivityExtension.getLastPermissionResult();
    }

    // PRIVATE: Check all required permissions
    private boolean checkAllPermissions(Context ctx) {
        List<String> permissions = getAllRequiredPermissions();

        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(ctx, permission)
                != PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Missing permission: " + permission);
                return false;
            }
        }

        Log.d(TAG, "All required permissions granted");
        return true;
    }

    // PRIVATE: Get list of missing permissions
    private String[] getMissingPermissions(Context ctx) {
        List<String> permissions = getAllRequiredPermissions();
        List<String> missingPermissions = new ArrayList<>();

        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(ctx, permission)
                != PackageManager.PERMISSION_GRANTED) {
                missingPermissions.add(permission);
            }
        }

        return missingPermissions.toArray(new String[0]);
    }

    // PRIVATE: Get all required permissions based on Android version
    private List<String> getAllRequiredPermissions() {
        List<String> permissions = new ArrayList<>();

        // Add base permissions
        for (String permission : BASE_PERMISSIONS) {
            permissions.add(permission);
        }

        // Add location permissions (needed for WiFi state)
        for (String permission : LOCATION_PERMISSIONS) {
            permissions.add(permission);
        }

        // Add Android 10+ permissions only if needed
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Note: ACCESS_BACKGROUND_LOCATION should only be requested after foreground location is granted
            // For now, we'll skip it to simplify the flow
            // for (String permission : ANDROID_10_PERMISSIONS) {
            //     permissions.add(permission);
            // }
        }

        // Add Android 13+ permissions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            for (String permission : ANDROID_13_PERMISSIONS) {
                permissions.add(permission);
            }
        }

        return permissions;
    }

    public boolean startVpn(String configJson) {
        Log.d(TAG, "Starting VPN with libbox - config length: " + (configJson != null ? configJson.length() : 0));

        // Check all permissions before starting
        if (!checkAllPermissions(context)) {
            Log.e(TAG, "Cannot start VPN: missing required permissions");
            return false;
        }

        // Check VPN permission
        Intent vpnIntent = VpnService.prepare(context);
        if (vpnIntent != null) {
            Log.e(TAG, "Cannot start VPN: VPN permission not granted");
            return false;
        }

        if (configJson == null || configJson.trim().isEmpty()) {
            Log.e(TAG, "Invalid configuration provided");
            return false;
        }

        try {
            JSONObject jsonObject = new JSONObject(configJson);
            Log.d(TAG, "Configuration JSON is valid, starting libbox service");
        } catch (Exception e) {
            Log.e(TAG, "Invalid JSON configuration", e);
            return false;
        }

        try {
            Intent intent = new Intent(context, VpnServiceWrapper.class);
            intent.setAction("START_VPN");
            intent.putExtra("config", configJson);

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(intent);
            } else {
                context.startService(intent);
            }

            Log.d(TAG, "VPN service start requested");

            // Reset traffic baseline when VPN starts
            if (trafficMonitor != null) {
                trafficMonitor.resetBaseline();
            }

            return true;
        } catch (Exception e) {
            Log.e(TAG, "Failed to start VPN service", e);
            return false;
        }
    }

    public boolean stopVpn() {
        Log.d(TAG, "Stopping VPN");

        try {
            Intent intent = new Intent(context, VpnServiceWrapper.class);
            intent.setAction("STOP_VPN");
            context.startService(intent);
            Log.d(TAG, "VPN stop requested");
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Failed to stop VPN", e);
            return false;
        }
    }

    public boolean isVpnRunning() {
        try {
            return VpnServiceWrapper.Companion.isRunning();
        } catch (Exception e) {
            Log.e(TAG, "Failed to check VPN status", e);
            return false;
        }
    }

    public String getTrafficStats() {
        if (trafficMonitor != null) {
            String stats = trafficMonitor.getTrafficStatsJson();
            Log.d(TAG, "Traffic stats: " + stats);
            return stats;
        }

        String stats = "{}";
        Log.d(TAG, "Traffic stats: " + stats);
        return stats;
    }

    public void cleanup() {
        Log.d(TAG, "Cleaning up SingBoxJNI");
        trafficMonitor = null;
    }
}

package com.raccoonline.vpnapp;

import org.qtproject.qt.android.bindings.QtActivity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import androidx.core.app.ActivityCompat;
import android.content.pm.PackageManager;
import android.net.VpnService;

public class QtActivityExtension extends QtActivity {
    private static final String TAG = "QtActivityExtension";
    private static final int VPN_REQUEST_CODE = 1001;
    private static final int PERMISSIONS_REQUEST_CODE = 1002;

    // Static instance for callbacks
    private static QtActivityExtension instance;

    // Result flags
    private static boolean lastPermissionResult = false;
    private static boolean waitingForPermissionResult = false;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instance = this;
        Log.d(TAG, "QtActivityExtension created");
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (instance == this) {
            instance = null;
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d(TAG, "onActivityResult: requestCode=" + requestCode + ", resultCode=" + resultCode);

        if (requestCode == VPN_REQUEST_CODE) {
            // Handle VPN permission result
            boolean granted = (resultCode == RESULT_OK);
            Log.d(TAG, "VPN permission result: " + granted);

            // Store result for polling
            lastPermissionResult = granted;
            waitingForPermissionResult = false;
        }

        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        Log.d(TAG, "onRequestPermissionsResult: requestCode=" + requestCode);

        if (requestCode == PERMISSIONS_REQUEST_CODE) {
            boolean allGranted = true;

            // Check if all permissions were granted
            for (int i = 0; i < permissions.length; i++) {
                Log.d(TAG, "Permission " + permissions[i] + ": " +
                    (grantResults[i] == PackageManager.PERMISSION_GRANTED ? "GRANTED" : "DENIED"));

                if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                }
            }

            Log.d(TAG, "All permissions granted: " + allGranted);

            // Store result for polling
            lastPermissionResult = allGranted;
            waitingForPermissionResult = false;

            // If all permissions granted, automatically check for VPN permission
            if (allGranted) {
                checkAndRequestVpnIfNeeded();
            }
        }

        // IMPORTANT: Don't call super for our custom request code
        // This prevents the "Found no valid pending permission request" warning
        if (requestCode != PERMISSIONS_REQUEST_CODE) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        }
    }

    // Method to check and request VPN permission after regular permissions
    private void checkAndRequestVpnIfNeeded() {
        Intent intent = VpnService.prepare(this);
        if (intent != null) {
            Log.d(TAG, "Requesting VPN permission after regular permissions");
            waitingForPermissionResult = true;
            startActivityForResult(intent, VPN_REQUEST_CODE);
        } else {
            Log.d(TAG, "VPN permission already granted");
            lastPermissionResult = true;
            waitingForPermissionResult = false;
        }
    }

    // Static methods for JNI to check permission results
    public static boolean isWaitingForResult() {
        return waitingForPermissionResult;
    }

    public static boolean getLastPermissionResult() {
        return lastPermissionResult;
    }

    public static void resetPermissionResult() {
        waitingForPermissionResult = true;
        lastPermissionResult = false;
    }

    // Static method to get the current instance
    public static QtActivityExtension getInstance() {
        return instance;
    }
}

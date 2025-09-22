package com.raccoonline.vpnapp;

import android.net.TrafficStats;
import android.util.Log;
import org.json.JSONObject;

public class TrafficMonitor {
    private static final String TAG = "TrafficMonitor";

    private int uid;
    private long baselineTxBytes = 0;
    private long baselineRxBytes = 0;
    private long sessionStartTime = 0;

    public TrafficMonitor(int appUid) {
        this.uid = appUid;
        this.sessionStartTime = System.currentTimeMillis();

        // Set baseline when monitor is created
        baselineTxBytes = TrafficStats.getUidTxBytes(uid);
        baselineRxBytes = TrafficStats.getUidRxBytes(uid);

        // Handle -1 (unsupported) case
        if (baselineTxBytes == TrafficStats.UNSUPPORTED) baselineTxBytes = 0;
        if (baselineRxBytes == TrafficStats.UNSUPPORTED) baselineRxBytes = 0;
    }

    // Get current traffic stats as JSON
    public String getTrafficStatsJson() {
        try {
            JSONObject stats = new JSONObject();

            // Get current values
            long currentTxBytes = TrafficStats.getUidTxBytes(uid);
            long currentRxBytes = TrafficStats.getUidRxBytes(uid);

            // Handle unsupported case
            if (currentTxBytes == TrafficStats.UNSUPPORTED) currentTxBytes = 0;
            if (currentRxBytes == TrafficStats.UNSUPPORTED) currentRxBytes = 0;

            // Calculate session totals (current - baseline)
            long sessionTx = currentTxBytes - baselineTxBytes;
            long sessionRx = currentRxBytes - baselineRxBytes;

            // Ensure non-negative values
            if (sessionTx < 0) sessionTx = 0;
            if (sessionRx < 0) sessionRx = 0;

            // Add raw values to JSON
            stats.put("download", sessionRx);
            stats.put("upload", sessionTx);
            stats.put("total", sessionRx + sessionTx);
            stats.put("sessionTime", System.currentTimeMillis() - sessionStartTime);

            // Add formatted values for display
            stats.put("downloadFormatted", formatBytes(sessionRx));
            stats.put("uploadFormatted", formatBytes(sessionTx));
            stats.put("totalFormatted", formatBytes(sessionRx + sessionTx));

            return stats.toString();

        } catch (Exception e) {
            Log.e(TAG, "Error creating stats JSON", e);
            return "{}";
        }
    }

    // Reset baseline (call when VPN starts)
    public void resetBaseline() {
        baselineTxBytes = TrafficStats.getUidTxBytes(uid);
        baselineRxBytes = TrafficStats.getUidRxBytes(uid);
        sessionStartTime = System.currentTimeMillis();

        if (baselineTxBytes == TrafficStats.UNSUPPORTED) baselineTxBytes = 0;
        if (baselineRxBytes == TrafficStats.UNSUPPORTED) baselineRxBytes = 0;

        Log.d(TAG, "Baseline reset - TX: " + baselineTxBytes + ", RX: " + baselineRxBytes);
    }

    // Format bytes to human readable string
    private String formatBytes(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        } else if (bytes < 1024 * 1024) {
            return String.format("%.2f KB", bytes / 1024.0);
        } else if (bytes < 1024 * 1024 * 1024) {
            return String.format("%.2f MB", bytes / (1024.0 * 1024));
        } else {
            return String.format("%.2f GB", bytes / (1024.0 * 1024 * 1024));
        }
    }
}

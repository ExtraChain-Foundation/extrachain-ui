package com.raccoonline.vpnapp;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import androidx.core.content.FileProvider;
import java.io.File;

public class UpdaterHelper {
    private static Context appContext;
    
    public static void setContext(Context context) {
        appContext = context;
    }
    
    public static void installApk(String filePath) {
        try {
            if (appContext == null) {
                return;
            }
            
            File apkFile = new File(filePath);
            
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                String authority = appContext.getPackageName() + ".fileprovider";
                Uri uri = FileProvider.getUriForFile(appContext, authority, apkFile);
                intent.setDataAndType(uri, "application/vnd.android.package-archive");
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            } else {
                Uri uri = Uri.fromFile(apkFile);
                intent.setDataAndType(uri, "application/vnd.android.package-archive");
            }
            
            appContext.startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
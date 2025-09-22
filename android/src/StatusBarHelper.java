package com.raccoonline.vpnapp;

import android.app.Activity;
import android.content.Context;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.view.DisplayCutout;
import android.graphics.Rect;
import android.content.res.Configuration;

public class StatusBarHelper {

    private Activity activity;

    public StatusBarHelper(Activity activity) {
        this.activity = activity;
    }

    public float convertPxToDp(float px) {
        float density = activity.getResources().getDisplayMetrics().density;
        return px / density;
    }

    public float getStatusBarHeight() {
        int statusBarHeight = 0;

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            WindowInsets insets = activity.getWindow().getDecorView().getRootWindowInsets();

            if (insets != null) {
                statusBarHeight = insets.getStableInsetTop();
            }
        } else {
            // Используем устаревший метод для устройств до Android M
            int resourceId = activity.getResources().getIdentifier("status_bar_height", "dimen", "android");

            if (resourceId > 0) {
                statusBarHeight = activity.getResources().getDimensionPixelSize(resourceId);
            }
        }

        return convertPxToDp(statusBarHeight);
    }

    // Получить высоту навигационной панели
    public float getNavigationBarHeight() {
        int navigationBarHeight = 0;

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            WindowInsets insets = activity.getWindow().getDecorView().getRootWindowInsets();

            if (insets != null) {
                navigationBarHeight = insets.getStableInsetBottom();
            }
        } else {
            // Используем устаревший метод для устройств до Android M
            if (hasNavigationBar()) {
                int resourceId = activity.getResources().getIdentifier("navigation_bar_height", "dimen", "android");
                if (resourceId > 0) {
                    navigationBarHeight = activity.getResources().getDimensionPixelSize(resourceId);
                }
            }
        }

        return convertPxToDp(navigationBarHeight);
    }

    // Проверить, есть ли навигационная панель
    public boolean hasNavigationBar() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            WindowInsets insets = activity.getWindow().getDecorView().getRootWindowInsets();
            if (insets != null) {
                return insets.getStableInsetBottom() > 0;
            }
        }

        // Для старых версий Android используем проверку ресурсов
        int id = activity.getResources().getIdentifier("config_showNavigationBar", "bool", "android");
        if (id > 0) {
            return activity.getResources().getBoolean(id);
        }

        // Альтернативная проверка для некоторых устройств
        boolean hasMenuKey = android.view.ViewConfiguration.get(activity).hasPermanentMenuKey();
        boolean hasBackKey = android.view.KeyCharacterMap.deviceHasKey(android.view.KeyEvent.KEYCODE_BACK);
        
        return !hasMenuKey && !hasBackKey;
    }

    // Получить высоту навигационной панели в зависимости от ориентации
    public float getNavigationBarHeightForOrientation() {
        if (!hasNavigationBar()) {
            return 0;
        }

        String resourceName;
        int orientation = activity.getResources().getConfiguration().orientation;
        
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            resourceName = "navigation_bar_height_landscape";
        } else {
            resourceName = "navigation_bar_height";
        }

        int resourceId = activity.getResources().getIdentifier(resourceName, "dimen", "android");
        if (resourceId > 0) {
            return convertPxToDp(activity.getResources().getDimensionPixelSize(resourceId));
        }

        return 0;
    }

    // Проверить, используется ли жестовая навигация
    public boolean isGestureNavigationEnabled() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            WindowInsets insets = activity.getWindow().getDecorView().getRootWindowInsets();
            if (insets != null) {
                // В жестовой навигации bottom inset обычно меньше обычной высоты навигационной панели
                int bottomInset = insets.getSystemWindowInsetBottom();
                int stableBottomInset = insets.getStableInsetBottom();
                
                // Если разница значительная, скорее всего используется жестовая навигация
                return Math.abs(bottomInset - stableBottomInset) > 20;
            }
        }
        return false;
    }

    public boolean hasNotch() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            WindowInsets windowInsets = activity.getWindow().getDecorView().getRootWindowInsets();

            if (windowInsets != null) {
                DisplayCutout displayCutout = windowInsets.getDisplayCutout();
                return displayCutout != null && !displayCutout.getBoundingRects().isEmpty();
            }
        }

        return false;
    }

    public float[] getNotchSize() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            WindowInsets windowInsets = activity.getWindow().getDecorView().getRootWindowInsets();

            if (windowInsets != null) {
                DisplayCutout displayCutout = windowInsets.getDisplayCutout();

                if (displayCutout != null && !displayCutout.getBoundingRects().isEmpty()) {
                    Rect rect = displayCutout.getBoundingRects().get(0);
                    float notchWidth = convertPxToDp(rect.right - rect.left); // Ширина выреза
                    float notchHeight = convertPxToDp(rect.bottom - rect.top); // Высота выреза
                    float x = convertPxToDp(rect.left); // X координата начала выреза
                    float y = convertPxToDp(rect.top); // Y координата начала выреза
                    return new float[] {
                        x, y, notchWidth, notchHeight
                    };
                }
            }
        }

        return new float[] {
            0, 0, 0, 0
        };
    }

    // Получить все отступы системы (статус бар, навигационная панель, боковые отступы)
    public float[] getSystemWindowInsets() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            WindowInsets insets = activity.getWindow().getDecorView().getRootWindowInsets();
            if (insets != null) {
                float left = convertPxToDp(insets.getSystemWindowInsetLeft());
                float top = convertPxToDp(insets.getSystemWindowInsetTop());
                float right = convertPxToDp(insets.getSystemWindowInsetRight());
                float bottom = convertPxToDp(insets.getSystemWindowInsetBottom());
                
                return new float[] { left, top, right, bottom };
            }
        }
        
        // Для старых версий возвращаем только статус бар и навигационную панель
        return new float[] { 
            0, 
            getStatusBarHeight(), 
            0, 
            getNavigationBarHeight() 
        };
    }
}

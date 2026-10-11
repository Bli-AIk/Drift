package org.cutwire.drift;

import android.app.Activity;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;

// Whether Android is running as a desktop: Samsung DeX, a ChromeOS device, or an Android PC.
// These get the desktop layout even when the screen size alone would not say so (DeX on a
// phone can report the phone's own display at launch).
public final class DesktopMode {
    private DesktopMode() {}

    public static boolean isDesktop(Context context) {
        PackageManager pm = context.getPackageManager();
        if (pm.hasSystemFeature("android.hardware.type.pc")
                || pm.hasSystemFeature("org.chromium.arc")
                || pm.hasSystemFeature("org.chromium.arc.device_management"))
            return true;
        return isSamsungDex(context.getResources().getConfiguration());
    }

    // The desktop layout has no portrait arrangement. DeX and ChromeOS windows ignore the request.
    public static void lockLandscape(Context context) {
        if (!(context instanceof Activity))
            return;
        final Activity activity = (Activity) context;
        activity.runOnUiThread(() -> activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE));
    }

    // Samsung exposes DeX only through these non-SDK Configuration fields.
    private static boolean isSamsungDex(Configuration config) {
        try {
            Class<?> cls = config.getClass();
            int enabled = cls.getField("SEM_DESKTOP_MODE_ENABLED").getInt(cls);
            int current = cls.getField("semDesktopModeEnabled").getInt(config);
            return current == enabled;
        } catch (ReflectiveOperationException | RuntimeException e) {
            return false;
        }
    }
}

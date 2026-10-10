package org.cutwire.drift;

import android.content.Context;
import android.content.Intent;

// Relaunches Drift so Shell.qml can build the other shell. The new task is started before this
// process is killed; CLEAR_TASK keeps the old activity from coming back on top of it.
public final class AppRestart {
    private AppRestart() {}

    public static void restart(Context context) {
        Intent intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
        if (intent == null)
            return;
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        context.startActivity(intent);
        android.os.Process.killProcess(android.os.Process.myPid());
    }
}

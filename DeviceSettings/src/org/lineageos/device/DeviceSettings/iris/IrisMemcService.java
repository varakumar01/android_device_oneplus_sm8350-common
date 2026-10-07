/*
 * SPDX-FileCopyrightText: 2025 The Nameless-CLO Project
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.device.DeviceSettings.iris;

import android.app.ActivityTaskManager;
import android.app.Service;
import android.app.TaskStackListener;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.os.PowerManager;
import android.util.ArraySet;
import android.util.Log;

import androidx.preference.PreferenceManager;

import org.lineageos.device.DeviceSettings.R;

import java.util.ArrayList;
import java.util.Set;

import vendor.pixelworks.hardware.display.V1_0.IIris;

/**
 * Motion smoothing (MEMC) on the Pixelworks Iris5 chip.
 *
 * The chip sits in analog bypass until it is told otherwise. While one of the
 * video player activities in R.array.iris_memc_activities is on top, this
 * service takes it out of bypass and selects the MEMC mode through the Iris
 * HAL; when the activity leaves, the screen turns off or battery saver comes
 * on, it puts the chip back in bypass.
 */
public class IrisMemcService extends Service {

    private static final String TAG = "IrisMemcService";

    public static final String KEY_MEMC = "iris_memc";

    // irisConfigureSet() types and values, see
    // hardware/pixelworks/interfaces (VendorConfig, HdrFormalType) and the
    // kernel's dsi_iris5_def.h (IRIS_ANALOG_BYPASS_MODE).
    private static final int TYPE_ANALOG_BYPASS = 56;
    private static final int TYPE_HDR_FORMAL = 258;
    private static final int HDR_FORMAL_NONE = 0;
    private static final int HDR_FORMAL_MEMC = 10;

    // Wait for the activity transition to end before switching the chip.
    private static final long ENTER_DELAY_MS = 600;

    private final Set<String> mActivities = new ArraySet<>();
    private HandlerThread mThread;
    private Handler mHandler;
    private IIris mIris;
    private boolean mInMemc;

    public static boolean isSupported(Context context) {
        return context.getResources().getBoolean(R.bool.config_irisMemcSupported);
    }

    public static boolean isEnabled(Context context) {
        return isSupported(context) && PreferenceManager.getDefaultSharedPreferences(context)
                .getBoolean(KEY_MEMC, false);
    }

    /** Starts or stops the service to match the user's setting. */
    public static void sync(Context context) {
        Intent intent = new Intent(context, IrisMemcService.class);
        if (isEnabled(context)) {
            context.startService(intent);
        } else {
            context.stopService(intent);
        }
    }

    private final TaskStackListener mTaskListener = new TaskStackListener() {
        @Override
        public void onTaskStackChanged() {
            scheduleUpdate(ENTER_DELAY_MS);
        }
    };

    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            scheduleUpdate(0);
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        for (String component : getResources().getStringArray(R.array.iris_memc_activities)) {
            mActivities.add(component.substring(component.indexOf('/') + 1));
        }

        mThread = new HandlerThread(TAG);
        mThread.start();
        mHandler = new Handler(mThread.getLooper());

        IntentFilter filter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
        filter.addAction(Intent.ACTION_USER_PRESENT);
        filter.addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED);
        registerReceiver(mReceiver, filter, null, mHandler, Context.RECEIVER_NOT_EXPORTED);

        try {
            ActivityTaskManager.getService().registerTaskStackListener(mTaskListener);
        } catch (Exception e) {
            Log.e(TAG, "Failed to register task stack listener", e);
        }
        scheduleUpdate(0);
    }

    @Override
    public void onDestroy() {
        try {
            ActivityTaskManager.getService().unregisterTaskStackListener(mTaskListener);
        } catch (Exception e) {
            Log.e(TAG, "Failed to unregister task stack listener", e);
        }
        unregisterReceiver(mReceiver);
        mHandler.removeCallbacksAndMessages(null);
        mHandler.post(() -> setMemc(false));
        mThread.quitSafely();
        super.onDestroy();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void scheduleUpdate(long delayMs) {
        mHandler.removeCallbacks(mUpdate);
        mHandler.postDelayed(mUpdate, delayMs);
    }

    private final Runnable mUpdate = () -> setMemc(wantMemc());

    private boolean wantMemc() {
        PowerManager pm = getSystemService(PowerManager.class);
        if (!pm.isInteractive() || pm.isPowerSaveMode()) {
            return false;
        }
        try {
            ActivityTaskManager.RootTaskInfo info =
                    ActivityTaskManager.getService().getFocusedRootTaskInfo();
            ComponentName top = info != null ? info.topActivity : null;
            return top != null && mActivities.contains(top.getClassName());
        } catch (Exception e) {
            Log.e(TAG, "Failed to get the top activity", e);
            return false;
        }
    }

    private void setMemc(boolean enable) {
        if (enable == mInMemc) {
            return;
        }
        boolean ok;
        if (enable) {
            ok = configure(TYPE_ANALOG_BYPASS, 0)
                    && configure(TYPE_HDR_FORMAL, HDR_FORMAL_MEMC, 0, 0);
        } else {
            ok = configure(TYPE_HDR_FORMAL, HDR_FORMAL_NONE)
                    && configure(TYPE_ANALOG_BYPASS, 1);
        }
        Log.i(TAG, "MEMC " + (enable ? "on" : "off") + (ok ? "" : " failed"));
        if (ok) {
            mInMemc = enable;
        }
    }

    private boolean configure(int type, int... values) {
        ArrayList<Integer> list = new ArrayList<>(values.length);
        for (int value : values) {
            list.add(value);
        }
        try {
            if (mIris == null) {
                mIris = IIris.getService(true);
            }
            int status = mIris.irisConfigureSet(type, list);
            Log.d(TAG, "irisConfigureSet(" + type + ", " + list + ") = " + status);
            return status >= 0;
        } catch (Exception e) {
            Log.e(TAG, "irisConfigureSet(" + type + ") failed", e);
            mIris = null;
            return false;
        }
    }
}

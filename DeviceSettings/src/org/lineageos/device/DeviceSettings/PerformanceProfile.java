/*
 * Copyright (C) 2026 The AxionOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.lineageos.device.DeviceSettings;

import android.os.AxKernelControl;
import android.os.AxKernelManager;
import android.os.SystemProperties;
import android.util.Log;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Applies a named performance profile (Performance / Balanced / Powersave)
 * across every CPU cluster AxKernelManager knows about, by driving the same
 * {@link AxKernelManager#setControlValue(String, int)} binder call the
 * AxionParts Kernel Manager UI uses for its raw per-cluster sliders. This is
 * not a second control mechanism -- it's a preset that writes the identical
 * governor/min/max ids, so a profile picked here is fully visible (and
 * further adjustable) from Kernel Manager afterward, and vice versa.
 *
 * Every frequency and governor value used is read at apply-time from each
 * control's own {@link AxKernelControl#getAvailableValues()} /
 * {@link AxKernelControl#getValueLabels()} -- nothing here is a hardcoded
 * frequency, since the real ladder is board-specific and only known at
 * runtime (see ax_kernel_manager_lahaina.xml's availablePath attributes).
 */
final class PerformanceProfile {

    private static final String TAG = "PerformanceProfile";

    static final int MODE_POWERSAVE = 0;
    static final int MODE_BALANCED = 1;
    static final int MODE_PERFORMANCE = 2;

    static final String KEY = "performance_profile";
    static final String DEFAULT_VALUE = String.valueOf(MODE_BALANCED);

    /**
     * Mirrors the currently-applied mode so other DeviceSettings preferences
     * (the vibrator-strength powersave cap) can read it without depending on
     * PowerTools' PowerProfileUtil, which this build doesn't ship. Reuses
     * PowerProfileUtil's exact 0/1/2 convention on purpose: this property
     * name and numbering already had a real, if previously dead, consumer
     * in DeviceSettings.java.
     */
    private static final String PROP_PERF_MODE_SAVED = "persist.sys.perf_mode_saved";

    private PerformanceProfile() {}

    /** Applies {@code mode} to every discovered CPU cluster and persists it. */
    static void apply(int mode) {
        AxKernelManager km = new AxKernelManager();
        List<AxKernelControl> controls;
        try {
            controls = km.getControls();
        } catch (RuntimeException e) {
            Log.e(TAG, "AxKernelManager unavailable, cannot apply profile " + mode, e);
            return;
        }
        if (controls.isEmpty()) {
            Log.w(TAG, "AxKernelManager returned no controls; nothing to apply");
            return;
        }

        Map<String, List<AxKernelControl>> clusters = new LinkedHashMap<>();
        for (AxKernelControl c : controls) {
            int type = c.getType();
            if (type == AxKernelControl.TYPE_CPU_MIN_FREQ
                    || type == AxKernelControl.TYPE_CPU_MAX_FREQ
                    || type == AxKernelControl.TYPE_CPU_GOVERNOR) {
                clusters.computeIfAbsent(c.getGroup(), g -> new ArrayList<>()).add(c);
            }
        }
        for (Map.Entry<String, List<AxKernelControl>> entry : clusters.entrySet()) {
            applyToCluster(km, entry.getKey(), entry.getValue(), mode);
        }

        SystemProperties.set(PROP_PERF_MODE_SAVED, String.valueOf(mode));
    }

    private static void applyToCluster(AxKernelManager km, String group,
            List<AxKernelControl> cluster, int mode) {
        AxKernelControl minControl = findByType(cluster, AxKernelControl.TYPE_CPU_MIN_FREQ);
        AxKernelControl maxControl = findByType(cluster, AxKernelControl.TYPE_CPU_MAX_FREQ);
        AxKernelControl govControl = findByType(cluster, AxKernelControl.TYPE_CPU_GOVERNOR);

        if (govControl != null) {
            String wanted = governorNameForMode(mode);
            int govValue = findGovernorValue(govControl, wanted);
            if (govValue == Integer.MIN_VALUE && mode != MODE_BALANCED) {
                // This kernel doesn't have the exact governor we wanted (e.g.
                // no "powersave" compiled in for this cluster) -- fall back to
                // schedutil rather than silently leaving the old governor.
                govValue = findGovernorValue(govControl, "schedutil");
            }
            if (govValue != Integer.MIN_VALUE) {
                if (!km.setControlValue(govControl.getId(), govValue)) {
                    Log.w(TAG, group + ": failed to set governor to " + wanted);
                }
            } else {
                Log.w(TAG, group + ": no usable governor found among "
                        + Arrays.toString(govControl.getValueLabels()));
            }
        }

        if (maxControl != null) {
            int[] avail = sortedCopy(maxControl.getAvailableValues());
            if (avail.length > 0) {
                int target;
                switch (mode) {
                    case MODE_POWERSAVE:
                        // A conservative low step, not the absolute floor --
                        // still usable for light interaction, just capped.
                        target = avail[Math.max(0, avail.length / 3)];
                        break;
                    case MODE_PERFORMANCE:
                    case MODE_BALANCED:
                    default:
                        // Ceiling. Balanced relies on the governor (schedutil)
                        // to scale down under it, matching the kernel's own
                        // stock default now that nothing else caps this node.
                        target = avail[avail.length - 1];
                        break;
                }
                if (!km.setControlValue(maxControl.getId(), target)) {
                    Log.w(TAG, group + ": failed to set max freq to " + target);
                }
            }
        }

        if (minControl != null) {
            int[] avail = sortedCopy(minControl.getAvailableValues());
            if (avail.length > 0) {
                int target = (mode == MODE_PERFORMANCE)
                        ? avail[avail.length / 2]  // push the floor up
                        : avail[0];                // let the governor manage it
                if (!km.setControlValue(minControl.getId(), target)) {
                    Log.w(TAG, group + ": failed to set min freq to " + target);
                }
            }
        }
    }

    private static AxKernelControl findByType(List<AxKernelControl> cluster,
            @AxKernelControl.ControlType int type) {
        for (AxKernelControl c : cluster) {
            if (c.getType() == type) return c;
        }
        return null;
    }

    private static int findGovernorValue(AxKernelControl govControl, String wantedLabel) {
        String[] labels = govControl.getValueLabels();
        int[] values = govControl.getAvailableValues();
        for (int i = 0; i < labels.length && i < values.length; i++) {
            if (wantedLabel.equalsIgnoreCase(labels[i])) {
                return values[i];
            }
        }
        return Integer.MIN_VALUE;
    }

    private static String governorNameForMode(int mode) {
        switch (mode) {
            case MODE_POWERSAVE: return "powersave";
            case MODE_PERFORMANCE: return "performance";
            case MODE_BALANCED:
            default: return "schedutil";
        }
    }

    private static int[] sortedCopy(int[] values) {
        int[] copy = values.clone();
        Arrays.sort(copy);
        return copy;
    }
}

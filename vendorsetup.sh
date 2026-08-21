#!/bin/bash
#
# apply_patch() mechanism cherry-picked from Jammy555/android_device_oneplus_sm8350-common
# @Sakura (aox doesn't carry it). Auto-sourced by build/envsetup.sh for every
# device dir on the search path -- no manual step needed once synced.

PATCH_DIR="device/oneplus/sm8350-common/patches"

apply_patch() {
    local target_dir=$1
    local patch_file=$2
    local name=$3

    if [ -d "$target_dir" ]; then
        pushd "$target_dir" >/dev/null
        if git apply --reverse --check "$patch_file" >/dev/null 2>&1; then
            echo "${target_dir}: Already applied ($name)"
        elif git apply "$patch_file" >/dev/null 2>&1; then
            echo "${target_dir}: Successfully applied ($name)"
        else
            echo "========================================================================"
            echo " [!] MERGE CONFLICT / PATCH ERROR"
            echo " Target: ${target_dir}"
            echo " Patch Name: ${name}"
            echo " Patch File: ${patch_file}"
            echo " Details of failure:"
            git apply --check "$patch_file"
            echo "========================================================================"
        fi
        popd >/dev/null
    fi
}

apply_patch "system/core" "../../$PATCH_DIR/system_core_drop_schedtune_actions.patch" "libprocessgroup: drop dead schedtune actions (no CONFIG_SCHED_TUNE on this kernel)"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_udfps_ghbm_listener_public.patch" "SystemUI: make UdfpsSurfaceView.GhbmIlluminationListener public (needed cross-package by UdfpsTouchOverlay.kt)"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_thermal_sanity_bound.patch" "AxDiagnostics: exclude non-temperature/sentinel thermal zones (BCL/ibat, kernel THERMAL_TEMP_INVALID) from maxTemperature/hottest so a bogus reading can't trigger a false Thermal-emergency insight"

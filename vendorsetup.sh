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
apply_patch "packages/apps/AxionParts" "../../../$PATCH_DIR/packages_apps_axionparts_kernel_manager_performance_profile.patch" "Kernel Manager: add a governor-driven Performance profile picker (one profile per available CPU governor, Custom when the clusters disagree)"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_allow_app_downgrade.patch" "PackageInstaller/PMS: allow installing a lower versionCode over an existing app instead of failing INSTALL_FAILED_VERSION_DOWNGRADE"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_flashlight_fade_from_current_level.patch" "SystemUI: fade the torch out from its current level and stop the slider restarting the ramp"
apply_patch "lineage-sdk" "../$PATCH_DIR/lineage_sdk_advanced_reboot_default_on.patch" "PowerMenuUtils: default advanced_reboot to enabled (no def_advanced_reboot resource exists to seed it any other way)"
apply_patch "packages/apps/LineageParts" "../../../$PATCH_DIR/lineageparts_advanced_reboot_default_on.patch" "Power menu settings: default the Advanced restart switch preference to checked, matching the PowerMenuUtils default"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_stale_download_progress_ui.patch" "UpdaterViewModel: clear downloadProgress/downloadedMB/totalMB when status is DELETED/UNKNOWN so the progress bar and Delete button don't stay stuck on screen after deleting a download"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_resume_uses_resume_download.patch" "UpdaterViewModel.resumeDownload(): call UpdaterController.resumeDownload(), not startDownload() -- startDownload() always builds a fresh DownloadClient with the update's (possibly null) download URL"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_persist_download_url.patch" "UpdatesDbHelper: persist download_url so an update restored from the DB after a process restart keeps a usable URL instead of null"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_null_url_not_fatal.patch" "UpdaterController: catch IllegalStateException alongside IOException when building a DownloadClient, so a missing download URL routes to PAUSED_ERROR/Retry instead of crashing the app"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_delete_button_keyed_on_status.patch" "UpdateCard: show the Delete action for any status with a file on disk, not just downloadProgress > 0f, so a restored PAUSED entry a user chose to keep (auto-delete-on-install off) gets a working Delete button instead of only a crashing Resume"
apply_patch "axion_sdk" "../$PATCH_DIR/axion_sdk_battery_design_capacity_int_extra.patch" "DeviceInfoProvider.getBatteryCapacity(): read EXTRA_DESIGN_CAPACITY with getIntExtra, not getLongExtra -- the extra is an Int (BatteryService puts it as one, matching BatteryManager's own doc), so getLongExtra always ClassCastExceptions internally and silently returns the -1 default"
apply_patch "build/make" "../../$PATCH_DIR/build_make_ota_spl_downgrade_default.patch" "ota_from_target_files.py: default OPTIONS.spl_downgrade to True, so every built OTA gets SPL_DOWNGRADE=1 in payload_properties.txt and the installing device's update_engine skips CheckSPLDowngrade() regardless of which build produced the OTA"

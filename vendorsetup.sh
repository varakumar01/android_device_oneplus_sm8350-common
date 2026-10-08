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

apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_udfps_ghbm_listener_public.patch" "SystemUI: make UdfpsSurfaceView.GhbmIlluminationListener public (needed cross-package by UdfpsTouchOverlay.kt)"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_thermal_sanity_bound.patch" "AxDiagnostics: exclude non-temperature/sentinel thermal zones (socd/vbat/BCL/ibat, kernel THERMAL_TEMP_INVALID) from maxTemperature/hottest so a bogus reading can't trigger a false Thermal-emergency insight, and label them in the exported zone dump"
apply_patch "packages/apps/AxionParts" "../../../$PATCH_DIR/packages_apps_axionparts_kernel_manager_performance_profile.patch" "Kernel Manager: add a governor-driven Performance profile picker (one profile per available CPU governor, Custom when the clusters disagree)"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_allow_app_downgrade.patch" "PackageInstaller/PMS: allow installing a lower versionCode over an existing app instead of failing INSTALL_FAILED_VERSION_DOWNGRADE"
apply_patch "lineage-sdk" "../$PATCH_DIR/lineage_sdk_advanced_reboot_default_on.patch" "PowerMenuUtils: default advanced_reboot to enabled (no def_advanced_reboot resource exists to seed it any other way)"
apply_patch "packages/apps/LineageParts" "../../../$PATCH_DIR/lineageparts_advanced_reboot_default_on.patch" "Power menu settings: default the Advanced restart switch preference to checked, matching the PowerMenuUtils default"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_stale_download_progress_ui.patch" "UpdaterViewModel: clear downloadProgress/downloadedMB/totalMB when status is DELETED/UNKNOWN so the progress bar and Delete button don't stay stuck on screen after deleting a download"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_resume_uses_resume_download.patch" "UpdaterViewModel.resumeDownload(): call UpdaterController.resumeDownload(), not startDownload() -- startDownload() always builds a fresh DownloadClient with the update's (possibly null) download URL"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_persist_download_url.patch" "UpdatesDbHelper: persist download_url so an update restored from the DB after a process restart keeps a usable URL instead of null"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_null_url_not_fatal.patch" "UpdaterController: catch IllegalStateException alongside IOException when building a DownloadClient, so a missing download URL routes to PAUSED_ERROR/Retry instead of crashing the app"
apply_patch "packages/apps/Updater" "../../../$PATCH_DIR/packages_apps_updater_delete_button_keyed_on_status.patch" "UpdateCard: show the Delete action for any status with a file on disk, not just downloadProgress > 0f, so a restored PAUSED entry a user chose to keep (auto-delete-on-install off) gets a working Delete button instead of only a crashing Resume"
apply_patch "axion_sdk" "../$PATCH_DIR/axion_sdk_battery_design_capacity_int_extra.patch" "DeviceInfoProvider.getBatteryCapacity(): read EXTRA_DESIGN_CAPACITY with getIntExtra, not getLongExtra -- the extra is an Int (BatteryService puts it as one, matching BatteryManager's own doc), so getLongExtra always ClassCastExceptions internally and silently returns the -1 default. Also divide by 1000: BatteryManager.EXTRA_DESIGN_CAPACITY's own doc says microampere-hours, so the raw value was showing e.g. 4450000 mAh instead of 4450 mAh"
apply_patch "build/make" "../../$PATCH_DIR/build_make_ota_spl_downgrade_default.patch" "ota_from_target_files.py: default OPTIONS.spl_downgrade to True, so every built OTA gets SPL_DOWNGRADE=1 in payload_properties.txt and the installing device's update_engine skips CheckSPLDowngrade() regardless of which build produced the OTA"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_systemui_wifi_tile_state_follows_enabled.patch" "SystemUI Wi-Fi tile: state follows isWifiEnabled (ENABLING counts as on), disableWifi() clears the Scanning state, so tap and tile colour agree"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_systemui_wifi_tile_long_press_wifi_settings.patch" "SystemUI Wi-Fi tile: long-press opens Settings.ACTION_WIFI_SETTINGS instead of the Internet dialog"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_export_single_sample_window.patch" "AxDiagnostics: report export primes the CPU/I-O/process collectors, waits one window, and reuses that one sample across the health summary and every section instead of re-diffing ~100ms apart"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_system_server_pressure_without_pid.patch" "AxDiagnostics: SystemServerAnalyzer keeps the global CPU/memory pressure when system_server's pid can't be found instead of zeroing it"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_proc_visibility_readproc.patch" "AxDiagnostics: map android.permission.DUMP to the readproc group so the app can see system_server and app processes under the hidepid=2 /proc mount"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_drain_rate_without_tracking.patch" "AxDiagnostics: health summary drain rate falls back to an estimate from the present discharge current when DrainTracker has no samples"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_battery_current_unsupported.patch" "AxDiagnostics: normalizeBatteryCurrentMa() treats Integer.MIN_VALUE (unsupported property) as 0 instead of scaling it to -20000 mA"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_wakelocks_from_sysfs.patch" "AxDiagnostics: WakelockCollector reads /sys/class/wakeup/* when debugfs wakeup_sources is unreadable, before falling back to /proc/wakelocks"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_storage_skip_duplicate_volumes.patch" "AxDiagnostics: StorageCollector drops the cache and external volumes when they report the same size and free space as /data"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_system_server_export_window.patch" "AxDiagnostics: report export primes SystemServerAnalyzer with the other collectors so its per-thread CPU has a window, and prints PSS as unavailable when it can't be read"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_export_battery_current_sign.patch" "AxDiagnostics: report export prints battery current signed by charging state (+ charging, - otherwise) like the Battery screen, and omits the average when it is 0"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_wakelocks_active_now.patch" "AxDiagnostics: WakelockSnapshot.totalActiveCount is the number of wakelocks active now, not the sum of every source's activation count"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_memory_hog_persistent_threshold.patch" "AxDiagnostics: HealthAnalyzer flags persistent processes (oom_score_adj <= -800) as memory hogs only above 1.5 GB instead of 500 MB"
apply_patch "packages/apps/AxDiagnostics" "../../../$PATCH_DIR/packages_apps_axdiagnostics_socd_as_battery_depletion.patch" "AxDiagnostics: thermal zones that aren't temperatures (socd/vbat/ibat/bcl) move to ThermalSnapshot.nonTemperatureZones; the report shows socd as battery depletion in the Battery section"
apply_patch "packages/apps/AxionParts" "../../../$PATCH_DIR/packages_apps_axionparts_personalize_advanced_protection_oneplus_settings.patch" "Personalize: add Advanced protection (org.aox.privacy) and OnePlus settings (DeviceSettings) cards, launched by explicit component"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_locksettings_duress_credential.patch" "LockSettingsService: a credential matching the stored ax_duress_credential hash wipes user data instead of being verified; the hash is cleared whenever the lockscreen credential changes"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_camera2_high_speed_ranges_from_supported_target.patch" "camera2: createHighSpeedRequestList() takes the fps ranges from a target whose size is an advertised high speed size instead of whichever target getTargets() lists first, so a privileged camera app recording a larger surface in a constrained high speed session no longer fails at random"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_appwidget_no_state_load_while_locked.patch" "AppWidgetService: do not load or save widget state for a credential-locked user (provider list would lack non-direct-boot-aware apps and the next save would erase every widget)"
apply_patch "frameworks/native" "../../$PATCH_DIR/frameworks_native_ahardwarebuffer_qti_p010_venus.patch" "libnativewindow: treat QTI YCbCr_420_P010_VENUS (0x7FA30C0A) as a YUV format in AHardwareBuffer_lockPlanes so it returns the chroma plane (OplusCamera Movie LOG/HDR preview reads it)"
apply_patch "frameworks/base" "../../$PATCH_DIR/frameworks_base_camera2_remember_missing_vendor_tags.patch" "camera2: CameraMetadataNative remembers for 5 s that a key's tag lookup failed instead of repeating the native lookup, error log line and exception on every get()/set() of a vendor key the HAL does not define"
apply_patch "hardware/qcom-caf/sm8350/audio" "../../../../$PATCH_DIR/hardware_qcom_caf_sm8350_audio_spkr_prot_thermalclient_soname.patch" "audio HAL spkr_prot_init(): dlopen libthermalclient.so by soname instead of the fixed /vendor/lib path, so a 64-bit libspkrprot finds the lib64 copy"
apply_patch "hardware/qcom-caf/sm8350/audio" "../../../../$PATCH_DIR/hardware_qcom_caf_sm8350_audio_flagless_stream_hifi_usecase.patch" "audio HAL adev_open_output_stream(): a flagless PCM output (the spatializer stream, whose flag libaudiohal strips for HALs below 7.1) takes the hifi usecase instead of the primary one the primary output already holds"

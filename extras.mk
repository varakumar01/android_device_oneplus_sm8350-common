# DeviceAsWebcam
TARGET_BUILD_DEVICE_AS_WEBCAM := true

# Torch
$(call soong_config_set,libcameraservice,ext_lib,//$(LOCAL_PATH):libcameraservice_extension.oneplus_sm8350)

# OnePlus OOS Camera
$(call inherit-product-if-exists, vendor/oplus/camera/opluscamera.mk)

# Dolby
$(call inherit-product, vendor/sony/dolby/sonydolby.mk)

# GhostWire (independent pentest app, pinned at packages/apps/GhostWire)
$(call inherit-product-if-exists, packages/apps/GhostWire/ghostwire.mk)

# Datura firewall (pinned at packages/apps/Datura-Firewall)
$(call inherit-product-if-exists, packages/apps/Datura-Firewall/datura.mk)

# Advanced protection settings (pinned at packages/apps/PrivacySettings)
$(call inherit-product-if-exists, packages/apps/PrivacySettings/privacysettings.mk)

# Prebuilt apps fetched by scripts/track_changes.sh into prebuilt-apps/
# (Brave stable, KernelSU-Next manager), shipped in /product/preinstall and
# installed as user apps on first boot. Each is added only when its APK is
# present; the modules themselves live in prebuilt-apps/Android.mk.
PRODUCT_PACKAGES += \
    axion_preinstall.rc \
    axion_preinstall.sh
ifneq ($(wildcard $(LOCAL_PATH)/prebuilt-apps/Brave.apk),)
PRODUCT_PACKAGES += BravePreinstall
endif
ifneq ($(wildcard $(LOCAL_PATH)/prebuilt-apps/KSUNManager.apk),)
PRODUCT_PACKAGES += KSUNManagerPreinstall
endif

# powerhal properties
PRODUCT_SYSTEM_PROPERTIES += \
    pm.sleep_mode=1 \
    ro.iorapd.enable=false \
    iorapd.perfetto.enable=false \
    persist.sys.perf.scroll_opt=true \
    persist.sys.perf.scroll_opt.heavy_app=1

PRODUCT_VENDOR_PROPERTIES += \
    vendor.post_boot.parsed=1

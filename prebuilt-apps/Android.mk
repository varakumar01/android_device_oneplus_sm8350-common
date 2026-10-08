LOCAL_PATH := $(call my-dir)

# Prebuilt APKs fetched by scripts/track_changes.sh into this directory
# (gitignored, never committed). They are shipped as plain files in
# /product/preinstall and installed as ordinary user apps on first boot by
# axion_preinstall.sh, so they land in /data/app with their own upstream
# signature, can update themselves and can be uninstalled.
#
# They are not built as system apps: the app prebuilt rule re-packs an APK
# (which drops a v2/v3 signature), and KernelSU only looks for its manager
# under /data/app.
#
# Each APK module is defined only when the file is present, so an absent APK
# drops out of the build; extras.mk adds the names under the same guard.

# Brave (stable "Release" channel, the orange icon; Universal arm64).
ifneq ($(wildcard $(LOCAL_PATH)/Brave.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := BravePreinstall
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES := Brave.apk
LOCAL_MODULE_STEM := Brave.apk
LOCAL_MODULE_PATH := $(TARGET_OUT_PRODUCT)/preinstall
LOCAL_PRODUCT_MODULE := true
include $(BUILD_PREBUILT)
endif

# KernelSU-Next manager (spoofed). Its version tracks the kernel's
# drivers/kernelsu/Kbuild KSU_GIT_TAG.
ifneq ($(wildcard $(LOCAL_PATH)/KSUNManager.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := KSUNManagerPreinstall
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES := KSUNManager.apk
LOCAL_MODULE_STEM := KSUNManager.apk
LOCAL_MODULE_PATH := $(TARGET_OUT_PRODUCT)/preinstall
LOCAL_PRODUCT_MODULE := true
include $(BUILD_PREBUILT)
endif

include $(CLEAR_VARS)
LOCAL_MODULE := axion_preinstall.sh
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES := axion_preinstall.sh
LOCAL_MODULE_PATH := $(TARGET_OUT_PRODUCT)/preinstall
LOCAL_PRODUCT_MODULE := true
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := axion_preinstall.rc
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES := axion_preinstall.rc
LOCAL_MODULE_PATH := $(TARGET_OUT_PRODUCT)/etc/init
LOCAL_PRODUCT_MODULE := true
include $(BUILD_PREBUILT)

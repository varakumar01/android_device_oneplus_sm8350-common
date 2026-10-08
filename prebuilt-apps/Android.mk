LOCAL_PATH := $(call my-dir)

# Prebuilt APKs fetched by scripts/track_changes.sh into this directory
# (gitignored, never committed). Each module is defined only when its APK is
# actually present, so a removed/absent APK drops out of the build cleanly
# instead of breaking Make analysis. extras.mk adds the matching name to
# PRODUCT_PACKAGES under the same wildcard guard.
#
# LOCAL_CERTIFICATE := PRESIGNED keeps each app's own upstream signature
# (so it can still update itself), and LOCAL_DEX_PREOPT := false skips the
# dexpreopt import path, which is also what avoids the user/userdebug
# <uses-library> verify failure a resigned/dexpreopted prebuilt can hit.
#
# LOCAL_REPLACE_PREBUILT_APK_INSTALLED installs the file byte for byte.
# Without it the prebuilt rule stores the APK's native libraries
# uncompressed and re-aligns the zip, which drops the APK Signing Block:
# both apps are v2/v3-signed, so PackageManager then finds no usable
# signature and skips them at boot.
#
# Both APKs carry their native libraries compressed, and a system app's
# libraries are never extracted on the device, so track_changes.sh unpacks
# lib/arm64-v8a/ into <name>-libs/ and LOCAL_PREBUILT_JNI_LIBS installs them
# beside the APK.

# Brave (stable "Release" channel, the orange icon; Universal arm64).
ifneq ($(wildcard $(LOCAL_PATH)/Brave.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := Brave
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_SRC_FILES := Brave.apk
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/Brave.apk
LOCAL_PREBUILT_JNI_LIBS := $(patsubst $(LOCAL_PATH)/%,%,$(wildcard $(LOCAL_PATH)/Brave-libs/*.so))
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRODUCT_MODULE := true
LOCAL_DEX_PREOPT := false
include $(BUILD_PREBUILT)
endif

# KernelSU-Next manager (spoofed). Its version tracks the kernel's
# drivers/kernelsu/Kbuild KSU_GIT_TAG; installed to /system/app so it stays
# user-updatable.
ifneq ($(wildcard $(LOCAL_PATH)/KSUNManager.apk),)
include $(CLEAR_VARS)
LOCAL_MODULE := KSUNManager
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_SRC_FILES := KSUNManager.apk
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/KSUNManager.apk
LOCAL_PREBUILT_JNI_LIBS := $(patsubst $(LOCAL_PATH)/%,%,$(wildcard $(LOCAL_PATH)/KSUNManager-libs/*.so))
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_DEX_PREOPT := false
include $(BUILD_PREBUILT)
endif

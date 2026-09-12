TARGET := iphone:clang:latest:15.0
ARCHS = arm64

INSTALL_TARGET_PROCESSES = YouTube
FINALPACKAGE = 1

ifeq ($(ROOTLESS),1)
THEOS_PACKAGE_SCHEME = rootless
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReturnYTCast

ReturnYTCast_FILES = Tweak.xm
ReturnYTCast_FRAMEWORKS = UIKit Foundation
ReturnYTCast_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

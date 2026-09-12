TARGET := iphone:clang:latest:15.0
ARCHS = arm64

INSTALL_TARGET_PROCESSES = YouTube

THEOS_PACKAGE_SCHEME = rootless
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReturnYTCast

ReturnYTCast_FILES = Tweak.xm
ReturnYTCast_FRAMEWORKS = UIKit Foundation
ReturnYTCast_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

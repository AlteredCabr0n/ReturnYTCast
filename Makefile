ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CastButtonFix

CastButtonFix_FILES = Tweak.xm
CastButtonFix_CFLAGS = -fobjc-arc
CastButtonFix_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

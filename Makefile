ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReturnYTCast

ReturnYTCast_FILES = Tweak.xm
ReturnYTCast_CFLAGS = -fobjc-arc
ReturnYTCast_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

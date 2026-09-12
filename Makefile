TARGET := iphone:clang:latest:15.0
ARCHS := arm64

FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME := ReturnYTCast

ReturnYTCast_FILES := Tweak.xm

ReturnYTCast_CFLAGS := \
	-fobjc-arc \
	-DTHEOS_LEAN_AND_MEAN=1

ReturnYTCast_FRAMEWORKS := UIKit Foundation

ReturnYTCast_LDFLAGS += \
	-ObjC \
	-Wl,-not_for_dyld_shared_cache \
	-undefined dynamic_lookup \
	-Wl,-undefined,dynamic_lookup

ReturnYTCast_INSTALL_PATH = /usr/lib

LEAN_AND_MEAN = 1

include $(THEOS_MAKE_PATH)/library.mk

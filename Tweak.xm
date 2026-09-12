#import <UIKit/UIKit.h>

%config(generator=internal)

%hook YTIIosMainBrowseEndpointTopBarConfig

- (BOOL)removeCastButtonFromTopbar {
    return NO;
}

- (BOOL)hasRemoveCastButtonFromTopbar {
    return YES;
}

%end

%hook MDXPlaybackRouteButtonController

- (BOOL)isPersistentCastIconEnabled {
    return YES;
}

%end

%hook YTHeaderViewController

- (BOOL)allowPlaybackRouteButton {
    return YES;
}

- (BOOL)controlsCastButton {
    return YES;
}

- (void)setPlaybackRouteButtonVisible:(BOOL)visible {
    %orig(YES);
}

%end

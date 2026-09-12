#import <UIKit/UIKit.h>

%hook YTIIosMainBrowseEndpointTopBarConfig

- (BOOL)removeCastButtonFromTopbar {
    return NO;
}

- (BOOL)hasRemoveCastButtonFromTopbar {
    return YES;
}

%end

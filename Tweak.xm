#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

%config(generator=internal)

@interface YTHeaderViewController : UIViewController
@end

static char kReturnYTCastItemKey;

static id RYTCastMsgSendId(id object, SEL selector) {
    if (!object || ![object respondsToSelector:selector])
        return nil;

    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

static void InstallReturnYTCastButton(YTHeaderViewController *controller) {
    if (!controller)
        return;

    UINavigationItem *navigationItem = controller.navigationItem;

    if (!navigationItem)
        return;

    UIBarButtonItem *existing =
        objc_getAssociatedObject(controller, &kReturnYTCastItemKey);

    if (existing &&
        [navigationItem.rightBarButtonItems containsObject:existing]) {
        return;
    }

    /*
     * YouTube 21.24.3 exposes playbackRouteButton directly
     * on its header/controller infrastructure.
     */
    UIButton *castButton =
        RYTCastMsgSendId(controller,
                         NSSelectorFromString(@"playbackRouteButton"));

    /*
     * If the header hasn't created it yet, ask YouTube to make
     * the playback route button visible first.
     */
    if (!castButton) {
        SEL visibleSelector =
            NSSelectorFromString(@"setPlaybackRouteButtonVisible:");

        if ([controller respondsToSelector:visibleSelector]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(
                controller,
                visibleSelector,
                YES
            );
        }

        castButton =
            RYTCastMsgSendId(controller,
                             NSSelectorFromString(@"playbackRouteButton"));
    }

    /*
     * Fallback:
     * retrieve YouTube's MDX playback route controller and
     * ask that for its own route button.
     */
    if (!castButton) {
        id routeController =
            RYTCastMsgSendId(
                controller,
                NSSelectorFromString(@"playbackRouteButtonController")
            );

        if (routeController) {
            castButton =
                RYTCastMsgSendId(
                    routeController,
                    NSSelectorFromString(@"routeButton")
                );

            if (!castButton) {
                castButton =
                    RYTCastMsgSendId(
                        routeController,
                        NSSelectorFromString(@"playbackRouteButton")
                    );
            }
        }
    }

    if (![castButton isKindOfClass:UIButton.class])
        return;

    castButton.hidden = NO;
    castButton.alpha = 1.0;
    castButton.userInteractionEnabled = YES;

    UIBarButtonItem *castItem =
        [[UIBarButtonItem alloc] initWithCustomView:castButton];

    /*
     * UIBarButtonItem arrays are ordered from the outside/right
     * towards the inside/left in YouTube's trailing navigation area.
     *
     * Existing visual order:
     *
     *     Chat   Bell   Search
     *
     * rightBarButtonItems is therefore expected roughly as:
     *
     *     Search, Bell, Chat
     *
     * Appending Cast places it visually LEFT of Chat:
     *
     *     Cast   Chat   Bell   Search
     */
    NSMutableArray *items =
        [navigationItem.rightBarButtonItems mutableCopy];

    if (!items)
        items = [NSMutableArray array];

    [items addObject:castItem];

    navigationItem.rightBarButtonItems = items;

    objc_setAssociatedObject(
        controller,
        &kReturnYTCastItemKey,
        castItem,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
    );
}

#pragma mark - Server-side Cast suppression

%hook YTIIosMainBrowseEndpointTopBarConfig

- (BOOL)removeCastButtonFromTopbar {
    return NO;
}

- (BOOL)hasRemoveCastButtonFromTopbar {
    return YES;
}

%end


#pragma mark - Native Cast controller

%hook MDXPlaybackRouteButtonController

- (BOOL)isPersistentCastIconEnabled {
    return YES;
}

%end


#pragma mark - YouTube header

%hook YTHeaderViewController

- (void)viewDidLoad {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        InstallReturnYTCastButton(self);
    });
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        InstallReturnYTCastButton(self);
    });
}

- (void)viewDidLayoutSubviews {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        InstallReturnYTCastButton(self);
    });
}

%end

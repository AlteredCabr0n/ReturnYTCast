#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

%config(generator=internal)

@interface YTHeaderViewController : UIViewController
@end

static char kReturnYTCastButtonKey;
static char kReturnYTCastControllerKey;

static id FindMDXController(UIViewController *vc) {
    if (!vc) return nil;

    Class cls = objc_getClass("MDXPlaybackRouteButtonController");
    if (!cls) return nil;

    if ([vc isKindOfClass:cls])
        return vc;

    for (UIViewController *child in vc.childViewControllers) {
        id found = FindMDXController(child);
        if (found) return found;
    }

    if (vc.presentedViewController) {
        id found = FindMDXController(vc.presentedViewController);
        if (found) return found;
    }

    return nil;
}

static UIViewController *TopViewController(void) {
    UIWindow *window = nil;

    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive)
            continue;

        if (![scene isKindOfClass:UIWindowScene.class])
            continue;

        UIWindowScene *windowScene = (UIWindowScene *)scene;

        for (UIWindow *candidate in windowScene.windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }

        if (!window)
            window = windowScene.windows.firstObject;

        if (window)
            break;
    }

    if (!window)
        return nil;

    UIViewController *vc = window.rootViewController;

    while (vc.presentedViewController)
        vc = vc.presentedViewController;

    if ([vc isKindOfClass:UINavigationController.class])
        vc = ((UINavigationController *)vc).visibleViewController;

    if ([vc isKindOfClass:UITabBarController.class])
        vc = ((UITabBarController *)vc).selectedViewController;

    return vc;
}

static void ReturnYTCastPressed(UIButton *sender) {
    UIViewController *root = TopViewController();

    id controller = FindMDXController(root);

    if (!controller) {
        Class cls = objc_getClass("MDXPlaybackRouteButtonController");
        if (!cls)
            return;

        controller = [[cls alloc] init];

        objc_setAssociatedObject(
            sender,
            &kReturnYTCastControllerKey,
            controller,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC
        );
    }

    SEL selector = NSSelectorFromString(@"didPressButton:");

    if ([controller respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(
            controller,
            selector,
            sender
        );
    }
}

static BOOL IsLikelyTopBarButton(UIView *view) {
    if (![view isKindOfClass:UIButton.class])
        return NO;

    CGRect frame = view.frame;

    return frame.size.width >= 24.0 &&
           frame.size.width <= 80.0 &&
           frame.size.height >= 24.0 &&
           frame.size.height <= 80.0;
}

static NSArray<UIButton *> *FindHeaderButtons(UIView *view) {
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];

    for (UIView *subview in view.subviews) {
        if (IsLikelyTopBarButton(subview))
            [buttons addObject:(UIButton *)subview];

        [buttons addObjectsFromArray:FindHeaderButtons(subview)];
    }

    return buttons;
}

static void AddReturnYTCastButton(UIView *headerView) {
    if (!headerView)
        return;

    UIButton *existing = objc_getAssociatedObject(
        headerView,
        &kReturnYTCastButtonKey
    );

    if (existing && existing.superview)
        return;

    NSArray<UIButton *> *allButtons = FindHeaderButtons(headerView);
    NSMutableArray<UIButton *> *rightSideButtons = [NSMutableArray array];

    CGFloat midpoint = CGRectGetMidX(headerView.bounds);

    for (UIButton *button in allButtons) {
        CGRect frame = [button.superview convertRect:button.frame
                                              toView:headerView];

        if (CGRectGetMidX(frame) > midpoint)
            [rightSideButtons addObject:button];
    }

    if (rightSideButtons.count == 0)
        return;

    [rightSideButtons sortUsingComparator:^NSComparisonResult(
        UIButton *a,
        UIButton *b
    ) {
        CGRect af = [a.superview convertRect:a.frame toView:headerView];
        CGRect bf = [b.superview convertRect:b.frame toView:headerView];

        if (CGRectGetMinX(af) < CGRectGetMinX(bf))
            return NSOrderedAscending;

        if (CGRectGetMinX(af) > CGRectGetMinX(bf))
            return NSOrderedDescending;

        return NSOrderedSame;
    }];

    UIButton *chatButton = rightSideButtons.firstObject;
    UIView *container = chatButton.superview ?: headerView;

    CGRect chatFrame = chatButton.frame;

    UIButton *castButton = [UIButton buttonWithType:UIButtonTypeSystem];

    UIImage *image = [UIImage systemImageNamed:@"airplayvideo"];
    [castButton setImage:image forState:UIControlStateNormal];

    castButton.tintColor =
        chatButton.tintColor ?: UIColor.whiteColor;

    castButton.frame = CGRectOffset(
        chatFrame,
        -(CGRectGetWidth(chatFrame) + 8.0),
        0
    );

    castButton.accessibilityLabel = @"Cast";
    castButton.accessibilityIdentifier = @"com.altc.returnytcast";

    [castButton addTarget:nil
                   action:@selector(returnYTCastTapped:)
         forControlEvents:UIControlEventTouchUpInside];

    [container addSubview:castButton];

    objc_setAssociatedObject(
        headerView,
        &kReturnYTCastButtonKey,
        castButton,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC
    );
}

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

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        AddReturnYTCastButton(self.view);
    });
}

- (void)viewDidLayoutSubviews {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        AddReturnYTCastButton(self.view);
    });
}

%end

%hook UIResponder

%new
- (void)returnYTCastTapped:(UIButton *)sender {
    ReturnYTCastPressed(sender);
}

%end

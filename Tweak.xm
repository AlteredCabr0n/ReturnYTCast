#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%config(generator=internal)

static char kReturnYTCastButtonKey;
static char kReturnYTCastControllerKey;

static id FindMDXController(UIViewController *vc) {
    Class cls = objc_getClass("MDXPlaybackRouteButtonController");
    if (!cls) return nil;

    // Try an existing MDX controller already owned somewhere in the VC tree.
    for (UIViewController *child in vc.childViewControllers) {
        if ([child isKindOfClass:cls]) return child;

        id found = FindMDXController(child);
        if (found) return found;
    }

    return nil;
}

static void ReturnYTCastPressed(UIButton *sender) {
    UIViewController *vc = sender.window.rootViewController;

    while (vc.presentedViewController)
        vc = vc.presentedViewController;

    id controller = FindMDXController(vc);

    if (!controller) {
        Class cls = objc_getClass("MDXPlaybackRouteButtonController");
        if (!cls) return;

        controller = [[cls alloc] init];
        objc_setAssociatedObject(sender,
                                 &kReturnYTCastControllerKey,
                                 controller,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    SEL selector = NSSelectorFromString(@"didPressButton:");

    if ([controller respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(controller,
                                              selector,
                                              sender);
    }
}

static BOOL IsLikelyHeaderActionButton(UIView *view) {
    if (![view isKindOfClass:UIButton.class])
        return NO;

    CGRect f = view.frame;

    // Right-hand Home header icons.
    return f.size.width >= 25.0 &&
           f.size.width <= 70.0 &&
           f.size.height >= 25.0 &&
           f.size.height <= 70.0;
}

static void AddReturnYTCastButton(UIView *headerView) {
    if (!headerView || objc_getAssociatedObject(headerView, &kReturnYTCastButtonKey))
        return;

    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];

    for (UIView *subview in headerView.subviews) {
        if (IsLikelyHeaderActionButton(subview))
            [buttons addObject:(UIButton *)subview];
    }

    if (buttons.count == 0)
        return;

    // Sort right-side buttons from left → right.
    [buttons sortUsingComparator:^NSComparisonResult(UIButton *a, UIButton *b) {
        if (CGRectGetMinX(a.frame) < CGRectGetMinX(b.frame))
            return NSOrderedAscending;
        if (CGRectGetMinX(a.frame) > CGRectGetMinX(b.frame))
            return NSOrderedDescending;
        return NSOrderedSame;
    }];

    // Existing left-most right-side icon should be the Chat button.
    UIButton *chatButton = buttons.firstObject;

    UIButton *castButton = [UIButton buttonWithType:UIButtonTypeSystem];

    UIImage *castImage = nil;

    if (@available(iOS 13.0, *)) {
        castImage = [UIImage systemImageNamed:@"airplayvideo"];
    }

    [castButton setImage:castImage forState:UIControlStateNormal];
    castButton.tintColor = chatButton.tintColor ?: UIColor.whiteColor;

    castButton.frame = chatButton.frame;

    CGFloat spacing = 12.0;
    castButton.frame = CGRectOffset(
        castButton.frame,
        -(CGRectGetWidth(chatButton.frame) + spacing),
        0
    );

    [castButton addTarget:nil
                   action:@selector(returnYTCastTapped:)
         forControlEvents:UIControlEventTouchUpInside];

    [headerView addSubview:castButton];

    objc_setAssociatedObject(headerView,
                             &kReturnYTCastButtonKey,
                             castButton,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%hook UIResponder

%new
- (void)returnYTCastTapped:(UIButton *)sender {
    ReturnYTCastPressed(sender);
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

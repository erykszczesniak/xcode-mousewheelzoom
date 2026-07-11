#import "SZZoomHUD.h"

#import "SZStrings.h"

static const CGFloat SZHUDWidth = 160.0;
static const CGFloat SZHUDHeight = 120.0;
static const CGFloat SZHUDCornerRadius = 18.0;
static const CGFloat SZHUDBottomInset = 140.0;
static const NSTimeInterval SZHUDFadeInDuration = 0.12;
static const NSTimeInterval SZHUDFadeOutDuration = 0.35;
static const NSTimeInterval SZHUDVisibleDuration = 0.7;

@interface SZZoomHUD ()

@property (nonatomic, strong, nullable) NSPanel *panel;
@property (nonatomic, strong) NSTextField *stepsLabel;
@property (nonatomic, strong) NSImageView *glyphView;
@property (nonatomic, strong, nullable) NSTimer *dismissTimer;
/// Bumped on every show. A fade-out only orders the panel out if no newer
/// show has happened since it started — alphaValue cannot be used for this,
/// because an animator-driven fade-in still reads 0.0 until its first tick.
@property (nonatomic) NSUInteger showGeneration;

@end

@implementation SZZoomHUD

- (void)dealloc {
    [_dismissTimer invalidate];
}

#pragma mark - SZZoomFeedbackPresenting

- (void)showZoomSteps:(NSInteger)steps {
    NSPanel *panel = [self panelForCurrentScreen];
    [self updateContentWithSteps:steps];

    self.showGeneration += 1;
    [self.dismissTimer invalidate];

    if (!panel.isVisible) {
        panel.alphaValue = 0.0;
        [panel orderFrontRegardless];
    }

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = SZHUDFadeInDuration;
        panel.animator.alphaValue = 1.0;
    }];

    // Common modes: a default-mode timer would stall while the agent's own
    // run loop is tracking (status menu open, slider drag), freezing the HUD.
    self.dismissTimer = [NSTimer timerWithTimeInterval:SZHUDVisibleDuration
                                                target:self
                                              selector:@selector(dismiss:)
                                              userInfo:nil
                                               repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.dismissTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - Content

- (void)updateContentWithSteps:(NSInteger)steps {
    NSString *symbolName = steps < 0 ? @"minus.magnifyingglass" : @"plus.magnifyingglass";
    self.glyphView.image = [NSImage imageWithSystemSymbolName:symbolName
                                     accessibilityDescription:nil];
    self.stepsLabel.stringValue = [NSString stringWithFormat:@"%+ld", (long)steps];
}

#pragma mark - Panel

- (NSPanel *)panelForCurrentScreen {
    if (self.panel == nil) {
        [self buildPanel];
    }
    [self centerPanelOnActiveScreen];
    return self.panel;
}

- (void)buildPanel {
    NSPanel *panel = [[NSPanel alloc]
        initWithContentRect:NSMakeRect(0, 0, SZHUDWidth, SZHUDHeight)
                  styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                    backing:NSBackingStoreBuffered
                      defer:YES];
    panel.opaque = NO;
    panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = YES;
    panel.ignoresMouseEvents = YES;
    panel.becomesKeyOnlyIfNeeded = YES;
    // Ride along to whichever Space the user is zooming in, including over
    // full-screen apps.
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                               NSWindowCollectionBehaviorFullScreenAuxiliary |
                               NSWindowCollectionBehaviorStationary;
    // Set last: -[NSPanel setFloatingPanel:] would silently rewrite the level
    // to NSFloatingWindowLevel, so it is deliberately not used here.
    panel.level = NSStatusWindowLevel;

    NSVisualEffectView *background = [[NSVisualEffectView alloc]
        initWithFrame:NSMakeRect(0, 0, SZHUDWidth, SZHUDHeight)];
    background.material = NSVisualEffectMaterialHUDWindow;
    background.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    background.state = NSVisualEffectStateActive;
    background.wantsLayer = YES;
    background.layer.cornerRadius = SZHUDCornerRadius;
    background.layer.masksToBounds = YES;

    self.glyphView = [[NSImageView alloc] init];
    self.glyphView.symbolConfiguration =
        [NSImageSymbolConfiguration configurationWithPointSize:40
                                                        weight:NSFontWeightRegular];
    self.glyphView.contentTintColor = NSColor.labelColor;

    self.stepsLabel = [NSTextField labelWithString:@""];
    self.stepsLabel.font = [NSFont monospacedDigitSystemFontOfSize:20
                                                            weight:NSFontWeightMedium];
    self.stepsLabel.alignment = NSTextAlignmentCenter;
    self.stepsLabel.textColor = NSColor.secondaryLabelColor;

    NSStackView *stack = [NSStackView stackViewWithViews:@[ self.glyphView, self.stepsLabel ]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeCenterX;
    stack.spacing = 6.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [background addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:background.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:background.centerYAnchor],
    ]];

    panel.contentView = background;
    panel.accessibilityLabel = SZLocalizedHUDAccessibilityLabel();
    self.panel = panel;
}

- (void)centerPanelOnActiveScreen {
    NSScreen *screen = [self screenUnderCursor] ?: NSScreen.mainScreen;
    if (screen == nil) {
        return;
    }
    NSRect visible = screen.visibleFrame;
    NSPoint origin = NSMakePoint(NSMidX(visible) - SZHUDWidth / 2.0,
                                 NSMinY(visible) + SZHUDBottomInset);
    [self.panel setFrameOrigin:origin];
}

- (nullable NSScreen *)screenUnderCursor {
    NSPoint mouse = NSEvent.mouseLocation;
    for (NSScreen *screen in NSScreen.screens) {
        // NSMouseInRect, not NSPointInRect: a cursor pinned to the top edge
        // reports y == NSMaxY, which NSPointInRect excludes.
        if (NSMouseInRect(mouse, screen.frame, NO)) {
            return screen;
        }
    }
    return nil;
}

#pragma mark - Dismissal

- (void)dismiss:(NSTimer *)timer {
    self.dismissTimer = nil;

    NSPanel *panel = self.panel;
    NSUInteger generation = self.showGeneration;
    __weak typeof(self) weakSelf = self;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = SZHUDFadeOutDuration;
        panel.animator.alphaValue = 0.0;
    } completionHandler:^{
        // A new gesture may have re-shown the HUD while this was fading.
        if (weakSelf.showGeneration == generation) {
            [panel orderOut:nil];
        }
    }];
}

@end

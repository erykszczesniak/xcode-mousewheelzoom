#import "SZAppDelegate.h"

#import <Carbon/Carbon.h>

#import "SZAccessibility.h"
#import "SZHotKey.h"
#import "SZMenuController.h"
#import "SZPermissionGate.h"
#import "SZPreferences.h"
#import "SZZoomController.h"

@interface SZAppDelegate () <SZMenuStateProviding>

@property (nonatomic, strong) SZPreferences *preferences;
@property (nonatomic, strong) SZMenuController *menuController;
@property (nonatomic, strong) SZAccessibility *accessibility;
@property (nonatomic, strong) SZPermissionGate *permissionGate;
@property (nonatomic, strong) SZZoomController *zoomController;
@property (nonatomic, strong) SZHotKey *toggleHotKey;
@property (nonatomic, strong) NSTimer *trustWatchTimer;

@end

/// How often to re-check that Accessibility trust is still granted.
static const NSTimeInterval SZTrustWatchInterval = 5.0;

@implementation SZAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.preferences = [[SZPreferences alloc] init];
    self.accessibility = [[SZAccessibility alloc] init];
    self.permissionGate = [[SZPermissionGate alloc] initWithTrustChecker:self.accessibility];

    self.menuController = [[SZMenuController alloc] initWithPreferences:self.preferences];
    self.menuController.stateProvider = self;

    __weak typeof(self) weakSelf = self;
    self.menuController.configurationChangedHandler = ^{
        [weakSelf applyPreferences];
    };
    self.menuController.openSettingsHandler = ^{
        [weakSelf.accessibility openAccessibilitySettings];
    };
    [self.menuController install];

    // ⌃⌥⌘Z pauses/resumes globally — the escape hatch if a gesture ever
    // misbehaves inside a full-screen app.
    self.toggleHotKey = [[SZHotKey alloc] initWithKeyCode:kVK_ANSI_Z
                                                modifiers:(cmdKey | optionKey | controlKey)
                                                  handler:^{
                                                      [weakSelf toggleEnabledFromHotKey];
                                                  }];
    [self.toggleHotKey registerHotKey];

    [self.permissionGate runWithGrantedHandler:^{
        [weakSelf armEventPipeline];
    }];
}

- (void)toggleEnabledFromHotKey {
    self.preferences.enabled = !self.preferences.isEnabled;
    [self applyPreferences];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)application {
    return YES;
}

#pragma mark - Pipeline

- (void)armEventPipeline {
    if (self.zoomController == nil) {
        self.zoomController =
            [[SZZoomController alloc] initWithMonitor:[[SZEventTap alloc] init]
                                       focusInspector:self.accessibility
                                          interpreter:[[SZGestureInterpreter alloc] init]
                                              matcher:[[SZTargetMatcher alloc] init]
                                               mapper:[[SZActionMapper alloc] init]
                                          synthesizer:[[SZKeystrokeSynthesizer alloc] init]];
    }
    [self applyPreferences];
    [self.zoomController arm];
    [self startTrustWatch];
}

#pragma mark - Permission-revoked recovery

- (void)startTrustWatch {
    if (self.trustWatchTimer != nil) {
        return;
    }
    self.trustWatchTimer = [NSTimer scheduledTimerWithTimeInterval:SZTrustWatchInterval
                                                            target:self
                                                          selector:@selector(reviewTrustState:)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)reviewTrustState:(NSTimer *)timer {
    BOOL trusted = self.accessibility.isProcessTrusted;
    if (!trusted && self.zoomController.isArmed) {
        // Revoked mid-flight: stand down instead of posting keystrokes that
        // the system would drop anyway. The menu shows the state.
        [self.zoomController disarm];
    } else if (trusted && self.zoomController != nil && !self.zoomController.isArmed) {
        [self armEventPipeline];
    }
}

- (void)applyPreferences {
    if (self.zoomController == nil) {
        return;
    }
    self.zoomController.enabled = self.preferences.isEnabled;
    self.zoomController.matcher =
        [[SZTargetMatcher alloc] initWithRules:self.preferences.activeTargetRules];
    self.zoomController.interpreter.preciseDeltaThreshold =
        self.preferences.preciseDeltaThreshold;
}

#pragma mark - SZMenuStateProviding

- (BOOL)isPermissionGranted {
    return self.permissionGate.isTrusted;
}

- (NSString *)activeTargetName {
    if (self.zoomController == nil || !self.zoomController.isArmed ||
        !self.preferences.isEnabled) {
        return nil;
    }
    NSString *bundleIdentifier = [self.accessibility frontmostApplicationBundleIdentifier];
    if (![self.zoomController.matcher hasRuleForBundleIdentifier:bundleIdentifier]) {
        return nil;
    }
    return [NSWorkspace sharedWorkspace].frontmostApplication.localizedName;
}

@end

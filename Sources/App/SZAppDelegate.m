#import "SZAppDelegate.h"

#import "SZAccessibility.h"
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

@end

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

    [self.permissionGate runWithGrantedHandler:^{
        [weakSelf armEventPipeline];
    }];
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

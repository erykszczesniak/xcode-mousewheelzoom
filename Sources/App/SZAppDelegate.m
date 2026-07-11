#import "SZAppDelegate.h"

#import <Carbon/Carbon.h>

#import "SZAccessibility.h"
#import "SZHotKey.h"
#import "SZLoginItem.h"
#import "SZMainMenu.h"
#import "SZMenuController.h"
#import "SZPermissionGate.h"
#import "SZPreferences.h"
#import "SZStrings.h"
#import "SZZoomController.h"

// Generated interface for the app's Swift side (Settings window).
#import "ScrollZoom-Swift.h"

@interface SZAppDelegate () <SZMenuStateProviding>

@property (nonatomic, strong) SZPreferences *preferences;
@property (nonatomic, strong) SZMenuController *menuController;
@property (nonatomic, strong) SZAccessibility *accessibility;
@property (nonatomic, strong) SZPermissionGate *permissionGate;
@property (nonatomic, strong) SZZoomController *zoomController;
@property (nonatomic, strong) SZHotKey *toggleHotKey;
@property (nonatomic, strong) id<SZLoginItemManaging> loginItem;
@property (nonatomic, strong) SZSettingsWindowPresenter *settingsPresenter;
@property (nonatomic, strong) NSTimer *trustWatchTimer;

@end

/// How often to re-check that Accessibility trust is still granted.
static const NSTimeInterval SZTrustWatchInterval = 5.0;

@implementation SZAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.preferences = [[SZPreferences alloc] init];
    self.loginItem = [[SZLoginItem alloc] init];
    self.accessibility = [[SZAccessibility alloc] init];
    self.permissionGate = [[SZPermissionGate alloc] initWithTrustChecker:self.accessibility];

    self.menuController = [[SZMenuController alloc] initWithPreferences:self.preferences];
    self.menuController.stateProvider = self;

    // Every preference mutation — from the menu, the hotkey, or any future
    // UI — funnels through one notification into the live pipeline.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesDidChange:)
                                                 name:SZPreferencesDidChangeNotification
                                               object:self.preferences];

    // A target app that quits comes back at its own default font size, so the
    // step count ScrollZoom accumulated for it is meaningless afterwards.
    [[NSWorkspace sharedWorkspace].notificationCenter
        addObserver:self
           selector:@selector(applicationDidTerminate:)
               name:NSWorkspaceDidTerminateApplicationNotification
             object:nil];

    __weak typeof(self) weakSelf = self;
    self.menuController.openSettingsHandler = ^{
        [weakSelf.accessibility openAccessibilitySettings];
    };
    self.menuController.toggleLoginItemHandler = ^{
        [weakSelf toggleLoginItem];
    };
    self.settingsPresenter = [[SZSettingsWindowPresenter alloc]
              initWithPreferences:self.preferences
                        loginItem:self.loginItem
                     trustChecker:self.accessibility
        openAccessibilitySettings:^{
            [weakSelf.accessibility openAccessibilitySettings];
        }];
    self.menuController.openSettingsWindowHandler = ^{
        [weakSelf.settingsPresenter show];
    };
    [self.menuController install];

    // Agent apps have no main menu, so ⌘, / ⌘W / ⌘Q would go nowhere.
    [SZMainMenu installWithSettingsAction:@selector(showSettingsWindow:) target:self];

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

- (void)showSettingsWindow:(id)sender {
    [self.settingsPresenter show];
}

- (void)toggleEnabledFromHotKey {
    self.preferences.enabled = !self.preferences.isEnabled;
}

- (void)preferencesDidChange:(NSNotification *)notification {
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
                                          synthesizer:[[SZKeystrokeSynthesizer alloc] init]
                                         levelTracker:[[SZZoomLevelTracker alloc] init]
                                             feedback:[[SZZoomHUD alloc] init]];
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

    SZTargetMatcher *matcher =
        [[SZTargetMatcher alloc] initWithRules:self.preferences.activeTargetRules];
    // An app that is no longer a target may be zoomed by hand from now on, so
    // its accumulated step count would be fiction if it is ever re-added.
    for (SZTargetRule *rule in self.zoomController.matcher.rules) {
        if (![matcher hasRuleForBundleIdentifier:rule.bundleIdentifier]) {
            [self.zoomController.levelTracker resetBundleIdentifier:rule.bundleIdentifier];
        }
    }
    self.zoomController.matcher = matcher;

    self.zoomController.interpreter.preciseDeltaThreshold =
        self.preferences.preciseDeltaThreshold;
}

- (void)applicationDidTerminate:(NSNotification *)notification {
    NSRunningApplication *application =
        notification.userInfo[NSWorkspaceApplicationKey];
    NSString *bundleIdentifier = application.bundleIdentifier;
    if (bundleIdentifier != nil) {
        [self.zoomController.levelTracker resetBundleIdentifier:bundleIdentifier];
    }
}

#pragma mark - Login item

- (void)toggleLoginItem {
    NSError *error = nil;
    if ([self.loginItem setEnabled:!self.loginItem.isEnabled error:&error]) {
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = SZLocalizedLoginItemErrorTitle();
    alert.informativeText = error.localizedDescription ?: SZLocalizedLoginItemErrorFallback();
    [alert runModal];
}

#pragma mark - SZMenuStateProviding

- (BOOL)isLoginItemEnabled {
    return self.loginItem.isEnabled;
}

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

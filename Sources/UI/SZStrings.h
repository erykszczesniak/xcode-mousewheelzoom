#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Every user-facing string in one place, wrapped in NSLocalizedString so
/// translations only need a Localizable.strings file. Technical identifiers
/// (bundle ids, AX roles, defaults keys) stay with their owning types — they
/// are contracts, not copy.

#pragma mark - App

static inline NSString *SZLocalizedAppName(void) {
    return NSLocalizedString(@"ScrollZoom", @"App name shown in the menu and status item");
}

#pragma mark - Menu items

static inline NSString *SZLocalizedMenuEnabled(void) {
    return NSLocalizedString(@"Enabled", @"Master on/off toggle in the status menu");
}

static inline NSString *SZLocalizedMenuTargets(void) {
    return NSLocalizedString(@"Targets", @"Submenu listing the apps ScrollZoom acts on");
}

static inline NSString *SZLocalizedMenuSensitivity(void) {
    return NSLocalizedString(@"Sensitivity", @"Submenu with trackpad sensitivity presets");
}

static inline NSString *SZLocalizedMenuSensitivityLow(void) {
    return NSLocalizedString(@"Low", @"Least sensitive trackpad preset");
}

static inline NSString *SZLocalizedMenuSensitivityNormal(void) {
    return NSLocalizedString(@"Normal", @"Default trackpad sensitivity preset");
}

static inline NSString *SZLocalizedMenuSensitivityHigh(void) {
    return NSLocalizedString(@"High", @"Most sensitive trackpad preset");
}

static inline NSString *SZLocalizedMenuStartAtLogin(void) {
    return NSLocalizedString(@"Start at Login", @"Toggle registering the agent as a login item");
}

static inline NSString *SZLocalizedMenuSettings(void) {
    return NSLocalizedString(@"Settings…", @"Opens the Settings window");
}

static inline NSString *SZLocalizedMenuOpenAccessibilitySettings(void) {
    return NSLocalizedString(@"Open Accessibility Settings…",
                             @"Deep link to the Accessibility privacy pane");
}

static inline NSString *SZLocalizedMenuAbout(void) {
    return NSLocalizedString(@"About ScrollZoom", @"Standard about panel item");
}

static inline NSString *SZLocalizedMenuQuit(void) {
    return NSLocalizedString(@"Quit ScrollZoom", @"Quit item in the status menu");
}

#pragma mark - Status line

static inline NSString *SZLocalizedStatusPermissionNeeded(void) {
    return NSLocalizedString(@"Accessibility permission needed",
                             @"Status line while Accessibility is not granted");
}

static inline NSString *SZLocalizedStatusPaused(void) {
    return NSLocalizedString(@"Paused", @"Status line while the master toggle is off");
}

static inline NSString *SZLocalizedStatusActiveFormat(void) {
    return NSLocalizedString(@"Active — %@",
                             @"Status line while a target app is frontmost; %@ is the app name");
}

static inline NSString *SZLocalizedStatusArmed(void) {
    return NSLocalizedString(@"Armed — ⌘ + scroll in a target app",
                             @"Status line while armed but no target is frontmost");
}

#pragma mark - Permission explainer

static inline NSString *SZLocalizedPermissionExplainerTitle(void) {
    return NSLocalizedString(@"ScrollZoom needs Accessibility access",
                             @"First-run permission alert title");
}

static inline NSString *SZLocalizedPermissionExplainerBody(void) {
    return NSLocalizedString(@"ScrollZoom watches for ⌘ + scroll and sends the matching "
                             @"font-size shortcut to Xcode. macOS requires Accessibility "
                             @"permission for both.\n\nGrant access in System Settings → "
                             @"Privacy & Security → Accessibility. ScrollZoom stays inactive "
                             @"until then.",
                             @"First-run permission alert body");
}

static inline NSString *SZLocalizedPermissionExplainerContinue(void) {
    return NSLocalizedString(@"Continue", @"First-run permission alert button");
}

#pragma mark - Zoom HUD

static inline NSString *SZLocalizedHUDAccessibilityLabel(void) {
    return NSLocalizedString(@"Zoom level", @"Accessibility label for the zoom HUD overlay");
}

#pragma mark - Settings window

static inline NSString *SZLocalizedSettingsNoBundleIdentifierFormat(void) {
    return NSLocalizedString(@"“%@” has no bundle identifier, so it cannot be targeted.",
                             @"Error when a chosen app bundle lacks an identifier");
}

static inline NSString *SZLocalizedSettingsDuplicateTargetFormat(void) {
    return NSLocalizedString(@"%@ is already in the target list.",
                             @"Error when adding an app that is already a target");
}

#pragma mark - Login item errors

static inline NSString *SZLocalizedLoginItemErrorTitle(void) {
    return NSLocalizedString(@"Could not update the login item",
                             @"Alert title when SMAppService registration fails");
}

static inline NSString *SZLocalizedLoginItemErrorFallback(void) {
    return NSLocalizedString(@"Unknown error.",
                             @"Alert body when the failure has no description");
}

NS_ASSUME_NONNULL_END

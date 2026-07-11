#import "SZMenuController.h"

#import "SZStrings.h"

/// Trackpad pixels per zoom step for the three sensitivity presets. Lower
/// threshold = more steps for the same swipe = higher sensitivity.
static const double SZSensitivityLowThreshold = 25.0;
static const double SZSensitivityNormalThreshold = 15.0;
static const double SZSensitivityHighThreshold = 8.0;

@interface SZMenuController ()

@property (nonatomic, strong) SZPreferences *preferences;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenuItem *statusLineItem;
@property (nonatomic, strong) NSMenuItem *enabledItem;
@property (nonatomic, strong) NSMenuItem *targetsItem;
@property (nonatomic, strong) NSMenuItem *sensitivityItem;
@property (nonatomic, strong) NSMenuItem *loginItem;
@property (nonatomic, strong) NSMenuItem *settingsItem;

@end

@implementation SZMenuController

- (instancetype)initWithPreferences:(SZPreferences *)preferences {
    self = [super init];
    if (self) {
        _preferences = preferences;
    }
    return self;
}

- (void)install {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    NSImage *icon = [NSImage imageWithSystemSymbolName:@"plus.magnifyingglass"
                              accessibilityDescription:SZLocalizedAppName()];
    [icon setTemplate:YES];
    self.statusItem.button.image = icon;

    self.statusItem.menu = [self buildMenu];
}

#pragma mark - Menu construction

- (NSMenu *)buildMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:SZLocalizedAppName()];
    menu.delegate = self;
    menu.autoenablesItems = NO;

    self.statusLineItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedAppName()
                                                     action:NULL
                                              keyEquivalent:@""];
    self.statusLineItem.enabled = NO;
    [menu addItem:self.statusLineItem];

    [menu addItem:[NSMenuItem separatorItem]];

    self.enabledItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuEnabled()
                                                  action:@selector(toggleEnabled:)
                                           keyEquivalent:@""];
    self.enabledItem.target = self;
    [menu addItem:self.enabledItem];

    self.targetsItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuTargets()
                                                  action:NULL
                                           keyEquivalent:@""];
    self.targetsItem.submenu = [[NSMenu alloc] initWithTitle:SZLocalizedMenuTargets()];
    self.targetsItem.submenu.autoenablesItems = NO;
    [menu addItem:self.targetsItem];

    self.sensitivityItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuSensitivity()
                                                      action:NULL
                                               keyEquivalent:@""];
    self.sensitivityItem.submenu = [self buildSensitivityMenu];
    [menu addItem:self.sensitivityItem];

    self.loginItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuStartAtLogin()
                                                action:@selector(toggleLoginItem:)
                                         keyEquivalent:@""];
    self.loginItem.target = self;
    [menu addItem:self.loginItem];

    // No ⌘, key equivalent yet: status-item menus only match shortcuts while
    // open, and the agent has no main menu to route them — lands separately.
    NSMenuItem *settingsWindowItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuSettings()
                                                                action:@selector(openSettingsWindow:)
                                                         keyEquivalent:@""];
    settingsWindowItem.target = self;
    [menu addItem:settingsWindowItem];

    [menu addItem:[NSMenuItem separatorItem]];

    self.settingsItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuOpenAccessibilitySettings()
                                                   action:@selector(openSettings:)
                                            keyEquivalent:@""];
    self.settingsItem.target = self;
    [menu addItem:self.settingsItem];

    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuAbout()
                                                       action:@selector(showAbout:)
                                                keyEquivalent:@""];
    aboutItem.target = self;
    [menu addItem:aboutItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuQuit()
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    quitItem.target = NSApp;
    [menu addItem:quitItem];

    return menu;
}

- (NSMenu *)buildSensitivityMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:SZLocalizedMenuSensitivity()];
    menu.autoenablesItems = NO;
    NSArray<NSString *> *titles = @[ SZLocalizedMenuSensitivityLow(), SZLocalizedMenuSensitivityNormal(), SZLocalizedMenuSensitivityHigh() ];
    NSArray<NSNumber *> *thresholds = @[
        @(SZSensitivityLowThreshold), @(SZSensitivityNormalThreshold),
        @(SZSensitivityHighThreshold)
    ];
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                      action:@selector(selectSensitivity:)
                                               keyEquivalent:@""];
        item.target = self;
        item.representedObject = thresholds[index];
        [menu addItem:item];
    }];
    return menu;
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    BOOL permitted = [self.stateProvider isPermissionGranted];

    // Dim the menu bar icon whenever the gesture cannot fire.
    self.statusItem.button.appearsDisabled = !permitted || !self.preferences.isEnabled;

    self.statusLineItem.title = [self statusLineTextWithPermission:permitted];
    self.enabledItem.state = self.preferences.isEnabled ? NSControlStateValueOn
                                                        : NSControlStateValueOff;
    self.enabledItem.enabled = permitted;
    self.settingsItem.hidden = permitted;
    self.loginItem.state = [self.stateProvider isLoginItemEnabled] ? NSControlStateValueOn
                                                                   : NSControlStateValueOff;

    [self rebuildTargetsMenu];

    double threshold = self.preferences.preciseDeltaThreshold;
    for (NSMenuItem *item in self.sensitivityItem.submenu.itemArray) {
        double itemThreshold = [item.representedObject doubleValue];
        item.state = (fabs(itemThreshold - threshold) < 0.001) ? NSControlStateValueOn
                                                               : NSControlStateValueOff;
    }
}

- (NSString *)statusLineTextWithPermission:(BOOL)permitted {
    if (!permitted) {
        return SZLocalizedStatusPermissionNeeded();
    }
    if (!self.preferences.isEnabled) {
        return SZLocalizedStatusPaused();
    }
    NSString *activeTargetName = [self.stateProvider activeTargetName];
    if (activeTargetName != nil) {
        return [NSString stringWithFormat:SZLocalizedStatusActiveFormat(), activeTargetName];
    }
    return SZLocalizedStatusArmed();
}

- (void)rebuildTargetsMenu {
    NSMenu *submenu = self.targetsItem.submenu;
    [submenu removeAllItems];
    for (SZTargetRule *rule in self.preferences.configuredTargetRules) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[self displayNameForRule:rule]
                                                      action:@selector(toggleTarget:)
                                               keyEquivalent:@""];
        item.target = self;
        item.representedObject = rule.bundleIdentifier;
        item.state = [self.preferences isTargetEnabled:rule.bundleIdentifier]
                         ? NSControlStateValueOn
                         : NSControlStateValueOff;
        [submenu addItem:item];
    }
}

- (NSString *)displayNameForRule:(SZTargetRule *)rule {
    NSURL *appURL = [[NSWorkspace sharedWorkspace]
        URLForApplicationWithBundleIdentifier:rule.bundleIdentifier];
    if (appURL == nil) {
        return rule.bundleIdentifier;
    }
    NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:appURL.path];
    return displayName.length > 0 ? displayName : rule.bundleIdentifier;
}

#pragma mark - Actions

- (void)toggleEnabled:(NSMenuItem *)sender {
    self.preferences.enabled = !self.preferences.isEnabled;
}

- (void)toggleTarget:(NSMenuItem *)sender {
    NSString *bundleIdentifier = sender.representedObject;
    BOOL enabled = [self.preferences isTargetEnabled:bundleIdentifier];
    [self.preferences setTarget:bundleIdentifier enabled:!enabled];
}

- (void)selectSensitivity:(NSMenuItem *)sender {
    self.preferences.preciseDeltaThreshold = [sender.representedObject doubleValue];
}

- (void)openSettingsWindow:(NSMenuItem *)sender {
    if (self.openSettingsWindowHandler) {
        self.openSettingsWindowHandler();
    }
}

- (void)toggleLoginItem:(NSMenuItem *)sender {
    if (self.toggleLoginItemHandler) {
        self.toggleLoginItemHandler();
    }
}

- (void)showAbout:(NSMenuItem *)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

- (void)openSettings:(NSMenuItem *)sender {
    if (self.openSettingsHandler) {
        self.openSettingsHandler();
    }
}

@end

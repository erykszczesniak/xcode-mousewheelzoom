#import "SZMenuController.h"

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
                              accessibilityDescription:@"ScrollZoom"];
    [icon setTemplate:YES];
    self.statusItem.button.image = icon;

    self.statusItem.menu = [self buildMenu];
}

#pragma mark - Menu construction

- (NSMenu *)buildMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"ScrollZoom"];
    menu.delegate = self;
    menu.autoenablesItems = NO;

    self.statusLineItem = [[NSMenuItem alloc] initWithTitle:@"ScrollZoom"
                                                     action:NULL
                                              keyEquivalent:@""];
    self.statusLineItem.enabled = NO;
    [menu addItem:self.statusLineItem];

    [menu addItem:[NSMenuItem separatorItem]];

    self.enabledItem = [[NSMenuItem alloc] initWithTitle:@"Enabled"
                                                  action:@selector(toggleEnabled:)
                                           keyEquivalent:@""];
    self.enabledItem.target = self;
    [menu addItem:self.enabledItem];

    self.targetsItem = [[NSMenuItem alloc] initWithTitle:@"Targets"
                                                  action:NULL
                                           keyEquivalent:@""];
    self.targetsItem.submenu = [[NSMenu alloc] initWithTitle:@"Targets"];
    self.targetsItem.submenu.autoenablesItems = NO;
    [menu addItem:self.targetsItem];

    self.sensitivityItem = [[NSMenuItem alloc] initWithTitle:@"Sensitivity"
                                                      action:NULL
                                               keyEquivalent:@""];
    self.sensitivityItem.submenu = [self buildSensitivityMenu];
    [menu addItem:self.sensitivityItem];

    [menu addItem:[NSMenuItem separatorItem]];

    self.settingsItem = [[NSMenuItem alloc] initWithTitle:@"Open Accessibility Settings…"
                                                   action:@selector(openSettings:)
                                            keyEquivalent:@""];
    self.settingsItem.target = self;
    [menu addItem:self.settingsItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit ScrollZoom"
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    quitItem.target = NSApp;
    [menu addItem:quitItem];

    return menu;
}

- (NSMenu *)buildSensitivityMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Sensitivity"];
    menu.autoenablesItems = NO;
    NSArray<NSString *> *titles = @[ @"Low", @"Normal", @"High" ];
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

    self.statusLineItem.title = [self statusLineTextWithPermission:permitted];
    self.enabledItem.state = self.preferences.isEnabled ? NSControlStateValueOn
                                                        : NSControlStateValueOff;
    self.enabledItem.enabled = permitted;
    self.settingsItem.hidden = permitted;

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
        return @"Accessibility permission needed";
    }
    if (!self.preferences.isEnabled) {
        return @"Paused";
    }
    NSString *activeTargetName = [self.stateProvider activeTargetName];
    if (activeTargetName != nil) {
        return [NSString stringWithFormat:@"Active — %@", activeTargetName];
    }
    return @"Armed — ⌘ + scroll in a target app";
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
    [self notifyConfigurationChanged];
}

- (void)toggleTarget:(NSMenuItem *)sender {
    NSString *bundleIdentifier = sender.representedObject;
    BOOL enabled = [self.preferences isTargetEnabled:bundleIdentifier];
    [self.preferences setTarget:bundleIdentifier enabled:!enabled];
    [self notifyConfigurationChanged];
}

- (void)selectSensitivity:(NSMenuItem *)sender {
    self.preferences.preciseDeltaThreshold = [sender.representedObject doubleValue];
    [self notifyConfigurationChanged];
}

- (void)openSettings:(NSMenuItem *)sender {
    if (self.openSettingsHandler) {
        self.openSettingsHandler();
    }
}

- (void)notifyConfigurationChanged {
    if (self.configurationChangedHandler) {
        self.configurationChangedHandler();
    }
}

@end

#import <Foundation/Foundation.h>

#import "SZTargetRule.h"

NS_ASSUME_NONNULL_BEGIN

/// Posted after any preference mutation (master switch, sensitivity, target
/// set or per-target opt-out). Observers re-read whatever they need; the
/// object is the posting SZPreferences instance.
FOUNDATION_EXPORT NSNotificationName const SZPreferencesDidChangeNotification;

/// NSUserDefaults-backed configuration. Custom targets can be added without
/// UI, e.g.:
///
///   defaults write com.erykszczesniak.ScrollZoom SZTargets -array-add \
///     '{ bundleIdentifier = "com.example.editor"; editorRoles = (AXTextArea); }'
///
/// Optional per-target keys `zoomInKeyCode` / `zoomOutKeyCode` (virtual key
/// codes, posted with ⌘) override the default ⌘= / ⌘- mapping.
@interface SZPreferences : NSObject

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults NS_DESIGNATED_INITIALIZER;

/// Backed by `+[NSUserDefaults standardUserDefaults]`.
- (instancetype)init;

/// Master switch. Defaults to YES.
@property (nonatomic, getter=isEnabled) BOOL enabled;

/// Trackpad pixels per zoom step. Defaults to 15.
@property (nonatomic) double preciseDeltaThreshold;

/// Per-target opt-out, keyed by bundle identifier. Defaults to enabled.
- (BOOL)isTargetEnabled:(NSString *)bundleIdentifier;
- (void)setTarget:(NSString *)bundleIdentifier enabled:(BOOL)enabled;

/// Appends a role-agnostic rule for `bundleIdentifier` to the stored target
/// list (materializing the built-in defaults first, so they survive edits).
/// Returns NO if a rule for that bundle already exists.
- (BOOL)addTargetWithBundleIdentifier:(NSString *)bundleIdentifier;

/// Removes the rule for `bundleIdentifier` and clears its opt-out entry.
/// Returns NO if no such rule exists. Removing every rule leaves the agent
/// with nothing to act on (deliberate empty config, not a reset).
- (BOOL)removeTargetWithBundleIdentifier:(NSString *)bundleIdentifier;

/// All configured rules, disabled ones included — for listing in the menu.
@property (nonatomic, readonly) NSArray<SZTargetRule *> *configuredTargetRules;

/// The rules the matcher should act on: configured minus disabled.
@property (nonatomic, readonly) NSArray<SZTargetRule *> *activeTargetRules;

@end

NS_ASSUME_NONNULL_END

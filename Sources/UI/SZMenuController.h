#import <Cocoa/Cocoa.h>

#import "SZPreferences.h"

NS_ASSUME_NONNULL_BEGIN

/// Everything the menu needs to render live state. Implemented by the app
/// delegate — the UI layer holds no business logic.
@protocol SZMenuStateProviding <NSObject>

- (BOOL)isPermissionGranted;

/// Localized name of the frontmost app when it matches an active rule right
/// now, nil otherwise (passthrough).
- (nullable NSString *)activeTargetName;

/// Whether the agent is registered to start at login.
- (BOOL)isLoginItemEnabled;

@end

/// Owns the NSStatusItem and the agent's menu: status line, master toggle,
/// per-target toggles, sensitivity, and the Accessibility shortcut. State is
/// re-read every time the menu opens.
@interface SZMenuController : NSObject <NSMenuDelegate>

- (instancetype)initWithPreferences:(SZPreferences *)preferences NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, weak) id<SZMenuStateProviding> stateProvider;

/// Called from the "Open Accessibility Settings…" item.
@property (nonatomic, copy, nullable) void (^openSettingsHandler)(void);

/// Called from the "Start at Login" item.
@property (nonatomic, copy, nullable) void (^toggleLoginItemHandler)(void);

/// Called from the "Settings…" item (⌘,).
@property (nonatomic, copy, nullable) void (^openSettingsWindowHandler)(void);

/// Creates the status item and attaches the menu.
- (void)install;

@end

NS_ASSUME_NONNULL_END

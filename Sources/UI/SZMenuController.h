#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Owns the NSStatusItem and the agent's menu. UI only — business logic
/// lives in the core layer.
@interface SZMenuController : NSObject

/// Creates the status item and attaches the menu.
- (void)install;

/// Reflects the Accessibility permission state in the menu.
- (void)updatePermissionStatus:(BOOL)granted;

@end

NS_ASSUME_NONNULL_END

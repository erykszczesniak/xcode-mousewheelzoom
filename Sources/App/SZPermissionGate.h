#import <Foundation/Foundation.h>

#import "SZAccessibility.h"

NS_ASSUME_NONNULL_BEGIN

/// Blocks arming of the event pipeline until Accessibility is granted.
/// Shows a one-time explainer, triggers the system prompt, then polls the
/// trust state until the user flips the switch in System Settings.
@interface SZPermissionGate : NSObject

- (instancetype)initWithTrustChecker:(id<SZAccessibilityTrustChecking>)trustChecker;
- (instancetype)init NS_UNAVAILABLE;

/// YES once Accessibility has been granted.
@property (nonatomic, readonly, getter=isTrusted) BOOL trusted;

/// Runs the gate. Calls `grantedHandler` on the main queue — immediately if
/// already trusted, otherwise after the user grants access. Never times out;
/// the agent stays disarmed (and says so) until permission arrives.
- (void)runWithGrantedHandler:(void (^)(void))grantedHandler;

@end

NS_ASSUME_NONNULL_END

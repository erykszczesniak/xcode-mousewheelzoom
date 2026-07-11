#import <Foundation/Foundation.h>

#import "SZTargetRule.h"

NS_ASSUME_NONNULL_BEGIN

/// Decides whether the current frontmost app + focus qualifies for zooming.
/// Pure lookup over a rule list — the live AX values are queried by the edge
/// layer and passed in, so this stays unit-testable.
@interface SZTargetMatcher : NSObject

@property (nonatomic, copy, readonly) NSArray<SZTargetRule *> *rules;

- (instancetype)initWithRules:(NSArray<SZTargetRule *> *)rules NS_DESIGNATED_INITIALIZER;

/// Rules containing only the built-in Xcode default.
- (instancetype)init;

/// Returns the rule to act under, or nil for passthrough. A rule matches
/// when the bundle identifier is equal and, if the rule constrains editor
/// roles, the focused role is one of them.
- (nullable SZTargetRule *)ruleMatchingBundleIdentifier:(nullable NSString *)bundleIdentifier
                                            focusedRole:(nullable NSString *)focusedRole;

@end

NS_ASSUME_NONNULL_END

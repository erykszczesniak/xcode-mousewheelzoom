#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const SZXcodeBundleIdentifier;

/// Immutable description of one app ScrollZoom is allowed to act on: which
/// bundle, and (optionally) which focused Accessibility roles count as "the
/// editor" there.
@interface SZTargetRule : NSObject

@property (nonatomic, copy, readonly) NSString *bundleIdentifier;

/// Focused AX roles that qualify (e.g. `AXTextArea`). nil means any focus
/// inside the app qualifies.
@property (nonatomic, copy, readonly, nullable) NSSet<NSString *> *editorRoles;

+ (instancetype)ruleWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(nullable NSSet<NSString *> *)editorRoles;

/// The built-in default: Xcode, acting only while a text area has focus.
+ (instancetype)xcodeRule;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

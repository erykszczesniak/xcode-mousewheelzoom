#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const SZXcodeBundleIdentifier;

@class SZActionMapper;

/// Immutable description of one app ScrollZoom is allowed to act on: which
/// bundle, (optionally) which focused Accessibility roles count as "the
/// editor" there, and (optionally) its own shortcut mapping.
@interface SZTargetRule : NSObject

@property (nonatomic, copy, readonly) NSString *bundleIdentifier;

/// Focused AX roles that qualify (e.g. `AXTextArea`). nil means any focus
/// inside the app qualifies.
@property (nonatomic, copy, readonly, nullable) NSSet<NSString *> *editorRoles;

/// Shortcut mapping specific to this app; nil falls back to the default
/// (⌘= / ⌘-).
@property (nonatomic, strong, readonly, nullable) SZActionMapper *mapper;

+ (instancetype)ruleWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(nullable NSSet<NSString *> *)editorRoles;

+ (instancetype)ruleWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(nullable NSSet<NSString *> *)editorRoles
                                  mapper:(nullable SZActionMapper *)mapper;

/// The built-in default: Xcode, regardless of which element has focus.
+ (instancetype)xcodeRule;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

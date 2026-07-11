#import "SZTargetRule.h"

NSString *const SZXcodeBundleIdentifier = @"com.apple.dt.Xcode";

@implementation SZTargetRule

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(NSSet<NSString *> *)editorRoles {
    self = [super init];
    if (self) {
        _bundleIdentifier = [bundleIdentifier copy];
        _editorRoles = [editorRoles copy];
    }
    return self;
}

+ (instancetype)ruleWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(NSSet<NSString *> *)editorRoles {
    return [[self alloc] initWithBundleIdentifier:bundleIdentifier editorRoles:editorRoles];
}

+ (instancetype)xcodeRule {
    return [self ruleWithBundleIdentifier:SZXcodeBundleIdentifier
                              editorRoles:[NSSet setWithObject:@"AXTextArea"]];
}

@end

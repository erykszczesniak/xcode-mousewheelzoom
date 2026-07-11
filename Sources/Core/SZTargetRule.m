#import "SZTargetRule.h"

#import "SZActionMapper.h"

NSString *const SZXcodeBundleIdentifier = @"com.apple.dt.Xcode";

@implementation SZTargetRule

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(NSSet<NSString *> *)editorRoles
                                  mapper:(SZActionMapper *)mapper {
    self = [super init];
    if (self) {
        _bundleIdentifier = [bundleIdentifier copy];
        _editorRoles = [editorRoles copy];
        _mapper = mapper;
    }
    return self;
}

+ (instancetype)ruleWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(NSSet<NSString *> *)editorRoles {
    return [[self alloc] initWithBundleIdentifier:bundleIdentifier
                                      editorRoles:editorRoles
                                           mapper:nil];
}

+ (instancetype)ruleWithBundleIdentifier:(NSString *)bundleIdentifier
                             editorRoles:(NSSet<NSString *> *)editorRoles
                                  mapper:(SZActionMapper *)mapper {
    return [[self alloc] initWithBundleIdentifier:bundleIdentifier
                                      editorRoles:editorRoles
                                           mapper:mapper];
}

+ (instancetype)xcodeRule {
    // No role constraint: Xcode's font-size shortcuts are app-wide, so the
    // gesture should work with the navigator or toolbar focused too.
    return [self ruleWithBundleIdentifier:SZXcodeBundleIdentifier editorRoles:nil];
}

@end

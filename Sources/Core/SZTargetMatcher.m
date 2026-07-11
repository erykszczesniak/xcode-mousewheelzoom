#import "SZTargetMatcher.h"

@implementation SZTargetMatcher

- (instancetype)initWithRules:(NSArray<SZTargetRule *> *)rules {
    self = [super init];
    if (self) {
        _rules = [rules copy];
    }
    return self;
}

- (instancetype)init {
    return [self initWithRules:@[ [SZTargetRule xcodeRule] ]];
}

- (SZTargetRule *)ruleMatchingBundleIdentifier:(NSString *)bundleIdentifier
                                   focusedRole:(NSString *)focusedRole {
    if (bundleIdentifier.length == 0) {
        return nil;
    }

    for (SZTargetRule *rule in self.rules) {
        if (![rule.bundleIdentifier isEqualToString:bundleIdentifier]) {
            continue;
        }
        if (rule.editorRoles == nil) {
            return rule;
        }
        if (focusedRole != nil && [rule.editorRoles containsObject:focusedRole]) {
            return rule;
        }
    }
    return nil;
}

@end

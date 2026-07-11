#import "SZPreferences.h"

#import "SZActionMapper.h"

NSNotificationName const SZPreferencesDidChangeNotification =
    @"SZPreferencesDidChangeNotification";

static NSString *const SZEnabledKey = @"SZEnabled";
static NSString *const SZPreciseDeltaThresholdKey = @"SZPreciseDeltaThreshold";
static NSString *const SZDisabledTargetsKey = @"SZDisabledTargets";
static NSString *const SZTargetsKey = @"SZTargets";

static NSString *const SZTargetBundleIdentifierKey = @"bundleIdentifier";
static NSString *const SZTargetEditorRolesKey = @"editorRoles";
static NSString *const SZTargetZoomInKeyCodeKey = @"zoomInKeyCode";
static NSString *const SZTargetZoomOutKeyCodeKey = @"zoomOutKeyCode";

static const double SZDefaultPreciseDeltaThresholdValue = 15.0;

@interface SZPreferences ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation SZPreferences

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

- (instancetype)init {
    return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
}

#pragma mark - Master switch

- (BOOL)isEnabled {
    if ([self.userDefaults objectForKey:SZEnabledKey] == nil) {
        return YES;
    }
    return [self.userDefaults boolForKey:SZEnabledKey];
}

- (void)setEnabled:(BOOL)enabled {
    [self.userDefaults setBool:enabled forKey:SZEnabledKey];
    [self notifyChanged];
}

- (void)notifyChanged {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:SZPreferencesDidChangeNotification
                      object:self];
}

#pragma mark - Sensitivity

- (double)preciseDeltaThreshold {
    double stored = [self.userDefaults doubleForKey:SZPreciseDeltaThresholdKey];
    return stored > 0.0 ? stored : SZDefaultPreciseDeltaThresholdValue;
}

- (void)setPreciseDeltaThreshold:(double)preciseDeltaThreshold {
    [self.userDefaults setDouble:preciseDeltaThreshold forKey:SZPreciseDeltaThresholdKey];
    [self notifyChanged];
}

#pragma mark - Per-target opt-out

- (BOOL)isTargetEnabled:(NSString *)bundleIdentifier {
    NSArray *disabled = [self.userDefaults stringArrayForKey:SZDisabledTargetsKey];
    return ![disabled containsObject:bundleIdentifier];
}

- (void)setTarget:(NSString *)bundleIdentifier enabled:(BOOL)enabled {
    NSMutableOrderedSet<NSString *> *disabled = [NSMutableOrderedSet orderedSet];
    NSArray *stored = [self.userDefaults stringArrayForKey:SZDisabledTargetsKey];
    if (stored != nil) {
        [disabled addObjectsFromArray:stored];
    }

    if (enabled) {
        [disabled removeObject:bundleIdentifier];
    } else {
        [disabled addObject:bundleIdentifier];
    }
    [self.userDefaults setObject:disabled.array forKey:SZDisabledTargetsKey];
    [self notifyChanged];
}

#pragma mark - Target rules

- (NSArray<SZTargetRule *> *)configuredTargetRules {
    NSArray *storedTargets = [self.userDefaults arrayForKey:SZTargetsKey];
    if (storedTargets == nil) {
        return @[ [SZTargetRule xcodeRule] ];
    }
    // An explicitly empty list is a deliberate "act on nothing" config; only
    // a missing key (or an all-malformed list) falls back to the default.
    if (storedTargets.count == 0) {
        return @[];
    }

    NSMutableArray<SZTargetRule *> *rules = [NSMutableArray arrayWithCapacity:storedTargets.count];
    for (id entry in storedTargets) {
        SZTargetRule *rule = [self ruleFromDictionary:entry];
        if (rule != nil) {
            [rules addObject:rule];
        }
    }
    return rules.count > 0 ? [rules copy] : @[ [SZTargetRule xcodeRule] ];
}

#pragma mark - Target mutations

- (BOOL)addTargetWithBundleIdentifier:(NSString *)bundleIdentifier {
    if (bundleIdentifier.length == 0) {
        return NO;
    }
    for (SZTargetRule *rule in self.configuredTargetRules) {
        if ([rule.bundleIdentifier isEqualToString:bundleIdentifier]) {
            return NO;
        }
    }

    NSMutableArray *stored = [[self materializedStoredTargets] mutableCopy];
    [stored addObject:@{SZTargetBundleIdentifierKey : bundleIdentifier}];
    [self.userDefaults setObject:stored forKey:SZTargetsKey];
    [self notifyChanged];
    return YES;
}

- (BOOL)removeTargetWithBundleIdentifier:(NSString *)bundleIdentifier {
    NSMutableArray *remaining = [NSMutableArray array];
    BOOL found = NO;
    for (NSDictionary *entry in [self materializedStoredTargets]) {
        if ([entry[SZTargetBundleIdentifierKey] isEqual:bundleIdentifier]) {
            found = YES;
            continue;
        }
        [remaining addObject:entry];
    }
    if (!found) {
        return NO;
    }

    [self.userDefaults setObject:remaining forKey:SZTargetsKey];
    // A stale opt-out must not silently disable the target if it is
    // re-added. Runs after the SZTargets write so the notification it posts
    // already sees the fully-updated state.
    [self setTarget:bundleIdentifier enabled:YES];
    return YES;
}

/// The stored SZTargets list as mutations should see it: always consistent
/// with the parsed view `configuredTargetRules` exposes. Valid entries are
/// kept verbatim (custom keys survive); malformed ones are dropped on the
/// first rewrite; when the key is absent — or every entry is malformed and
/// the parsed view falls back to the defaults — the visible rules are
/// serialized out first so edits never lose them.
- (NSArray<NSDictionary *> *)materializedStoredTargets {
    NSArray *storedTargets = [self.userDefaults arrayForKey:SZTargetsKey];
    if (storedTargets != nil) {
        NSMutableArray<NSDictionary *> *valid = [NSMutableArray array];
        for (id entry in storedTargets) {
            if ([self ruleFromDictionary:entry] != nil) {
                [valid addObject:entry];
            }
        }
        // An empty stored list stays deliberately empty; only an all-
        // malformed list falls through to the fallback the user can see.
        if (valid.count > 0 || storedTargets.count == 0) {
            return valid;
        }
    }

    NSMutableArray<NSDictionary *> *materialized = [NSMutableArray array];
    for (SZTargetRule *rule in self.configuredTargetRules) {
        [materialized addObject:[self dictionaryFromRule:rule]];
    }
    return materialized;
}

- (NSDictionary *)dictionaryFromRule:(SZTargetRule *)rule {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[SZTargetBundleIdentifierKey] = rule.bundleIdentifier;
    if (rule.editorRoles.count > 0) {
        dictionary[SZTargetEditorRolesKey] = rule.editorRoles.allObjects;
    }
    return [dictionary copy];
}

- (NSArray<SZTargetRule *> *)activeTargetRules {
    NSMutableArray<SZTargetRule *> *active = [NSMutableArray array];
    for (SZTargetRule *rule in self.configuredTargetRules) {
        if ([self isTargetEnabled:rule.bundleIdentifier]) {
            [active addObject:rule];
        }
    }
    return [active copy];
}

- (nullable SZTargetRule *)ruleFromDictionary:(id)entry {
    if (![entry isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dictionary = entry;

    NSString *bundleIdentifier = dictionary[SZTargetBundleIdentifierKey];
    if (![bundleIdentifier isKindOfClass:[NSString class]] || bundleIdentifier.length == 0) {
        return nil;
    }

    NSSet<NSString *> *editorRoles = nil;
    NSArray *storedRoles = dictionary[SZTargetEditorRolesKey];
    if ([storedRoles isKindOfClass:[NSArray class]] && storedRoles.count > 0) {
        editorRoles = [NSSet setWithArray:storedRoles];
    }

    return [SZTargetRule ruleWithBundleIdentifier:bundleIdentifier
                                      editorRoles:editorRoles
                                           mapper:[self mapperFromDictionary:dictionary]];
}

- (nullable SZActionMapper *)mapperFromDictionary:(NSDictionary *)dictionary {
    NSNumber *zoomInKeyCode = dictionary[SZTargetZoomInKeyCodeKey];
    NSNumber *zoomOutKeyCode = dictionary[SZTargetZoomOutKeyCodeKey];
    if (![zoomInKeyCode isKindOfClass:[NSNumber class]] ||
        ![zoomOutKeyCode isKindOfClass:[NSNumber class]]) {
        return nil;
    }

    SZKeystrokeSpec zoomIn = SZKeystrokeSpecMake(zoomInKeyCode.unsignedShortValue,
                                                 kCGEventFlagMaskCommand);
    SZKeystrokeSpec zoomOut = SZKeystrokeSpecMake(zoomOutKeyCode.unsignedShortValue,
                                                  kCGEventFlagMaskCommand);
    return [[SZActionMapper alloc] initWithZoomInKeystroke:zoomIn zoomOutKeystroke:zoomOut];
}

@end

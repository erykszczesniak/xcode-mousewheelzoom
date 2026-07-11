#import "SZPreferences.h"

#import "SZActionMapper.h"

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
}

#pragma mark - Sensitivity

- (double)preciseDeltaThreshold {
    double stored = [self.userDefaults doubleForKey:SZPreciseDeltaThresholdKey];
    return stored > 0.0 ? stored : SZDefaultPreciseDeltaThresholdValue;
}

- (void)setPreciseDeltaThreshold:(double)preciseDeltaThreshold {
    [self.userDefaults setDouble:preciseDeltaThreshold forKey:SZPreciseDeltaThresholdKey];
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
}

#pragma mark - Target rules

- (NSArray<SZTargetRule *> *)configuredTargetRules {
    NSArray *storedTargets = [self.userDefaults arrayForKey:SZTargetsKey];
    if (storedTargets.count == 0) {
        return @[ [SZTargetRule xcodeRule] ];
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

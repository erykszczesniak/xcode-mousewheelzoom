#import "SZZoomLevelTracker.h"

@interface SZZoomLevelTracker ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *stepsByBundle;

@end

@implementation SZZoomLevelTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        _stepsByBundle = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSInteger)applyIntent:(SZZoomIntent)intent
     forBundleIdentifier:(NSString *)bundleIdentifier {
    NSInteger delta = 0;
    switch (intent) {
        case SZZoomIntentIn:
            delta = 1;
            break;
        case SZZoomIntentOut:
            delta = -1;
            break;
        case SZZoomIntentNone:
            break;
    }

    NSInteger steps = [self stepsForBundleIdentifier:bundleIdentifier] + delta;
    if (bundleIdentifier != nil) {
        self.stepsByBundle[bundleIdentifier] = @(steps);
    }
    return steps;
}

- (NSInteger)stepsForBundleIdentifier:(NSString *)bundleIdentifier {
    if (bundleIdentifier == nil) {
        return 0;
    }
    return self.stepsByBundle[bundleIdentifier].integerValue;
}

- (void)resetBundleIdentifier:(NSString *)bundleIdentifier {
    if (bundleIdentifier != nil) {
        [self.stepsByBundle removeObjectForKey:bundleIdentifier];
    }
}

@end

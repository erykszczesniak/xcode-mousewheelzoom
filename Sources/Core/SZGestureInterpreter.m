 #import "SZGestureInterpreter.h"

static const double SZDefaultPreciseDeltaThreshold = 15.0;
static const NSTimeInterval SZDefaultThrottleInterval = 0.05;
static const NSTimeInterval SZDefaultIdleResetInterval = 0.3;

@interface SZGestureInterpreter ()

@property (nonatomic) double accumulatedDelta;
@property (nonatomic) NSTimeInterval lastSampleTimestamp;
@property (nonatomic) NSTimeInterval lastStepTimestamp;

@end

@implementation SZGestureInterpreter

- (instancetype)initWithPreciseDeltaThreshold:(double)preciseDeltaThreshold
                             throttleInterval:(NSTimeInterval)throttleInterval
                            idleResetInterval:(NSTimeInterval)idleResetInterval {
    self = [super init];
    if (self) {
        _preciseDeltaThreshold = preciseDeltaThreshold;
        _throttleInterval = throttleInterval;
        _idleResetInterval = idleResetInterval;
        [self reset];
    }
    return self;
}

- (instancetype)init {
    return [self initWithPreciseDeltaThreshold:SZDefaultPreciseDeltaThreshold
                              throttleInterval:SZDefaultThrottleInterval
                             idleResetInterval:SZDefaultIdleResetInterval];
}

- (void)reset {
    self.accumulatedDelta = 0.0;
    self.lastSampleTimestamp = -DBL_MAX;
    self.lastStepTimestamp = -DBL_MAX;
}

- (SZZoomIntent)intentForSample:(SZScrollSample)sample {
    // A flick's inertial tail would keep zooming long after the fingers
    // lifted — drop it outright.
    if (sample.isMomentumPhase || sample.deltaY == 0.0) {
        return SZZoomIntentNone;
    }

    BOOL idle = (sample.timestamp - self.lastSampleTimestamp) > self.idleResetInterval;
    BOOL flipped = (self.accumulatedDelta != 0.0 &&
                    signbit(self.accumulatedDelta) != signbit(sample.deltaY));
    if (idle || flipped) {
        self.accumulatedDelta = 0.0;
    }
    self.lastSampleTimestamp = sample.timestamp;

    SZZoomIntent candidate;
    if (sample.hasPreciseDeltas) {
        self.accumulatedDelta += sample.deltaY;
        if (fabs(self.accumulatedDelta) < self.preciseDeltaThreshold) {
            return SZZoomIntentNone;
        }
        candidate = (self.accumulatedDelta > 0.0) ? SZZoomIntentIn : SZZoomIntentOut;
    } else {
        // Wheel notch: every event is a step candidate regardless of how
        // many lines the system scaled it to.
        candidate = (sample.deltaY > 0.0) ? SZZoomIntentIn : SZZoomIntentOut;
    }

    if ((sample.timestamp - self.lastStepTimestamp) < self.throttleInterval) {
        // Cap the backlog so a burst during the throttle window yields at
        // most one step once it reopens.
        if (sample.hasPreciseDeltas) {
            self.accumulatedDelta = copysign(self.preciseDeltaThreshold, self.accumulatedDelta);
        }
        return SZZoomIntentNone;
    }

    self.lastStepTimestamp = sample.timestamp;
    self.accumulatedDelta = 0.0;
    return candidate;
}

@end

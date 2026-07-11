#import <Foundation/Foundation.h>

#import "SZScrollSample.h"
#import "SZZoomIntent.h"

NS_ASSUME_NONNULL_BEGIN

/// Turns raw scroll samples into discrete zoom steps. Pure state machine —
/// no NSEvent, no AX, no timers — so every rule is unit-testable:
///
/// - one wheel notch = one step, rate-limited so spinning the wheel cannot
///   produce runaway zoom
/// - trackpad (precise) deltas accumulate until a threshold before emitting
///   a step
/// - the inertial momentum tail is ignored
/// - a direction flip or an idle pause resets the accumulator
@interface SZGestureInterpreter : NSObject

/// Pixels of precise (trackpad) scroll needed per zoom step. Writable so
/// sensitivity can be tuned at runtime.
@property (nonatomic) double preciseDeltaThreshold;

/// Minimum seconds between two emitted steps.
@property (nonatomic, readonly) NSTimeInterval throttleInterval;

/// Pause after which partial trackpad accumulation is discarded.
@property (nonatomic, readonly) NSTimeInterval idleResetInterval;

- (instancetype)initWithPreciseDeltaThreshold:(double)preciseDeltaThreshold
                             throttleInterval:(NSTimeInterval)throttleInterval
                            idleResetInterval:(NSTimeInterval)idleResetInterval
    NS_DESIGNATED_INITIALIZER;

/// Defaults tuned for a notch-per-step wheel feel: 15 px per trackpad step,
/// 50 ms throttle, 300 ms idle reset.
- (instancetype)init;

/// Feeds one sample through the state machine. Returns the step to perform
/// now, or `SZZoomIntentNone`.
- (SZZoomIntent)intentForSample:(SZScrollSample)sample;

/// Clears accumulation and throttle state (e.g. when ⌘ is released or the
/// frontmost app changes).
- (void)reset;

@end

NS_ASSUME_NONNULL_END

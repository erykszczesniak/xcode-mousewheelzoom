#import <XCTest/XCTest.h>

#import "SZGestureInterpreter.h"

static SZScrollSample SZWheelSample(double deltaY, NSTimeInterval timestamp) {
    return (SZScrollSample){.deltaY = deltaY,
                            .hasPreciseDeltas = NO,
                            .isMomentumPhase = NO,
                            .timestamp = timestamp};
}

static SZScrollSample SZTrackpadSample(double deltaY, NSTimeInterval timestamp) {
    return (SZScrollSample){.deltaY = deltaY,
                            .hasPreciseDeltas = YES,
                            .isMomentumPhase = NO,
                            .timestamp = timestamp};
}

@interface SZGestureInterpreterTests : XCTestCase
@end

@implementation SZGestureInterpreterTests {
    SZGestureInterpreter *_interpreter;
}

- (void)setUp {
    [super setUp];
    _interpreter = [[SZGestureInterpreter alloc] initWithPreciseDeltaThreshold:15.0
                                                              throttleInterval:0.05
                                                             idleResetInterval:0.3];
}

#pragma mark - Wheel notches

- (void)testWheelNotchUpZoomsIn {
    XCTAssertEqual([_interpreter intentForSample:SZWheelSample(3.0, 1.0)], SZZoomIntentIn);
}

- (void)testWheelNotchDownZoomsOut {
    XCTAssertEqual([_interpreter intentForSample:SZWheelSample(-3.0, 1.0)], SZZoomIntentOut);
}

- (void)testZeroDeltaIsIgnored {
    XCTAssertEqual([_interpreter intentForSample:SZWheelSample(0.0, 1.0)], SZZoomIntentNone);
}

- (void)testNotchWithinThrottleWindowIsSuppressed {
    XCTAssertEqual([_interpreter intentForSample:SZWheelSample(3.0, 1.0)], SZZoomIntentIn);
    XCTAssertEqual([_interpreter intentForSample:SZWheelSample(3.0, 1.01)], SZZoomIntentNone);
}

- (void)testNotchAfterThrottleWindowFires {
    XCTAssertEqual([_interpreter intentForSample:SZWheelSample(3.0, 1.0)], SZZoomIntentIn);
    XCTAssertEqual([_interpreter intentForSample:SZWheelSample(3.0, 1.1)], SZZoomIntentIn);
}

#pragma mark - Trackpad accumulation

- (void)testSmallPreciseDeltasAccumulateToOneStep {
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(6.0, 1.00)], SZZoomIntentNone);
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(6.0, 1.02)], SZZoomIntentNone);
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(6.0, 1.10)], SZZoomIntentIn);
}

- (void)testPreciseDeltaBelowThresholdEmitsNothing {
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(14.0, 1.0)], SZZoomIntentNone);
}

- (void)testDirectionFlipResetsAccumulation {
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(14.0, 1.00)], SZZoomIntentNone);
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(-4.0, 1.02)], SZZoomIntentNone);
    // The flip discarded +14; -4 alone must stay below the threshold.
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(-10.0, 1.04)], SZZoomIntentNone);
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(-2.0, 1.06)], SZZoomIntentOut);
}

- (void)testIdlePauseResetsAccumulation {
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(14.0, 1.0)], SZZoomIntentNone);
    // 14 more px after a long pause: earlier accumulation must be gone.
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(14.0, 2.0)], SZZoomIntentNone);
}

- (void)testBurstDuringThrottleYieldsSingleStepAfterWindow {
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(20.0, 1.00)], SZZoomIntentIn);
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(40.0, 1.01)], SZZoomIntentNone);
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(40.0, 1.02)], SZZoomIntentNone);
    // Window reopens: exactly one step, backlog was capped at one threshold.
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(1.0, 1.10)], SZZoomIntentIn);
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(1.0, 1.16)], SZZoomIntentNone);
}

#pragma mark - Momentum and reset

- (void)testMomentumSamplesAreIgnored {
    SZScrollSample momentum = {.deltaY = 40.0,
                               .hasPreciseDeltas = YES,
                               .isMomentumPhase = YES,
                               .timestamp = 1.0};
    XCTAssertEqual([_interpreter intentForSample:momentum], SZZoomIntentNone);
}

- (void)testResetClearsAccumulation {
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(14.0, 1.00)], SZZoomIntentNone);
    [_interpreter reset];
    XCTAssertEqual([_interpreter intentForSample:SZTrackpadSample(14.0, 1.02)], SZZoomIntentNone);
}

@end

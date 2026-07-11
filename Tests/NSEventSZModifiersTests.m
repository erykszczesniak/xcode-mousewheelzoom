#import <XCTest/XCTest.h>

#import "NSEvent+SZModifiers.h"

@interface NSEventSZModifiersTests : XCTestCase
@end

@implementation NSEventSZModifiersTests

- (NSEvent *)scrollEventWithFlags:(CGEventFlags)flags {
    CGEventRef cgEvent = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitLine, 1, 3);
    CGEventSetFlags(cgEvent, flags);
    NSEvent *event = [NSEvent eventWithCGEvent:cgEvent];
    CFRelease(cgEvent);
    return event;
}

- (void)testCommandAloneMatches {
    NSEvent *event = [self scrollEventWithFlags:kCGEventFlagMaskCommand];
    XCTAssertTrue(event.sz_hasCommandOnlyModifier);
}

- (void)testNoModifiersDoesNotMatch {
    NSEvent *event = [self scrollEventWithFlags:0];
    XCTAssertFalse(event.sz_hasCommandOnlyModifier);
}

- (void)testCommandWithShiftDoesNotMatch {
    NSEvent *event = [self scrollEventWithFlags:kCGEventFlagMaskCommand | kCGEventFlagMaskShift];
    XCTAssertFalse(event.sz_hasCommandOnlyModifier);
}

- (void)testCommandWithOptionDoesNotMatch {
    NSEvent *event = [self scrollEventWithFlags:kCGEventFlagMaskCommand | kCGEventFlagMaskAlternate];
    XCTAssertFalse(event.sz_hasCommandOnlyModifier);
}

- (void)testCapsLockWithCommandStillMatches {
    NSEvent *event = [self scrollEventWithFlags:kCGEventFlagMaskCommand | kCGEventFlagMaskAlphaShift];
    XCTAssertTrue(event.sz_hasCommandOnlyModifier);
}

- (void)testScrollSampleCarriesLineDelta {
    NSEvent *event = [self scrollEventWithFlags:0];
    SZScrollSample sample = event.sz_scrollSample;
    XCTAssertGreaterThan(sample.deltaY, 0.0);
    XCTAssertFalse(sample.isMomentumPhase);
}

@end

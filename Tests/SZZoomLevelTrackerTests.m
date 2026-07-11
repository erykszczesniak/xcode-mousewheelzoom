#import <XCTest/XCTest.h>

#import "SZZoomLevelTracker.h"

static NSString *const SZTrackerXcode = @"com.apple.dt.Xcode";
static NSString *const SZTrackerOther = @"com.example.editor";

@interface SZZoomLevelTrackerTests : XCTestCase
@end

@implementation SZZoomLevelTrackerTests {
    SZZoomLevelTracker *_tracker;
}

- (void)setUp {
    [super setUp];
    _tracker = [[SZZoomLevelTracker alloc] init];
}

- (void)testUntouchedAppHasNoSteps {
    XCTAssertEqual([_tracker stepsForBundleIdentifier:SZTrackerXcode], 0);
}

- (void)testZoomInAndOutAccumulate {
    XCTAssertEqual([_tracker applyIntent:SZZoomIntentIn forBundleIdentifier:SZTrackerXcode], 1);
    XCTAssertEqual([_tracker applyIntent:SZZoomIntentIn forBundleIdentifier:SZTrackerXcode], 2);
    XCTAssertEqual([_tracker applyIntent:SZZoomIntentOut forBundleIdentifier:SZTrackerXcode], 1);
    XCTAssertEqual([_tracker stepsForBundleIdentifier:SZTrackerXcode], 1);
}

- (void)testStepsGoNegativeWhenZoomingOutFromZero {
    XCTAssertEqual([_tracker applyIntent:SZZoomIntentOut forBundleIdentifier:SZTrackerXcode], -1);
}

- (void)testNoneIntentDoesNotChangeCount {
    [_tracker applyIntent:SZZoomIntentIn forBundleIdentifier:SZTrackerXcode];
    XCTAssertEqual([_tracker applyIntent:SZZoomIntentNone forBundleIdentifier:SZTrackerXcode], 1);
}

- (void)testCountsAreIsolatedPerApp {
    [_tracker applyIntent:SZZoomIntentIn forBundleIdentifier:SZTrackerXcode];
    [_tracker applyIntent:SZZoomIntentOut forBundleIdentifier:SZTrackerOther];

    XCTAssertEqual([_tracker stepsForBundleIdentifier:SZTrackerXcode], 1);
    XCTAssertEqual([_tracker stepsForBundleIdentifier:SZTrackerOther], -1);
}

- (void)testResetForgetsOneAppOnly {
    [_tracker applyIntent:SZZoomIntentIn forBundleIdentifier:SZTrackerXcode];
    [_tracker applyIntent:SZZoomIntentIn forBundleIdentifier:SZTrackerOther];

    [_tracker resetBundleIdentifier:SZTrackerXcode];
    XCTAssertEqual([_tracker stepsForBundleIdentifier:SZTrackerXcode], 0);
    XCTAssertEqual([_tracker stepsForBundleIdentifier:SZTrackerOther], 1);
}

@end

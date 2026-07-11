#import <XCTest/XCTest.h>

#import "SZZoomController.h"

#pragma mark - Fakes

@interface SZFakeScrollMonitor : NSObject <SZScrollEventMonitoring>
@property (nonatomic, copy, nullable) SZScrollEventHandler handler;
@end

@implementation SZFakeScrollMonitor

- (BOOL)isMonitoring {
    return self.handler != nil;
}

- (void)startWithHandler:(SZScrollEventHandler)handler {
    self.handler = handler;
}

- (void)stop {
    self.handler = nil;
}

- (void)sendSample:(SZScrollSample)sample commandOnly:(BOOL)commandOnly {
    if (self.handler) {
        self.handler(sample, commandOnly);
    }
}

@end

@interface SZFakeFocusInspector : NSObject <SZFocusInspecting>
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;
@property (nonatomic, copy, nullable) NSString *focusedRole;
@property (nonatomic) pid_t processIdentifier;
@property (nonatomic) NSUInteger focusedRoleQueryCount;
@end

@implementation SZFakeFocusInspector

- (NSString *)frontmostApplicationBundleIdentifier {
    return self.bundleIdentifier;
}

- (pid_t)frontmostApplicationProcessIdentifier {
    return self.processIdentifier;
}

- (NSString *)focusedElementRole {
    self.focusedRoleQueryCount += 1;
    return self.focusedRole;
}

@end

@interface SZFakeKeystrokePoster : NSObject <SZKeystrokePosting>
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *posted;
/// Mimics the real synthesizer, which cannot deliver to a dead process.
@property (nonatomic) BOOL deliverySucceeds;
@end

@implementation SZFakeKeystrokePoster

- (instancetype)init {
    self = [super init];
    if (self) {
        _posted = [NSMutableArray array];
        _deliverySucceeds = YES;
    }
    return self;
}

- (BOOL)postKeystroke:(SZKeystrokeSpec)keystroke
  toProcessIdentifier:(pid_t)processIdentifier {
    if (!self.deliverySucceeds || processIdentifier <= 0) {
        return NO;
    }
    [self.posted addObject:@{
        @"keyCode" : @(keystroke.keyCode),
        @"flags" : @(keystroke.modifierFlags),
        @"pid" : @(processIdentifier),
    }];
    return YES;
}

@end

@interface SZFakeZoomFeedback : NSObject <SZZoomFeedbackPresenting>
@property (nonatomic, strong) NSMutableArray<NSNumber *> *shownSteps;
@end

@implementation SZFakeZoomFeedback

- (instancetype)init {
    self = [super init];
    if (self) {
        _shownSteps = [NSMutableArray array];
    }
    return self;
}

- (void)showZoomSteps:(NSInteger)steps {
    [self.shownSteps addObject:@(steps)];
}

@end

#pragma mark - Tests

static const pid_t SZFakeXcodePid = 4242;

@interface SZZoomControllerTests : XCTestCase
@end

@implementation SZZoomControllerTests {
    SZFakeScrollMonitor *_monitor;
    SZFakeFocusInspector *_focus;
    SZFakeKeystrokePoster *_poster;
    SZFakeZoomFeedback *_feedback;
    SZZoomController *_controller;
}

- (void)setUp {
    [super setUp];
    _monitor = [[SZFakeScrollMonitor alloc] init];
    _focus = [[SZFakeFocusInspector alloc] init];
    _focus.bundleIdentifier = SZXcodeBundleIdentifier;
    _focus.focusedRole = @"AXTextArea";
    _focus.processIdentifier = SZFakeXcodePid;
    _poster = [[SZFakeKeystrokePoster alloc] init];
    _feedback = [[SZFakeZoomFeedback alloc] init];
    _controller = [[SZZoomController alloc] initWithMonitor:_monitor
                                             focusInspector:_focus
                                                interpreter:[[SZGestureInterpreter alloc] init]
                                                    matcher:[[SZTargetMatcher alloc] init]
                                                     mapper:[[SZActionMapper alloc] init]
                                                synthesizer:_poster
                                               levelTracker:[[SZZoomLevelTracker alloc] init]
                                                   feedback:_feedback];
    [_controller arm];
}

- (SZScrollSample)wheelSampleWithDelta:(double)deltaY timestamp:(NSTimeInterval)timestamp {
    return (SZScrollSample){.deltaY = deltaY,
                            .hasPreciseDeltas = NO,
                            .isMomentumPhase = NO,
                            .timestamp = timestamp};
}

- (void)testCommandScrollUpInXcodeEditorPostsZoomIn {
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];

    XCTAssertEqual(_poster.posted.count, 1u);
    NSDictionary *post = _poster.posted.firstObject;
    XCTAssertEqualObjects(post[@"keyCode"], @(SZKeyCodeEqual));
    XCTAssertEqualObjects(post[@"pid"], @(SZFakeXcodePid));
}

- (void)testCommandScrollDownInXcodeEditorPostsZoomOut {
    [_monitor sendSample:[self wheelSampleWithDelta:-3.0 timestamp:1.0] commandOnly:YES];

    XCTAssertEqual(_poster.posted.count, 1u);
    XCTAssertEqualObjects(_poster.posted.firstObject[@"keyCode"], @(SZKeyCodeMinus));
}

- (void)testFeedbackShowsRunningStepCount {
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.2] commandOnly:YES];
    [_monitor sendSample:[self wheelSampleWithDelta:-3.0 timestamp:1.4] commandOnly:YES];

    XCTAssertEqualObjects(_feedback.shownSteps, (@[ @1, @2, @1 ]));
}

- (void)testFeedbackNotShownForPassthroughEvents {
    _focus.bundleIdentifier = @"com.apple.Safari";
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.2] commandOnly:NO];

    XCTAssertEqual(_feedback.shownSteps.count, 0u);
}

- (void)testUndeliveredKeystrokeDoesNotCountAsAStep {
    // The target app quit between the bundle check and the post.
    _poster.deliverySucceeds = NO;
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];
    XCTAssertEqual(_feedback.shownSteps.count, 0u);

    _poster.deliverySucceeds = YES;
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.2] commandOnly:YES];
    // The failed step must not have advanced the count.
    XCTAssertEqualObjects(_feedback.shownSteps, (@[ @1 ]));
}

- (void)testResettingLevelTrackerClearsTheReportedCount {
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.2] commandOnly:YES];

    [_controller.levelTracker resetBundleIdentifier:SZXcodeBundleIdentifier];
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.4] commandOnly:YES];

    XCTAssertEqualObjects(_feedback.shownSteps, (@[ @1, @2, @1 ]));
}

- (void)testFeedbackNotShownWhenGestureIsThrottled {
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.00] commandOnly:YES];
    // Inside the throttle window: no keystroke, so no HUD update either.
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.01] commandOnly:YES];

    XCTAssertEqual(_poster.posted.count, 1u);
    XCTAssertEqual(_feedback.shownSteps.count, 1u);
}

- (void)testPlainScrollPassesThrough {
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:NO];
    XCTAssertEqual(_poster.posted.count, 0u);
}

- (void)testNonTargetAppPassesThroughWithoutFocusQuery {
    _focus.bundleIdentifier = @"com.apple.Safari";
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];

    XCTAssertEqual(_poster.posted.count, 0u);
    XCTAssertEqual(_focus.focusedRoleQueryCount, 0u);
}

- (void)testNonEditorFocusInXcodeStillZoomsWithoutFocusQuery {
    _focus.focusedRole = @"AXButton";
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];

    // The default Xcode rule is role-agnostic, so it acts on any focus and
    // never needs the AX focus round-trip.
    XCTAssertEqual(_poster.posted.count, 1u);
    XCTAssertEqual(_focus.focusedRoleQueryCount, 0u);
}

- (void)testRoleConstrainedRuleQueriesFocusAndPassesThroughOnMismatch {
    SZTargetRule *constrained =
        [SZTargetRule ruleWithBundleIdentifier:SZXcodeBundleIdentifier
                                   editorRoles:[NSSet setWithObject:@"AXTextArea"]];
    _controller.matcher = [[SZTargetMatcher alloc] initWithRules:@[ constrained ]];

    _focus.focusedRole = @"AXButton";
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];
    XCTAssertEqual(_poster.posted.count, 0u);
    XCTAssertEqual(_focus.focusedRoleQueryCount, 1u);

    _focus.focusedRole = @"AXTextArea";
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.1] commandOnly:YES];
    XCTAssertEqual(_poster.posted.count, 1u);
}

- (void)testDisabledControllerPassesThrough {
    _controller.enabled = NO;
    [_monitor sendSample:[self wheelSampleWithDelta:3.0 timestamp:1.0] commandOnly:YES];
    XCTAssertEqual(_poster.posted.count, 0u);
}

- (void)testInterruptedGestureDoesNotLeakAccumulation {
    SZScrollSample partial = {.deltaY = 14.0,
                              .hasPreciseDeltas = YES,
                              .isMomentumPhase = NO,
                              .timestamp = 1.0};
    [_monitor sendSample:partial commandOnly:YES];
    // ⌘ released mid-gesture: accumulation must reset...
    [_monitor sendSample:partial commandOnly:NO];
    // ...so the next ⌘ sample starts from zero and stays below threshold.
    partial.timestamp = 1.05;
    [_monitor sendSample:partial commandOnly:YES];

    XCTAssertEqual(_poster.posted.count, 0u);
}

- (void)testDisarmStopsMonitoring {
    XCTAssertTrue(_controller.isArmed);
    [_controller disarm];
    XCTAssertFalse(_controller.isArmed);
}

@end

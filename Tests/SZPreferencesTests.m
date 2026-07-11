#import <XCTest/XCTest.h>

#import "SZActionMapper.h"
#import "SZPreferences.h"

static NSString *const SZTestSuiteName = @"com.erykszczesniak.ScrollZoom.tests";

@interface SZPreferencesTests : XCTestCase
@end

@implementation SZPreferencesTests {
    NSUserDefaults *_defaults;
    SZPreferences *_preferences;
}

- (void)setUp {
    [super setUp];
    [[NSUserDefaults alloc] initWithSuiteName:SZTestSuiteName];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:SZTestSuiteName];
    _defaults = [[NSUserDefaults alloc] initWithSuiteName:SZTestSuiteName];
    _preferences = [[SZPreferences alloc] initWithUserDefaults:_defaults];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:SZTestSuiteName];
    [super tearDown];
}

- (void)testEnabledDefaultsToYesAndPersists {
    XCTAssertTrue(_preferences.isEnabled);
    _preferences.enabled = NO;
    XCTAssertFalse(_preferences.isEnabled);
}

- (void)testThresholdDefaultsAndPersists {
    XCTAssertEqualWithAccuracy(_preferences.preciseDeltaThreshold, 15.0, 0.001);
    _preferences.preciseDeltaThreshold = 8.0;
    XCTAssertEqualWithAccuracy(_preferences.preciseDeltaThreshold, 8.0, 0.001);
}

- (void)testDefaultRulesContainOnlyXcode {
    NSArray<SZTargetRule *> *rules = _preferences.configuredTargetRules;
    XCTAssertEqual(rules.count, 1u);
    XCTAssertEqualObjects(rules.firstObject.bundleIdentifier, SZXcodeBundleIdentifier);
}

- (void)testDisablingTargetRemovesItFromActiveRules {
    XCTAssertTrue([_preferences isTargetEnabled:SZXcodeBundleIdentifier]);
    [_preferences setTarget:SZXcodeBundleIdentifier enabled:NO];

    XCTAssertFalse([_preferences isTargetEnabled:SZXcodeBundleIdentifier]);
    XCTAssertEqual(_preferences.activeTargetRules.count, 0u);
    // Still listed for the menu.
    XCTAssertEqual(_preferences.configuredTargetRules.count, 1u);

    [_preferences setTarget:SZXcodeBundleIdentifier enabled:YES];
    XCTAssertEqual(_preferences.activeTargetRules.count, 1u);
}

- (void)testCustomTargetParsedFromDefaults {
    [_defaults setObject:@[
        @{@"bundleIdentifier" : @"com.example.editor",
          @"editorRoles" : @[ @"AXTextArea", @"AXWebArea" ]}
    ]
                  forKey:@"SZTargets"];

    NSArray<SZTargetRule *> *rules = _preferences.configuredTargetRules;
    XCTAssertEqual(rules.count, 1u);
    XCTAssertEqualObjects(rules.firstObject.bundleIdentifier, @"com.example.editor");
    XCTAssertTrue([rules.firstObject.editorRoles containsObject:@"AXWebArea"]);
    XCTAssertNil(rules.firstObject.mapper);
}

- (void)testCustomKeyMappingParsedFromDefaults {
    [_defaults setObject:@[
        @{@"bundleIdentifier" : @"com.example.editor",
          @"zoomInKeyCode" : @(SZKeyCodeEqual),
          @"zoomOutKeyCode" : @(SZKeyCodeMinus)}
    ]
                  forKey:@"SZTargets"];

    SZTargetRule *rule = _preferences.configuredTargetRules.firstObject;
    XCTAssertNotNil(rule.mapper);
    SZKeystrokeSpec keystroke;
    XCTAssertTrue([rule.mapper getKeystroke:&keystroke forIntent:SZZoomIntentIn]);
    XCTAssertEqual(keystroke.keyCode, SZKeyCodeEqual);
    XCTAssertEqual(keystroke.modifierFlags, (CGEventFlags)kCGEventFlagMaskCommand);
}

- (void)testMalformedTargetEntriesFallBackToXcode {
    [_defaults setObject:@[ @"garbage", @{@"editorRoles" : @[ @"AXTextArea" ]} ]
                  forKey:@"SZTargets"];

    NSArray<SZTargetRule *> *rules = _preferences.configuredTargetRules;
    XCTAssertEqual(rules.count, 1u);
    XCTAssertEqualObjects(rules.firstObject.bundleIdentifier, SZXcodeBundleIdentifier);
}

@end

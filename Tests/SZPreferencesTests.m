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

#pragma mark - Change notification

- (void)testMutationsPostChangeNotification {
    __block NSUInteger notificationCount = 0;
    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:SZPreferencesDidChangeNotification
                    object:_preferences
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    notificationCount += 1;
                }];

    _preferences.enabled = NO;
    _preferences.preciseDeltaThreshold = 8.0;
    [_preferences setTarget:SZXcodeBundleIdentifier enabled:NO];
    [_preferences addTargetWithBundleIdentifier:@"com.example.editor"];
    [_preferences removeTargetWithBundleIdentifier:@"com.example.editor"];

    XCTAssertEqual(notificationCount, 5u);
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testObserverSeesPostMutationStateAtNotificationTime {
    [_preferences addTargetWithBundleIdentifier:@"com.example.editor"];
    __block NSArray<NSString *> *capturedActive = nil;
    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:SZPreferencesDidChangeNotification
                    object:_preferences
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    SZPreferences *preferences = note.object;
                    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
                    for (SZTargetRule *rule in preferences.activeTargetRules) {
                        [identifiers addObject:rule.bundleIdentifier];
                    }
                    capturedActive = identifiers;
                }];

    // The pipeline rebuilds its matcher inside this notification — it must
    // never observe pre-mutation state.
    [_preferences removeTargetWithBundleIdentifier:@"com.example.editor"];
    XCTAssertNotNil(capturedActive);
    XCTAssertFalse([capturedActive containsObject:@"com.example.editor"]);
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

#pragma mark - Target mutations

- (void)testAddTargetAppendsRoleAgnosticRuleAndKeepsDefaults {
    XCTAssertTrue([_preferences addTargetWithBundleIdentifier:@"com.example.editor"]);

    NSArray<SZTargetRule *> *rules = _preferences.configuredTargetRules;
    XCTAssertEqual(rules.count, 2u);
    XCTAssertEqualObjects(rules[0].bundleIdentifier, SZXcodeBundleIdentifier);
    XCTAssertEqualObjects(rules[1].bundleIdentifier, @"com.example.editor");
    XCTAssertNil(rules[1].editorRoles);
}

- (void)testAddDuplicateTargetIsRejected {
    XCTAssertTrue([_preferences addTargetWithBundleIdentifier:@"com.example.editor"]);
    XCTAssertFalse([_preferences addTargetWithBundleIdentifier:@"com.example.editor"]);
    XCTAssertFalse([_preferences addTargetWithBundleIdentifier:SZXcodeBundleIdentifier]);
    XCTAssertEqual(_preferences.configuredTargetRules.count, 2u);
}

- (void)testRemoveTargetDeletesRuleAndClearsOptOut {
    [_preferences addTargetWithBundleIdentifier:@"com.example.editor"];
    [_preferences setTarget:@"com.example.editor" enabled:NO];

    XCTAssertTrue([_preferences removeTargetWithBundleIdentifier:@"com.example.editor"]);
    XCTAssertEqual(_preferences.configuredTargetRules.count, 1u);
    // Re-adding must come back enabled, not silently opted out.
    XCTAssertTrue([_preferences isTargetEnabled:@"com.example.editor"]);
}

- (void)testRemoveUnknownTargetIsRejected {
    XCTAssertFalse([_preferences removeTargetWithBundleIdentifier:@"com.example.editor"]);
}

- (void)testRemovingBuiltInDefaultLeavesDeliberatelyEmptyConfig {
    XCTAssertTrue([_preferences removeTargetWithBundleIdentifier:SZXcodeBundleIdentifier]);
    XCTAssertEqual(_preferences.configuredTargetRules.count, 0u);
    XCTAssertEqual(_preferences.activeTargetRules.count, 0u);
    // The empty list is persisted config, not a reset to defaults.
    XCTAssertNotNil([_defaults arrayForKey:@"SZTargets"]);
}

- (void)testAddAfterRemoveAllDoesNotResurrectDefaults {
    [_preferences removeTargetWithBundleIdentifier:SZXcodeBundleIdentifier];

    XCTAssertTrue([_preferences addTargetWithBundleIdentifier:@"com.example.editor"]);
    NSArray<SZTargetRule *> *rules = _preferences.configuredTargetRules;
    XCTAssertEqual(rules.count, 1u);
    XCTAssertEqualObjects(rules.firstObject.bundleIdentifier, @"com.example.editor");

    // The removed built-in is gone, not shadowing — re-adding must work.
    XCTAssertTrue([_preferences addTargetWithBundleIdentifier:SZXcodeBundleIdentifier]);
}

- (void)testAddOnAllMalformedConfigKeepsVisibleFallbackRule {
    [_defaults setObject:@[ @"garbage" ] forKey:@"SZTargets"];
    // The parsed view falls back to Xcode; an edit must not lose that rule.
    XCTAssertTrue([_preferences addTargetWithBundleIdentifier:@"com.example.editor"]);

    NSArray<SZTargetRule *> *rules = _preferences.configuredTargetRules;
    XCTAssertEqual(rules.count, 2u);
    XCTAssertEqualObjects(rules[0].bundleIdentifier, SZXcodeBundleIdentifier);
    XCTAssertEqualObjects(rules[1].bundleIdentifier, @"com.example.editor");
}

- (void)testRemoveWithMalformedEntriesDoesNotCrashAndDropsGarbage {
    [_defaults setObject:@[
        @"garbage", @{@"bundleIdentifier" : @"com.example.editor"}
    ]
                  forKey:@"SZTargets"];

    XCTAssertFalse([_preferences removeTargetWithBundleIdentifier:@"com.absent"]);
    XCTAssertTrue([_preferences removeTargetWithBundleIdentifier:@"com.example.editor"]);
    XCTAssertEqual(_preferences.configuredTargetRules.count, 0u);
}

- (void)testCustomKeyMappingSurvivesUnrelatedMutations {
    [_defaults setObject:@[
        @{@"bundleIdentifier" : @"com.example.editor",
          @"zoomInKeyCode" : @(SZKeyCodeEqual),
          @"zoomOutKeyCode" : @(SZKeyCodeMinus)}
    ]
                  forKey:@"SZTargets"];

    [_preferences addTargetWithBundleIdentifier:@"com.example.other"];

    SZTargetRule *custom = _preferences.configuredTargetRules.firstObject;
    XCTAssertEqualObjects(custom.bundleIdentifier, @"com.example.editor");
    XCTAssertNotNil(custom.mapper);
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

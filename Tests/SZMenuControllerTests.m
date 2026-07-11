#import <XCTest/XCTest.h>

#import "SZMenuController.h"

static NSString *const SZMenuTestSuiteName = @"com.erykszczesniak.ScrollZoom.menu-tests";

/// The menu reaches the live pipeline solely through SZPreferences mutations
/// (which post SZPreferencesDidChangeNotification) — these tests pin that
/// contract without installing a status item.
@interface SZMenuControllerTests : XCTestCase
@end

@implementation SZMenuControllerTests {
    NSUserDefaults *_defaults;
    SZPreferences *_preferences;
    SZMenuController *_menuController;
    NSUInteger _notificationCount;
    id _observer;
}

- (void)setUp {
    [super setUp];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:SZMenuTestSuiteName];
    _defaults = [[NSUserDefaults alloc] initWithSuiteName:SZMenuTestSuiteName];
    _preferences = [[SZPreferences alloc] initWithUserDefaults:_defaults];
    _menuController = [[SZMenuController alloc] initWithPreferences:_preferences];

    _notificationCount = 0;
    __weak typeof(self) weakSelf = self;
    _observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:SZPreferencesDidChangeNotification
                    object:_preferences
                     queue:nil
                usingBlock:^(NSNotification *note) {
                    [weakSelf countNotification];
                }];
}

- (void)countNotification {
    _notificationCount += 1;
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:SZMenuTestSuiteName];
    [super tearDown];
}

- (NSMenuItem *)itemRepresenting:(id)representedObject {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    item.representedObject = representedObject;
    return item;
}

- (void)testToggleEnabledWritesThroughPreferencesAndNotifies {
    XCTAssertTrue(_preferences.isEnabled);
    [_menuController performSelector:@selector(toggleEnabled:) withObject:nil];

    XCTAssertFalse(_preferences.isEnabled);
    XCTAssertEqual(_notificationCount, 1u);
}

- (void)testSelectSensitivityWritesThresholdAndNotifies {
    [_menuController performSelector:@selector(selectSensitivity:)
                          withObject:[self itemRepresenting:@8.0]];

    XCTAssertEqualWithAccuracy(_preferences.preciseDeltaThreshold, 8.0, 0.001);
    XCTAssertEqual(_notificationCount, 1u);
}

- (void)testToggleTargetOptsOutAndNotifies {
    [_menuController performSelector:@selector(toggleTarget:)
                          withObject:[self itemRepresenting:SZXcodeBundleIdentifier]];

    XCTAssertFalse([_preferences isTargetEnabled:SZXcodeBundleIdentifier]);
    XCTAssertEqual(_preferences.activeTargetRules.count, 0u);
    XCTAssertEqual(_notificationCount, 1u);
}

@end

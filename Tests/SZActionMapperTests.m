#import <XCTest/XCTest.h>

#import "SZActionMapper.h"

@interface SZActionMapperTests : XCTestCase
@end

@implementation SZActionMapperTests

- (void)testDefaultMappingZoomInIsCommandEqual {
    SZActionMapper *mapper = [[SZActionMapper alloc] init];
    SZKeystrokeSpec keystroke;
    XCTAssertTrue([mapper getKeystroke:&keystroke forIntent:SZZoomIntentIn]);
    XCTAssertTrue(SZKeystrokeSpecEqual(
        keystroke, SZKeystrokeSpecMake(SZKeyCodeEqual, kCGEventFlagMaskCommand)));
}

- (void)testDefaultMappingZoomOutIsCommandMinus {
    SZActionMapper *mapper = [[SZActionMapper alloc] init];
    SZKeystrokeSpec keystroke;
    XCTAssertTrue([mapper getKeystroke:&keystroke forIntent:SZZoomIntentOut]);
    XCTAssertTrue(SZKeystrokeSpecEqual(
        keystroke, SZKeystrokeSpecMake(SZKeyCodeMinus, kCGEventFlagMaskCommand)));
}

- (void)testNoneIntentYieldsNoKeystroke {
    SZActionMapper *mapper = [[SZActionMapper alloc] init];
    SZKeystrokeSpec keystroke;
    XCTAssertFalse([mapper getKeystroke:&keystroke forIntent:SZZoomIntentNone]);
}

- (void)testCustomMappingIsHonored {
    SZKeystrokeSpec customIn = SZKeystrokeSpecMake(SZKeyCodeEqual,
                                                   kCGEventFlagMaskCommand | kCGEventFlagMaskShift);
    SZKeystrokeSpec customOut = SZKeystrokeSpecMake(SZKeyCodeMinus,
                                                    kCGEventFlagMaskCommand | kCGEventFlagMaskShift);
    SZActionMapper *mapper = [[SZActionMapper alloc] initWithZoomInKeystroke:customIn
                                                            zoomOutKeystroke:customOut];
    SZKeystrokeSpec keystroke;
    XCTAssertTrue([mapper getKeystroke:&keystroke forIntent:SZZoomIntentIn]);
    XCTAssertTrue(SZKeystrokeSpecEqual(keystroke, customIn));
}

@end

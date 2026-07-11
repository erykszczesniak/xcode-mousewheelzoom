#import <XCTest/XCTest.h>

#import "SZTargetMatcher.h"

@interface SZTargetMatcherTests : XCTestCase
@end

@implementation SZTargetMatcherTests {
    SZTargetMatcher *_matcher;
}

- (void)setUp {
    [super setUp];
    _matcher = [[SZTargetMatcher alloc] init];
}

- (void)testXcodeWithTextAreaFocusMatches {
    SZTargetRule *rule = [_matcher ruleMatchingBundleIdentifier:SZXcodeBundleIdentifier
                                                    focusedRole:@"AXTextArea"];
    XCTAssertNotNil(rule);
    XCTAssertEqualObjects(rule.bundleIdentifier, SZXcodeBundleIdentifier);
}

- (void)testXcodeWithNonEditorFocusStillMatches {
    XCTAssertNotNil([_matcher ruleMatchingBundleIdentifier:SZXcodeBundleIdentifier
                                               focusedRole:@"AXButton"]);
}

- (void)testXcodeWithUnknownFocusStillMatches {
    XCTAssertNotNil([_matcher ruleMatchingBundleIdentifier:SZXcodeBundleIdentifier
                                               focusedRole:nil]);
}

- (void)testRoleConstrainedRuleRequiresMatchingFocus {
    SZTargetRule *constrained =
        [SZTargetRule ruleWithBundleIdentifier:@"com.example.editor"
                                   editorRoles:[NSSet setWithObject:@"AXTextArea"]];
    SZTargetMatcher *matcher = [[SZTargetMatcher alloc] initWithRules:@[ constrained ]];

    XCTAssertNotNil([matcher ruleMatchingBundleIdentifier:@"com.example.editor"
                                              focusedRole:@"AXTextArea"]);
    XCTAssertNil([matcher ruleMatchingBundleIdentifier:@"com.example.editor"
                                           focusedRole:@"AXButton"]);
    XCTAssertNil([matcher ruleMatchingBundleIdentifier:@"com.example.editor"
                                           focusedRole:nil]);
}

- (void)testOtherAppIsPassthrough {
    XCTAssertNil([_matcher ruleMatchingBundleIdentifier:@"com.apple.Safari"
                                            focusedRole:@"AXTextArea"]);
}

- (void)testNilBundleIdentifierIsPassthrough {
    XCTAssertNil([_matcher ruleMatchingBundleIdentifier:nil focusedRole:@"AXTextArea"]);
}

- (void)testRuleWithoutRoleConstraintMatchesAnyFocus {
    SZTargetRule *anyFocus = [SZTargetRule ruleWithBundleIdentifier:@"com.example.editor"
                                                        editorRoles:nil];
    SZTargetMatcher *matcher = [[SZTargetMatcher alloc] initWithRules:@[ anyFocus ]];
    XCTAssertNotNil([matcher ruleMatchingBundleIdentifier:@"com.example.editor"
                                              focusedRole:nil]);
}

- (void)testFirstMatchingRuleWins {
    SZTargetRule *narrow = [SZTargetRule ruleWithBundleIdentifier:@"com.example.editor"
                                                      editorRoles:[NSSet setWithObject:@"AXTextArea"]];
    SZTargetRule *broad = [SZTargetRule ruleWithBundleIdentifier:@"com.example.editor"
                                                     editorRoles:nil];
    SZTargetMatcher *matcher = [[SZTargetMatcher alloc] initWithRules:@[ narrow, broad ]];

    SZTargetRule *matched = [matcher ruleMatchingBundleIdentifier:@"com.example.editor"
                                                      focusedRole:@"AXTextArea"];
    XCTAssertEqual(matched, narrow);
}

@end

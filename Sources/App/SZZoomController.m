#import "SZZoomController.h"

@interface SZZoomController ()

@property (nonatomic, strong) id<SZScrollEventMonitoring> monitor;
@property (nonatomic, strong) id<SZFocusInspecting> focusInspector;
@property (nonatomic, strong) SZGestureInterpreter *interpreter;
@property (nonatomic, strong) SZTargetMatcher *matcher;
@property (nonatomic, strong) SZActionMapper *mapper;
@property (nonatomic, strong) id<SZKeystrokePosting> synthesizer;

@end

@implementation SZZoomController

- (instancetype)initWithMonitor:(id<SZScrollEventMonitoring>)monitor
                 focusInspector:(id<SZFocusInspecting>)focusInspector
                    interpreter:(SZGestureInterpreter *)interpreter
                        matcher:(SZTargetMatcher *)matcher
                         mapper:(SZActionMapper *)mapper
                    synthesizer:(id<SZKeystrokePosting>)synthesizer {
    self = [super init];
    if (self) {
        _monitor = monitor;
        _focusInspector = focusInspector;
        _interpreter = interpreter;
        _matcher = matcher;
        _mapper = mapper;
        _synthesizer = synthesizer;
        _enabled = YES;
    }
    return self;
}

- (BOOL)isArmed {
    return self.monitor.isMonitoring;
}

- (void)arm {
    __weak typeof(self) weakSelf = self;
    [self.monitor startWithHandler:^(SZScrollSample sample, BOOL commandOnly) {
        [weakSelf handleScrollSample:sample commandOnly:commandOnly];
    }];
}

- (void)disarm {
    [self.monitor stop];
    [self.interpreter reset];
}

#pragma mark - Pipeline

- (void)handleScrollSample:(SZScrollSample)sample commandOnly:(BOOL)commandOnly {
    if (!self.enabled || !commandOnly) {
        [self.interpreter reset];
        return;
    }

    // Cheap bundle check first; the AX focus round-trip only happens for
    // apps that a rule actually mentions.
    NSString *bundleIdentifier = [self.focusInspector frontmostApplicationBundleIdentifier];
    if (![self.matcher hasRuleForBundleIdentifier:bundleIdentifier]) {
        [self.interpreter reset];
        return;
    }

    NSString *focusedRole = [self.focusInspector focusedElementRole];
    SZTargetRule *rule = [self.matcher ruleMatchingBundleIdentifier:bundleIdentifier
                                                        focusedRole:focusedRole];
    if (rule == nil) {
        [self.interpreter reset];
        return;
    }

    SZKeystrokeSpec keystroke;
    if (![self.mapper getKeystroke:&keystroke
                         forIntent:[self.interpreter intentForSample:sample]]) {
        return;
    }

    [self.synthesizer postKeystroke:keystroke
                toProcessIdentifier:[self.focusInspector frontmostApplicationProcessIdentifier]];
}

@end

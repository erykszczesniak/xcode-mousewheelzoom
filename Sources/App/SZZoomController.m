#import "SZZoomController.h"

@interface SZZoomController ()

@property (nonatomic, strong) id<SZScrollEventMonitoring> monitor;
@property (nonatomic, strong) id<SZFocusInspecting> focusInspector;
@property (nonatomic, strong, readwrite) SZGestureInterpreter *interpreter;
@property (nonatomic, strong) SZActionMapper *mapper;
@property (nonatomic, strong) id<SZKeystrokePosting> synthesizer;
@property (nonatomic, strong, readwrite) SZZoomLevelTracker *levelTracker;
@property (nonatomic, strong, nullable) id<SZZoomFeedbackPresenting> feedback;

@end

@implementation SZZoomController

- (instancetype)initWithMonitor:(id<SZScrollEventMonitoring>)monitor
                 focusInspector:(id<SZFocusInspecting>)focusInspector
                    interpreter:(SZGestureInterpreter *)interpreter
                        matcher:(SZTargetMatcher *)matcher
                         mapper:(SZActionMapper *)mapper
                    synthesizer:(id<SZKeystrokePosting>)synthesizer
                   levelTracker:(SZZoomLevelTracker *)levelTracker
                       feedback:(id<SZZoomFeedbackPresenting>)feedback {
    self = [super init];
    if (self) {
        _monitor = monitor;
        _focusInspector = focusInspector;
        _interpreter = interpreter;
        _matcher = matcher;
        _mapper = mapper;
        _synthesizer = synthesizer;
        _levelTracker = levelTracker;
        _feedback = feedback;
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

    // Try role-agnostic rules first; the focused-element round-trip only
    // happens when a rule actually constrains the editor role.
    SZTargetRule *rule = [self.matcher ruleMatchingBundleIdentifier:bundleIdentifier
                                                        focusedRole:nil];
    if (rule == nil) {
        NSString *focusedRole = [self.focusInspector focusedElementRole];
        rule = [self.matcher ruleMatchingBundleIdentifier:bundleIdentifier
                                              focusedRole:focusedRole];
    }
    if (rule == nil) {
        [self.interpreter reset];
        return;
    }

    SZZoomIntent intent = [self.interpreter intentForSample:sample];
    SZActionMapper *mapper = rule.mapper ?: self.mapper;
    SZKeystrokeSpec keystroke;
    if (![mapper getKeystroke:&keystroke forIntent:intent]) {
        return;
    }

    pid_t pid = [self.focusInspector frontmostApplicationProcessIdentifier];
    if (![self.synthesizer postKeystroke:keystroke toProcessIdentifier:pid]) {
        // The app vanished mid-gesture: never count a step that never landed.
        return;
    }

    NSInteger steps = [self.levelTracker applyIntent:intent
                                 forBundleIdentifier:bundleIdentifier];
    [self.feedback showZoomSteps:steps];
}

@end

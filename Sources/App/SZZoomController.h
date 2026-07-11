#import <Foundation/Foundation.h>

#import "SZAccessibility.h"
#import "SZActionMapper.h"
#import "SZEventTap.h"
#import "SZGestureInterpreter.h"
#import "SZKeystrokeSynthesizer.h"
#import "SZTargetMatcher.h"
#import "SZZoomHUD.h"
#import "SZZoomLevelTracker.h"

NS_ASSUME_NONNULL_BEGIN

/// Ties the pipeline together: scroll monitor → gesture interpreter →
/// target matcher → action mapper → keystroke synthesizer, with on-screen
/// feedback. Every dependency is a protocol or a pure object, so the whole
/// flow is testable with fakes.
@interface SZZoomController : NSObject

- (instancetype)initWithMonitor:(id<SZScrollEventMonitoring>)monitor
                 focusInspector:(id<SZFocusInspecting>)focusInspector
                    interpreter:(SZGestureInterpreter *)interpreter
                        matcher:(SZTargetMatcher *)matcher
                         mapper:(SZActionMapper *)mapper
                    synthesizer:(id<SZKeystrokePosting>)synthesizer
                   levelTracker:(SZZoomLevelTracker *)levelTracker
                       feedback:(nullable id<SZZoomFeedbackPresenting>)feedback
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Master switch, flipped from the menu. Defaults to YES. While NO the
/// monitor stays attached but every event passes through untouched.
@property (nonatomic, getter=isEnabled) BOOL enabled;

/// Whether the scroll monitor is currently attached.
@property (nonatomic, readonly, getter=isArmed) BOOL armed;

/// Swappable at runtime so configuration changes take effect immediately.
@property (nonatomic, strong) SZTargetMatcher *matcher;

/// Exposed for runtime sensitivity tuning.
@property (nonatomic, strong, readonly) SZGestureInterpreter *interpreter;

/// Exposed so the app can forget an app's accumulated steps when the count
/// stops reflecting reality (target removed, app quit and relaunched).
@property (nonatomic, strong, readonly) SZZoomLevelTracker *levelTracker;

/// Attaches the scroll monitor. Call only after Accessibility is granted.
- (void)arm;

/// Detaches the scroll monitor.
- (void)disarm;

@end

NS_ASSUME_NONNULL_END

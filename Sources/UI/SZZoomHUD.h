#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Seam over the on-screen feedback so the pipeline can be tested without a
/// window server.
@protocol SZZoomFeedbackPresenting <NSObject>

/// Shows the current zoom step count (positive = zoomed in) and starts the
/// dismiss countdown. Calling again while visible refreshes both.
- (void)showZoomSteps:(NSInteger)steps;

@end

/// System-HUD-style overlay: a rounded, blurred panel that fades in on the
/// first zoom step, follows further steps, and fades out shortly after the
/// gesture stops. Non-activating and click-through — it never steals focus
/// from the app being zoomed.
@interface SZZoomHUD : NSObject <SZZoomFeedbackPresenting>
@end

NS_ASSUME_NONNULL_END

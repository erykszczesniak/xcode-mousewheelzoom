#import <Foundation/Foundation.h>

#import "SZZoomIntent.h"

NS_ASSUME_NONNULL_BEGIN

/// Counts zoom steps per target app so the HUD can show how far the user has
/// zoomed in this session. Pure bookkeeping — the real font size lives in the
/// target app and is not readable, so this is relative to where the app was
/// when ScrollZoom first acted on it.
@interface SZZoomLevelTracker : NSObject

/// Applies `intent` to `bundleIdentifier` and returns the new step count
/// (positive = zoomed in, negative = out). `SZZoomIntentNone` is a no-op.
- (NSInteger)applyIntent:(SZZoomIntent)intent
     forBundleIdentifier:(NSString *)bundleIdentifier;

/// Current step count for an app; 0 if untouched.
- (NSInteger)stepsForBundleIdentifier:(NSString *)bundleIdentifier;

/// Forgets an app's accumulated steps (e.g. the user reset the font size in
/// the app itself, so ScrollZoom's count is meaningless).
- (void)resetBundleIdentifier:(NSString *)bundleIdentifier;

@end

NS_ASSUME_NONNULL_END

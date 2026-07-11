#import <Cocoa/Cocoa.h>

#import "SZScrollSample.h"

NS_ASSUME_NONNULL_BEGIN

/// Called for every global scroll-wheel event while monitoring is active.
/// `commandOnly` is YES when ⌘ was the only primary modifier held.
typedef void (^SZScrollEventHandler)(SZScrollSample sample, BOOL commandOnly);

/// Seam over global scroll monitoring so the pipeline can be driven by fake
/// events in tests.
@protocol SZScrollEventMonitoring <NSObject>

@property (nonatomic, readonly, getter=isMonitoring) BOOL monitoring;

/// Starts delivering scroll events to `handler`. No-op if already started.
- (void)startWithHandler:(SZScrollEventHandler)handler;

/// Stops monitoring. No-op if not started.
- (void)stop;

@end

/// Global scroll observer built on `+[NSEvent
/// addGlobalMonitorForEventsMatchingMask:handler:]`. Observation only — a
/// global monitor cannot consume events, so scrolling always reaches the
/// frontmost app untouched. Requires Accessibility trust to see events at
/// all, which is why arming is gated on the permission.
@interface SZEventTap : NSObject <SZScrollEventMonitoring>
@end

NS_ASSUME_NONNULL_END

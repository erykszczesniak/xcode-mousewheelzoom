#import "SZEventTap.h"

#import "NSEvent+SZModifiers.h"

@interface SZEventTap ()

/// Opaque token returned by NSEvent's monitor API; non-nil while active.
@property (nonatomic, strong, nullable) id monitorToken;

@end

@implementation SZEventTap

- (void)dealloc {
    [self stop];
}

- (BOOL)isMonitoring {
    return self.monitorToken != nil;
}

- (void)startWithHandler:(SZScrollEventHandler)handler {
    if (self.monitorToken != nil) {
        return;
    }

    self.monitorToken = [NSEvent
        addGlobalMonitorForEventsMatchingMask:NSEventMaskScrollWheel
                                      handler:^(NSEvent *event) {
                                          handler(event.sz_scrollSample,
                                                  event.sz_hasCommandOnlyModifier);
                                      }];
}

- (void)stop {
    if (self.monitorToken == nil) {
        return;
    }
    [NSEvent removeMonitor:self.monitorToken];
    self.monitorToken = nil;
}

@end

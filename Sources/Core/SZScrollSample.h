#ifndef SZScrollSample_h
#define SZScrollSample_h

#import <Foundation/Foundation.h>

/// One observed scroll-wheel sample, reduced to the fields the core layer
/// consumes. Decoupled from NSEvent so the gesture interpreter stays pure
/// and testable.
typedef struct SZScrollSample {
    /// Vertical scroll amount. Line-based for wheels, pixel-based when
    /// `hasPreciseDeltas` is set (trackpads, Magic Mouse).
    double deltaY;
    /// YES for continuous-delta devices (trackpad, Magic Mouse).
    BOOL hasPreciseDeltas;
    /// YES during the inertial tail after the fingers have lifted.
    BOOL isMomentumPhase;
    /// Event timestamp in seconds since boot.
    NSTimeInterval timestamp;
} SZScrollSample;

#endif /* SZScrollSample_h */

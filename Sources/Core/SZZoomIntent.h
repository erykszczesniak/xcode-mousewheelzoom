#ifndef SZZoomIntent_h
#define SZZoomIntent_h

#import <Foundation/Foundation.h>

/// What the user asked for with a single zoom gesture step.
typedef NS_ENUM(NSInteger, SZZoomIntent) {
    /// Nothing to do (sample below threshold, throttled, or momentum tail).
    SZZoomIntentNone = 0,
    /// Grow the font one step (scroll up).
    SZZoomIntentIn,
    /// Shrink the font one step (scroll down).
    SZZoomIntentOut,
};

#endif /* SZZoomIntent_h */

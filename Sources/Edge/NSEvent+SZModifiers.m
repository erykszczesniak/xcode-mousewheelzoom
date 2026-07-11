#import "NSEvent+SZModifiers.h"

@implementation NSEvent (SZModifiers)

- (BOOL)sz_hasCommandOnlyModifier {
    NSEventModifierFlags primaryFlags = self.modifierFlags &
        (NSEventModifierFlagCommand | NSEventModifierFlagShift |
         NSEventModifierFlagOption | NSEventModifierFlagControl);
    return primaryFlags == NSEventModifierFlagCommand;
}

- (SZScrollSample)sz_scrollSample {
    SZScrollSample sample;
    sample.deltaY = self.scrollingDeltaY;
    sample.hasPreciseDeltas = self.hasPreciseScrollingDeltas;
    sample.isMomentumPhase = (self.momentumPhase != NSEventPhaseNone);
    sample.timestamp = self.timestamp;
    return sample;
}

@end

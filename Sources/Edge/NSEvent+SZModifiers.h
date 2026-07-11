#import <Cocoa/Cocoa.h>

#import "SZScrollSample.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSEvent (SZModifiers)

/// YES when ⌘ is held without ⇧, ⌥ or ⌃ — the ScrollZoom trigger chord.
/// Chords with extra modifiers are left alone so app shortcuts keep working.
@property (nonatomic, readonly) BOOL sz_hasCommandOnlyModifier;

/// This scroll event reduced to the fields the core layer consumes.
@property (nonatomic, readonly) SZScrollSample sz_scrollSample;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

#import "SZKeystrokeSpec.h"
#import "SZZoomIntent.h"

NS_ASSUME_NONNULL_BEGIN

/// Maps a zoom intent to the shortcut the target app understands. Kept as
/// data so per-app mappings can come from configuration.
@interface SZActionMapper : NSObject

@property (nonatomic, readonly) SZKeystrokeSpec zoomInKeystroke;
@property (nonatomic, readonly) SZKeystrokeSpec zoomOutKeystroke;

- (instancetype)initWithZoomInKeystroke:(SZKeystrokeSpec)zoomInKeystroke
                       zoomOutKeystroke:(SZKeystrokeSpec)zoomOutKeystroke
    NS_DESIGNATED_INITIALIZER;

/// Default mapping used by Xcode (and most editors): ⌘= grows, ⌘- shrinks.
- (instancetype)init;

/// Fills `outKeystroke` for an actionable intent and returns YES; returns
/// NO for `SZZoomIntentNone`.
- (BOOL)getKeystroke:(SZKeystrokeSpec *)outKeystroke forIntent:(SZZoomIntent)intent;

@end

NS_ASSUME_NONNULL_END

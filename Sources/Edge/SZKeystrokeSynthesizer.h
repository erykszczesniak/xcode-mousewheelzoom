#import <Foundation/Foundation.h>

#import "SZKeystrokeSpec.h"

NS_ASSUME_NONNULL_BEGIN

/// Seam over keystroke posting so the pipeline can be tested without
/// emitting real events.
@protocol SZKeystrokePosting <NSObject>

/// Posts a key-down/key-up pair for `keystroke` to one process only.
- (void)postKeystroke:(SZKeystrokeSpec)keystroke
  toProcessIdentifier:(pid_t)processIdentifier;

@end

/// Synthesizes shortcuts with CGEvent. Events are posted with
/// `CGEventPostToPid`, never system-wide, so a zoom step can only ever reach
/// the app that was frontmost when the gesture happened.
@interface SZKeystrokeSynthesizer : NSObject <SZKeystrokePosting>
@end

NS_ASSUME_NONNULL_END

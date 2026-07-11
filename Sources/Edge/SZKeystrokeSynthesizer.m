#import "SZKeystrokeSynthesizer.h"

@implementation SZKeystrokeSynthesizer

- (BOOL)postKeystroke:(SZKeystrokeSpec)keystroke
  toProcessIdentifier:(pid_t)processIdentifier {
    if (processIdentifier <= 0) {
        return NO;
    }

    CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, keystroke.keyCode, true);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, keystroke.keyCode, false);
    if (keyDown == NULL || keyUp == NULL) {
        if (keyDown) CFRelease(keyDown);
        if (keyUp) CFRelease(keyUp);
        return NO;
    }

    CGEventSetFlags(keyDown, keystroke.modifierFlags);
    CGEventSetFlags(keyUp, keystroke.modifierFlags);

    CGEventPostToPid(processIdentifier, keyDown);
    CGEventPostToPid(processIdentifier, keyUp);

    CFRelease(keyDown);
    CFRelease(keyUp);
    return YES;
}

@end

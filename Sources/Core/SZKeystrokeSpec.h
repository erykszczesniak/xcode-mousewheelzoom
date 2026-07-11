#ifndef SZKeystrokeSpec_h
#define SZKeystrokeSpec_h

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

/// Virtual key codes ScrollZoom cares about (values from Carbon's
/// HIToolbox, redeclared so the core layer needs no Carbon import).
typedef NS_ENUM(CGKeyCode, SZKeyCode) {
    /// The `=` / `+` key on ANSI layouts.
    SZKeyCodeEqual = 0x18,
    /// The `-` / `_` key on ANSI layouts.
    SZKeyCodeMinus = 0x1B,
};

/// One synthesized shortcut: a virtual key plus modifier flags.
typedef struct SZKeystrokeSpec {
    CGKeyCode keyCode;
    CGEventFlags modifierFlags;
} SZKeystrokeSpec;

static inline SZKeystrokeSpec SZKeystrokeSpecMake(CGKeyCode keyCode, CGEventFlags modifierFlags) {
    return (SZKeystrokeSpec){.keyCode = keyCode, .modifierFlags = modifierFlags};
}

static inline BOOL SZKeystrokeSpecEqual(SZKeystrokeSpec a, SZKeystrokeSpec b) {
    return a.keyCode == b.keyCode && a.modifierFlags == b.modifierFlags;
}

#endif /* SZKeystrokeSpec_h */

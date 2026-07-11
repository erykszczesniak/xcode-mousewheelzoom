#import "SZAccessibility.h"

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

static NSString *const SZAccessibilitySettingsURLString =
    @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";

@implementation SZAccessibility

- (BOOL)isProcessTrusted {
    return AXIsProcessTrusted();
}

- (BOOL)checkTrustPrompting:(BOOL)shouldPrompt {
    NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt : @(shouldPrompt)};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

- (void)openAccessibilitySettings {
    NSURL *settingsURL = [NSURL URLWithString:SZAccessibilitySettingsURLString];
    [[NSWorkspace sharedWorkspace] openURL:settingsURL];
}

@end

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

#pragma mark - SZFocusInspecting

- (NSString *)frontmostApplicationBundleIdentifier {
    return [NSWorkspace sharedWorkspace].frontmostApplication.bundleIdentifier;
}

- (pid_t)frontmostApplicationProcessIdentifier {
    NSRunningApplication *frontmost = [NSWorkspace sharedWorkspace].frontmostApplication;
    return frontmost ? frontmost.processIdentifier : -1;
}

- (NSString *)focusedElementRole {
    AXUIElementRef systemWide = AXUIElementCreateSystemWide();
    CFTypeRef focused = NULL;
    AXError error = AXUIElementCopyAttributeValue(systemWide,
                                                  kAXFocusedUIElementAttribute,
                                                  &focused);
    CFRelease(systemWide);
    if (error != kAXErrorSuccess || focused == NULL) {
        return nil;
    }

    CFTypeRef role = NULL;
    error = AXUIElementCopyAttributeValue((AXUIElementRef)focused, kAXRoleAttribute, &role);
    CFRelease(focused);
    if (error != kAXErrorSuccess || role == NULL) {
        return nil;
    }
    return CFBridgingRelease(role);
}

#pragma mark - Settings deep link

- (void)openAccessibilitySettings {
    NSURL *settingsURL = [NSURL URLWithString:SZAccessibilitySettingsURLString];
    [[NSWorkspace sharedWorkspace] openURL:settingsURL];
}

@end

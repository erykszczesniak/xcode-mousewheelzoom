#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Seam over the Accessibility trust API so higher layers can be exercised
/// without talking to the real AX server.
@protocol SZAccessibilityTrustChecking <NSObject>

/// Whether the process is currently trusted for Accessibility.
@property (nonatomic, readonly, getter=isProcessTrusted) BOOL processTrusted;

/// Re-checks trust, optionally asking the system to show its grant dialog.
- (BOOL)checkTrustPrompting:(BOOL)shouldPrompt;

@end

/// Seam over "what is the user looking at right now" — frontmost app and
/// focused element role — so the pipeline can be tested with canned values.
@protocol SZFocusInspecting <NSObject>

/// Bundle identifier of the frontmost app, or nil if none.
- (nullable NSString *)frontmostApplicationBundleIdentifier;

/// Process identifier of the frontmost app, or -1 if none. Keystrokes are
/// posted to this pid so they cannot land in a different app mid-gesture.
- (pid_t)frontmostApplicationProcessIdentifier;

/// AX role of the system-wide focused element (e.g. `AXTextArea`), or nil
/// when it cannot be determined.
- (nullable NSString *)focusedElementRole;

@end

/// Thin edge wrapper over the Accessibility C API and NSWorkspace.
/// No logic beyond the API calls — keep this layer boring.
@interface SZAccessibility : NSObject <SZAccessibilityTrustChecking, SZFocusInspecting>

/// Opens System Settings at the Privacy & Security → Accessibility pane.
- (void)openAccessibilitySettings;

@end

NS_ASSUME_NONNULL_END

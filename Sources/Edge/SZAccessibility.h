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

/// Thin edge wrapper over AXIsProcessTrusted / AXIsProcessTrustedWithOptions.
/// No logic beyond the API call — keep this layer boring.
@interface SZAccessibility : NSObject <SZAccessibilityTrustChecking>

/// Opens System Settings at the Privacy & Security → Accessibility pane.
- (void)openAccessibilitySettings;

@end

NS_ASSUME_NONNULL_END

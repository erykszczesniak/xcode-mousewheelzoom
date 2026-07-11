#import "SZPermissionGate.h"

#import <AppKit/AppKit.h>

static const NSTimeInterval SZPermissionPollInterval = 1.0;

@interface SZPermissionGate ()

@property (nonatomic, strong) id<SZAccessibilityTrustChecking> trustChecker;
@property (nonatomic, strong, nullable) NSTimer *pollTimer;
@property (nonatomic, copy, nullable) void (^grantedHandler)(void);

@end

@implementation SZPermissionGate

- (instancetype)initWithTrustChecker:(id<SZAccessibilityTrustChecking>)trustChecker {
    self = [super init];
    if (self) {
        _trustChecker = trustChecker;
    }
    return self;
}

- (BOOL)isTrusted {
    return self.trustChecker.isProcessTrusted;
}

- (void)runWithGrantedHandler:(void (^)(void))grantedHandler {
    if (self.trustChecker.isProcessTrusted) {
        dispatch_async(dispatch_get_main_queue(), grantedHandler);
        return;
    }

    self.grantedHandler = grantedHandler;
    [self showExplainer];
    [self.trustChecker checkTrustPrompting:YES];
    [self startPolling];
}

#pragma mark - First-run explainer

- (void)showExplainer {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = @"ScrollZoom needs Accessibility access";
    alert.informativeText = @"ScrollZoom watches for ⌘ + scroll and sends the matching "
                            @"font-size shortcut to Xcode. macOS requires Accessibility "
                            @"permission for both.\n\nGrant access in System Settings → "
                            @"Privacy & Security → Accessibility. ScrollZoom stays inactive "
                            @"until then.";
    [alert addButtonWithTitle:@"Continue"];
    [alert runModal];
}

#pragma mark - Polling

- (void)startPolling {
    self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:SZPermissionPollInterval
                                                      target:self
                                                    selector:@selector(pollTrustState:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)pollTrustState:(NSTimer *)timer {
    if (!self.trustChecker.isProcessTrusted) {
        return;
    }

    [self.pollTimer invalidate];
    self.pollTimer = nil;

    void (^handler)(void) = self.grantedHandler;
    self.grantedHandler = nil;
    if (handler) {
        handler();
    }
}

@end

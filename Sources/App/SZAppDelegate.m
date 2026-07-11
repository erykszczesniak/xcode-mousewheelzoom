#import "SZAppDelegate.h"

#import "SZAccessibility.h"
#import "SZMenuController.h"
#import "SZPermissionGate.h"
#import "SZZoomController.h"

@interface SZAppDelegate ()

@property (nonatomic, strong) SZMenuController *menuController;
@property (nonatomic, strong) SZAccessibility *accessibility;
@property (nonatomic, strong) SZPermissionGate *permissionGate;
@property (nonatomic, strong) SZZoomController *zoomController;

@end

@implementation SZAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.menuController = [[SZMenuController alloc] init];
    [self.menuController install];

    self.accessibility = [[SZAccessibility alloc] init];
    self.permissionGate = [[SZPermissionGate alloc] initWithTrustChecker:self.accessibility];

    [self.menuController updatePermissionStatus:self.permissionGate.isTrusted];

    __weak typeof(self) weakSelf = self;
    [self.permissionGate runWithGrantedHandler:^{
        [weakSelf armEventPipeline];
    }];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)application {
    return YES;
}

#pragma mark - Arming

- (void)armEventPipeline {
    if (self.zoomController == nil) {
        self.zoomController =
            [[SZZoomController alloc] initWithMonitor:[[SZEventTap alloc] init]
                                       focusInspector:self.accessibility
                                          interpreter:[[SZGestureInterpreter alloc] init]
                                              matcher:[[SZTargetMatcher alloc] init]
                                               mapper:[[SZActionMapper alloc] init]
                                          synthesizer:[[SZKeystrokeSynthesizer alloc] init]];
    }
    [self.zoomController arm];
    [self.menuController updatePermissionStatus:YES];
}

@end

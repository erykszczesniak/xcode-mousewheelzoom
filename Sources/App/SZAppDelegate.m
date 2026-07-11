#import "SZAppDelegate.h"

#import "SZAccessibility.h"
#import "SZMenuController.h"
#import "SZPermissionGate.h"

@interface SZAppDelegate ()

@property (nonatomic, strong) SZMenuController *menuController;
@property (nonatomic, strong) SZAccessibility *accessibility;
@property (nonatomic, strong) SZPermissionGate *permissionGate;

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
    // The scroll monitor and synthesizer land in later changes; until then
    // arming only surfaces the granted state in the menu.
    [self.menuController updatePermissionStatus:YES];
}

@end

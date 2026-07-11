#import "SZAppDelegate.h"

#import "SZMenuController.h"

@interface SZAppDelegate ()

@property (nonatomic, strong) SZMenuController *menuController;

@end

@implementation SZAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.menuController = [[SZMenuController alloc] init];
    [self.menuController install];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)application {
    return YES;
}

@end

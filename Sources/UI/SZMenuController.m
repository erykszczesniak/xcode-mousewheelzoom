#import "SZMenuController.h"

@interface SZMenuController ()

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenuItem *permissionStatusItem;

@end

@implementation SZMenuController

- (void)install {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    NSImage *icon = [NSImage imageWithSystemSymbolName:@"plus.magnifyingglass"
                              accessibilityDescription:@"ScrollZoom"];
    [icon setTemplate:YES];
    self.statusItem.button.image = icon;

    self.statusItem.menu = [self buildMenu];
}

- (void)updatePermissionStatus:(BOOL)granted {
    self.permissionStatusItem.title = granted ? @"Accessibility: granted"
                                              : @"Accessibility: not granted";
}

#pragma mark - Menu construction

- (NSMenu *)buildMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"ScrollZoom"];

    NSMenuItem *headerItem = [[NSMenuItem alloc] initWithTitle:@"ScrollZoom"
                                                        action:NULL
                                                 keyEquivalent:@""];
    headerItem.enabled = NO;
    [menu addItem:headerItem];

    self.permissionStatusItem = [[NSMenuItem alloc] initWithTitle:@"Accessibility: unknown"
                                                           action:NULL
                                                    keyEquivalent:@""];
    self.permissionStatusItem.enabled = NO;
    [menu addItem:self.permissionStatusItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit ScrollZoom"
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    quitItem.target = NSApp;
    [menu addItem:quitItem];

    return menu;
}

@end

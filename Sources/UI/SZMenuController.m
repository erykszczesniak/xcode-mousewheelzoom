#import "SZMenuController.h"

@interface SZMenuController ()

@property (nonatomic, strong) NSStatusItem *statusItem;

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

#pragma mark - Menu construction

- (NSMenu *)buildMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"ScrollZoom"];

    NSMenuItem *headerItem = [[NSMenuItem alloc] initWithTitle:@"ScrollZoom"
                                                        action:NULL
                                                 keyEquivalent:@""];
    headerItem.enabled = NO;
    [menu addItem:headerItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit ScrollZoom"
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    quitItem.target = NSApp;
    [menu addItem:quitItem];

    return menu;
}

@end

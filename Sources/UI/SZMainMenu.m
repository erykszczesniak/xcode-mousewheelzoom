#import "SZMainMenu.h"

#import "SZStrings.h"

@implementation SZMainMenu

+ (void)installWithSettingsAction:(SEL)settingsAction target:(id)target {
    NSMenu *mainMenu = [[NSMenu alloc] init];

    NSMenuItem *appItem = [[NSMenuItem alloc] init];
    appItem.submenu = [self buildAppMenuWithSettingsAction:settingsAction target:target];
    [mainMenu addItem:appItem];

    NSMenuItem *windowItem = [[NSMenuItem alloc] init];
    windowItem.submenu = [self buildWindowMenu];
    [mainMenu addItem:windowItem];

    NSApp.mainMenu = mainMenu;
}

+ (NSMenu *)buildAppMenuWithSettingsAction:(SEL)settingsAction target:(id)target {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:SZLocalizedAppName()];

    NSMenuItem *settingsItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuSettings()
                                                          action:settingsAction
                                                   keyEquivalent:@","];
    settingsItem.target = target;
    [menu addItem:settingsItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:SZLocalizedMenuQuit()
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    quitItem.target = NSApp;
    [menu addItem:quitItem];

    return menu;
}

+ (NSMenu *)buildWindowMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:SZLocalizedMenuWindow()];
    // Target stays nil: ⌘W travels the responder chain to the key window.
    [menu addItemWithTitle:SZLocalizedMenuClose()
                    action:@selector(performClose:)
             keyEquivalent:@"w"];
    return menu;
}

@end

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// An agent app has no main menu, so standard key equivalents (⌘, for
/// Settings, ⌘W to close a window, ⌘Q to quit) never reach anything. This
/// installs a minimal, never-displayed main menu purely to route them.
@interface SZMainMenu : NSObject

/// Installs the menu on NSApp. `openSettingsHandler` runs on ⌘,.
+ (void)installWithSettingsAction:(SEL)settingsAction target:(id)target;

@end

NS_ASSUME_NONNULL_END

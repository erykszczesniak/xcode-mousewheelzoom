#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Seam over login-item registration so the app layer never talks to
/// ServiceManagement directly and can be tested with a fake.
@protocol SZLoginItemManaging <NSObject>

/// Whether the agent is currently registered to start at login.
@property (nonatomic, readonly, getter=isEnabled) BOOL enabled;

/// Registers or unregisters the agent as a login item. Returns NO and fills
/// `error` on failure.
- (BOOL)setEnabled:(BOOL)enabled error:(NSError **)error;

@end

/// Thin edge wrapper over `SMAppService.mainAppService` (macOS 13+).
@interface SZLoginItem : NSObject <SZLoginItemManaging>
@end

NS_ASSUME_NONNULL_END

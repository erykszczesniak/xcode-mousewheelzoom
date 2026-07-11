#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// System-wide hotkey via Carbon's RegisterEventHotKey — works without any
/// extra permission, unlike key-event monitors. One instance = one hotkey.
@interface SZHotKey : NSObject

/// `keyCode` is a virtual key code, `modifiers` Carbon modifier flags
/// (cmdKey, optionKey, controlKey, shiftKey). `handler` runs on the main
/// thread each time the hotkey fires.
- (instancetype)initWithKeyCode:(UInt32)keyCode
                      modifiers:(UInt32)modifiers
                        handler:(void (^)(void))handler NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly, getter=isRegistered) BOOL registered;

/// Registers the hotkey with the system. Returns NO if registration failed
/// (e.g. the combination is taken). Safe to call repeatedly.
- (BOOL)registerHotKey;

/// Removes the registration. Safe to call repeatedly; also runs on dealloc.
- (void)unregisterHotKey;

@end

NS_ASSUME_NONNULL_END

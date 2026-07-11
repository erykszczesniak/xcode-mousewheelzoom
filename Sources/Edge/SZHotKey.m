#import "SZHotKey.h"

#import <Carbon/Carbon.h>

static const OSType SZHotKeySignature = 'SZhk';

@interface SZHotKey ()

@property (nonatomic) UInt32 keyCode;
@property (nonatomic) UInt32 modifiers;
@property (nonatomic, copy) void (^handler)(void);
@property (nonatomic) EventHotKeyRef hotKeyRef;
@property (nonatomic) EventHandlerRef eventHandlerRef;

@end

static OSStatus SZHotKeyEventHandler(EventHandlerCallRef nextHandler,
                                     EventRef event,
                                     void *userData) {
    SZHotKey *hotKey = (__bridge SZHotKey *)userData;

    EventHotKeyID hotKeyID;
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID,
                                        NULL, sizeof(hotKeyID), NULL, &hotKeyID);
    if (status != noErr || hotKeyID.signature != SZHotKeySignature) {
        return status;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (hotKey.handler) {
            hotKey.handler();
        }
    });
    return noErr;
}

@implementation SZHotKey

- (instancetype)initWithKeyCode:(UInt32)keyCode
                      modifiers:(UInt32)modifiers
                        handler:(void (^)(void))handler {
    self = [super init];
    if (self) {
        _keyCode = keyCode;
        _modifiers = modifiers;
        _handler = [handler copy];
    }
    return self;
}

- (void)dealloc {
    [self unregisterHotKey];
}

- (BOOL)isRegistered {
    return self.hotKeyRef != NULL;
}

- (BOOL)registerHotKey {
    if (self.hotKeyRef != NULL) {
        return YES;
    }

    if (self.eventHandlerRef == NULL) {
        EventTypeSpec eventType = {.eventClass = kEventClassKeyboard,
                                   .eventKind = kEventHotKeyPressed};
        OSStatus status = InstallEventHandler(GetApplicationEventTarget(),
                                              SZHotKeyEventHandler, 1, &eventType,
                                              (__bridge void *)self, &_eventHandlerRef);
        if (status != noErr) {
            return NO;
        }
    }

    EventHotKeyID hotKeyID = {.signature = SZHotKeySignature, .id = 1};
    OSStatus status = RegisterEventHotKey(self.keyCode, self.modifiers, hotKeyID,
                                          GetApplicationEventTarget(), 0, &_hotKeyRef);
    if (status != noErr) {
        self.hotKeyRef = NULL;
        return NO;
    }
    return YES;
}

- (void)unregisterHotKey {
    if (self.hotKeyRef != NULL) {
        UnregisterEventHotKey(self.hotKeyRef);
        self.hotKeyRef = NULL;
    }
    if (self.eventHandlerRef != NULL) {
        RemoveEventHandler(self.eventHandlerRef);
        self.eventHandlerRef = NULL;
    }
}

@end

#import "SZActionMapper.h"

@implementation SZActionMapper

- (instancetype)initWithZoomInKeystroke:(SZKeystrokeSpec)zoomInKeystroke
                       zoomOutKeystroke:(SZKeystrokeSpec)zoomOutKeystroke {
    self = [super init];
    if (self) {
        _zoomInKeystroke = zoomInKeystroke;
        _zoomOutKeystroke = zoomOutKeystroke;
    }
    return self;
}

- (instancetype)init {
    return [self initWithZoomInKeystroke:SZKeystrokeSpecMake(SZKeyCodeEqual, kCGEventFlagMaskCommand)
                        zoomOutKeystroke:SZKeystrokeSpecMake(SZKeyCodeMinus, kCGEventFlagMaskCommand)];
}

- (BOOL)getKeystroke:(SZKeystrokeSpec *)outKeystroke forIntent:(SZZoomIntent)intent {
    NSParameterAssert(outKeystroke != NULL);
    switch (intent) {
        case SZZoomIntentIn:
            *outKeystroke = self.zoomInKeystroke;
            return YES;
        case SZZoomIntentOut:
            *outKeystroke = self.zoomOutKeystroke;
            return YES;
        case SZZoomIntentNone:
            return NO;
    }
}

@end

#import "SZLoginItem.h"

#import <ServiceManagement/ServiceManagement.h>

NSNotificationName const SZLoginItemDidChangeNotification =
    @"SZLoginItemDidChangeNotification";

@implementation SZLoginItem

- (BOOL)isEnabled {
    return SMAppService.mainAppService.status == SMAppServiceStatusEnabled;
}

- (BOOL)setEnabled:(BOOL)enabled error:(NSError **)error {
    SMAppService *service = SMAppService.mainAppService;
    BOOL succeeded = enabled ? [service registerAndReturnError:error]
                             : [service unregisterAndReturnError:error];
    if (succeeded) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:SZLoginItemDidChangeNotification
                          object:self];
    }
    return succeeded;
}

@end

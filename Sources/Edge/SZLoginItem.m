#import "SZLoginItem.h"

#import <ServiceManagement/ServiceManagement.h>

@implementation SZLoginItem

- (BOOL)isEnabled {
    return SMAppService.mainAppService.status == SMAppServiceStatusEnabled;
}

- (BOOL)setEnabled:(BOOL)enabled error:(NSError **)error {
    SMAppService *service = SMAppService.mainAppService;
    if (enabled) {
        return [service registerAndReturnError:error];
    }
    return [service unregisterAndReturnError:error];
}

@end

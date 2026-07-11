#import <Cocoa/Cocoa.h>

#import "SZAppDelegate.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        SZAppDelegate *delegate = [[SZAppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return EXIT_SUCCESS;
}

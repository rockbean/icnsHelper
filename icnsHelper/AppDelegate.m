//
//  AppDelegate.m
//  icnsHelper
//
//  Created by ndpop on 2021/9/11.
//

#import "AppDelegate.h"
#import "IcnsHelper.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    IcnsHelper *helper = [[IcnsHelper alloc] initWith:@"/Users/ndpop/Desktop/icntest/CotEditor.app"];

//    [helper icnsToImageFor:@"png"];
    
//    [helper imageToIcnsFrom:@"/Users/ndpop/Desktop/show.png"];
    
    [helper drawOverlayIconWith:@"/Users/ndpop/Desktop/show.png"];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end

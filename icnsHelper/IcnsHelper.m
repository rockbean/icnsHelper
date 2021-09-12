//
//  icnsHelper.m
//  icnsHelper
//
//  Created by ndpop on 2021/9/11.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "IconFamily.h"
#import "IcnsHelper.h"

@interface IcnsHelper()
@property NSString *icnsPath;
@property NSArray *icnsReps;
@property IconFamily *icnFamily;
@end

static NSUInteger ImageTypeForSuffix(NSString *suffix) {
    NSDictionary *map = @{
        @"jpg" : @(NSBitmapImageFileTypeJPEG),
        @"jpeg": @(NSBitmapImageFileTypeJPEG),
        @"png":  @(NSBitmapImageFileTypePNG),
        @"gif":  @(NSBitmapImageFileTypeGIF),
        @"tiff": @(NSBitmapImageFileTypeTIFF),
        @"bmp":  @(NSBitmapImageFileTypeBMP)
    };
    
    NSString *s = [suffix lowercaseString];
    NSNumber *imgTypeNum = map[s];
    if (!imgTypeNum) {
        return -1;
    }
    
    return [imgTypeNum unsignedIntegerValue];
}

@implementation IcnsHelper

- (id) initWith:(NSString *)appPath
{
    if (self = [super init]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:appPath]) {
            NSLog(@"Fail to find: %@", appPath);
            exit(-1);
        }
        
        NSBundle *app = [NSBundle bundleWithPath:appPath];
        if (app == nil) {
            NSLog(@"Path is not app: %@", appPath);
            exit(-1);
        }
        
        NSString *icnsName = [app objectForInfoDictionaryKey:@"CFBundleIconFile"];
        if (icnsName == nil) {
            NSLog(@"Fail to find app icon name: %@", appPath);
            exit(-1);
        }
        
        _icnsPath = [app pathForResource:icnsName ofType:@"icns"];
        if (_icnsPath == nil) {
            NSLog(@"Fail to find app icns path: %@", appPath);
            exit(-1);
        }

        _icnsReps = [[[NSImage alloc] initWithContentsOfFile:_icnsPath] representations];
    }
    return self;
}

- (NSDictionary *) icnsToImageFor:(NSString *)suffix
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    NSUInteger imgType = NSBitmapImageFileTypeTIFF;
    if (suffix) {
        imgType = ImageTypeForSuffix(suffix);
    }
    
    if (imgType < 0) {
        NSLog(@"Unknown file suffix: %@", suffix);
        exit(-1);
    }
    
    NSDictionary *prop = @{ NSImageCompressionFactor : @(1.0f) };
    for (NSImageRep *rep in _icnsReps) {
        if (![rep isKindOfClass:[NSBitmapImageRep class]]) {
            continue;
        }
        NSBitmapImageRep *brep = (NSBitmapImageRep *)rep;
        NSData *data = [brep representationUsingType:imgType properties:prop];
        
        if (data == nil) {
            NSLog(@"Fail to create image data for %lu", (unsigned long)imgType);
            exit(-1);
        }
        
        [ret setObject:data forKey:@(brep.pixelsWide)];
    }
    return ret;
}

- (int) imageToIcnsFrom: (NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        NSLog(@"Fail to find: %@", path);
        return -1;
    }
    
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
    if (img == nil) {
        NSLog(@"Invalid image file: %@", path);
        return -1;
    }
    
    _icnFamily = [[IconFamily alloc] initWithThumbnailsOfImage:img];
    return 0;
}

- (int) drawOverlayIconWith:(NSString *)overlay
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:overlay]) {
        NSLog(@"Fail to find: %@", overlay);
        return -1;
    }
    
    size_t size = 1024;
    NSImage *overlayImg =[[NSImage alloc] initWithContentsOfFile:overlay];
    NSImageRep *backgroundImg = nil;
    NSInteger max = 0;

    for (NSImageRep *rep in _icnsReps) {
        if (![rep isKindOfClass:[NSBitmapImageRep class]]) {
            continue;
        }
        NSBitmapImageRep *brep = (NSBitmapImageRep *)rep;
        
        if (backgroundImg == nil) {
            backgroundImg = rep;
            max = brep.pixelsWide;
        } else if (brep.pixelsWide > backgroundImg.pixelsWide) {
            backgroundImg = rep;
            max = brep.pixelsWide;
        }
    }
    
    if (backgroundImg == nil) {
        NSLog(@"Couldn't find the background image");
        return -1;
    }
    
    NSBitmapImageRep *trep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                                    pixelsWide: size
                                                                    pixelsHigh: size
                                                                 bitsPerSample: 8
                                                               samplesPerPixel: 4
                                                                      hasAlpha: YES
                                                                      isPlanar: NO
                                                                colorSpaceName: NSDeviceRGBColorSpace
                                                                   bytesPerRow: 0
                                                                  bitsPerPixel: 0];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep: trep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: ctx];
    [backgroundImg drawInRect:NSMakeRect(0, 0, size, size)];
    [overlayImg drawInRect:NSMakeRect(0, 0, size/2, size/2)
               fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
    [ctx flushGraphics];
    [NSGraphicsContext restoreGraphicsState];
    
    NSImage *finImg = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
    [finImg addRepresentation:trep];
    
    _icnFamily = [[IconFamily alloc] initWithThumbnailsOfImage:finImg];
    
    NSError *err;
    [fm removeItemAtPath:_icnsPath error:&err];
    if (err) {
        NSLog(@"Fail to remove %@, %@", _icnsPath, err);
        return -1;
    }
    if (![_icnFamily writeToFile:_icnsPath]) {
        NSLog(@"Fail to write icns");
        return -1;
    }
    return 0;
}

@end

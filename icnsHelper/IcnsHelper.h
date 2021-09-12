//
//  icnsHelper.h
//  icnsHelper
//
//  Created by ndpop on 2021/9/11.
//

#ifndef icnsHelper_h
#define icnsHelper_h
@interface IcnsHelper : NSObject
- (id) initWith:(NSString *)appPath;
- (NSDictionary *) icnsToImageFor:(NSString *)type;
- (int) imageToIcnsFrom: (NSString *)path;
- (int) drawOverlayIconWith:(NSString *)overlay;
@end

#endif /* icnsHelper_h */

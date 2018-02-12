//
//  NSXMLXibDocument.h
//  xib2Storyboard
//
//  Created by Dries Van Schevensteen on 15/01/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Platform) {
    PlatformUnsuported,
    PlatformIOS,
    PlatformTVOS
};



#pragma mark - NSXMLXibDocument interface -

@interface NSXMLXibDocument : NSXMLDocument

#pragma mark Properties

@property (nonatomic, readonly, strong, nullable) NSURL *fileURL;
@property (nonatomic, readonly, assign) Platform platform;



#pragma mark Initializers

- (nonnull instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initWithRootElement:(NSXMLElement * _Nullable)element NS_UNAVAILABLE;

- (nullable instancetype)initWithData:(NSData * _Nullable)data options:(NSXMLNodeOptions)mask error:(NSError * _Nullable __autoreleasing)error NS_UNAVAILABLE;

- (nonnull instancetype)initWithFileURL:(NSURL * _Nullable)fileURL;

@end

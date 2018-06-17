//
//  NSXMLLayoutDocument.h
//  xib2Storyboard
//
//  Created by Dries Van Schevensteen on 25/03/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

typedef NS_ENUM(NSInteger, Platform) {
    PlatformUnsuported,
    PlatformIOS,
    PlatformTVOS
};

typedef NS_ENUM(NSInteger, LayoutType) {
    LayoutTypeUnsuported,
    LayoutTypeXib,
    LayoutTypeStoryboard
};



#pragma mark - NSXMLLayoutDocument interface -

@interface NSXMLLayoutDocument : NSXMLDocument



#pragma mark Properties

@property (nonatomic, readonly, strong, nullable) NSURL *fileURL;

@property (nonatomic, readonly, assign) Platform platform;

@property (nonatomic, readonly, assign) LayoutType layoutType;



#pragma mark Initializers

- (instancetype _Nonnull)init NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithRootElement:(NSXMLElement * _Nullable)element NS_UNAVAILABLE;

- (instancetype _Nullable)initWithData:(NSData * _Nullable)data options:(NSXMLNodeOptions)mask error:(NSError * _Nullable __autoreleasing)error NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithFileURL:(NSURL * _Nonnull)fileURL layoutType:(LayoutType)layoutType;

- (instancetype _Nonnull)initFromUserSelectionWithWindow:(NSWindow * _Nonnull)window layoutType:(LayoutType)layoutType;



#pragma mark Generate storyboards

+ (NSXMLLayoutDocument * _Nullable)generateStoryboardFromXib:(NSXMLLayoutDocument * _Nonnull)xib forPlatform:(Platform)platform;

+ (NSXMLLayoutDocument * _Nullable)generateStoryboardFromXibs:(NSArray<NSXMLLayoutDocument *> * _Nonnull)xibs forPlatform:(Platform)platform;

- (void)addXibs:(NSArray<NSXMLLayoutDocument *> * _Nonnull)xibs;



#pragma mark Save

- (void)save;

- (void)saveWithName:(NSString * _Nullable)initialName onWindow:(NSWindow * _Nonnull)window;

- (void)saveForURL:(NSURL * _Nonnull)fileURL;

@end

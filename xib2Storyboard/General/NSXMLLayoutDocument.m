//
//  NSXMLLayoutDocument.m
//  xib2Storyboard
//
//  Created by Dries Van Schevensteen on 25/03/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import "NSXMLLayoutDocument.h"


const CGFloat ViewControllerSpacing = 1000;



#pragma mark - NSXMLLayoutDocument class extenstion -

@interface NSXMLLayoutDocument ()

#pragma mark Properties

@property (readwrite) NSURL *fileURL;

@property (readwrite) LayoutType layoutType;

@end



#pragma mark - NSXMLLayoutDocument implementation -

@implementation NSXMLLayoutDocument


#pragma mark Initialize & Destory

- (instancetype)initWithFileURL:(NSURL *)fileURL layoutType:(LayoutType)layoutType {
    
    self = [super initWithContentsOfURL:fileURL options:NSXMLNodeOptionsNone error:nil];
    if (self) {
        
        self.fileURL = fileURL;
        self.layoutType = layoutType;
        
    }
    
    return self;
}

- (instancetype)initFromUserSelectionWithWindow:(NSWindow *)window layoutType:(LayoutType)layoutType {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[[[self class] fileExtenstionForLayoutType:layoutType]];
    
    NSModalResponse response = [panel runModal];
    if (response == NSModalResponseOK) {
        
        NSURL *fileURL = panel.URL;
        self = [super initWithContentsOfURL:fileURL options:NSXMLNodeOptionsNone error:nil];
        if (self) {
            
            self.fileURL = fileURL;
            self.layoutType = layoutType;
            
        }
        
    }
    
    return self;
}

- (instancetype)initWithRootElement:(NSXMLElement *)rootElement layoutType:(LayoutType)layoutType {
    
    self = [super initWithRootElement:rootElement];
    if (self) {
        
        self.layoutType = layoutType;
        
    }
    
    return self;
}



#pragma mark Custom Getters & Setters

- (Platform)platform {
    
    NSXMLNode *documentNode = nil;
    if ([[[self.children firstObject] name] isEqualToString:@"document"]) {
        documentNode = [self.children firstObject];
    }
    
    NSXMLNode *dependenciesNode = [[documentNode nodesForXPath:@"dependencies" error:nil] firstObject];
//    NSXMLNode *objectsNode = [[documentNode nodesForXPath:@"objects" error:nil] firstObject];
    
    if (dependenciesNode) {
        
        NSXMLElement *deploymentElement = [[[dependenciesNode nodesForXPath:@"deployment" error:nil] firstObject] xmlElementOrNil];
        NSString *platform = [deploymentElement attributeForName:@"identifier"].stringValue;
        
        if ([platform isEqualToString:@"iOS"]) {
            return PlatformIOS;
        }
        else if ([platform isEqualToString:@"tvOS"]) {
            return PlatformTVOS;
        }
        // If no platform found, make the assumption it's an iOS XIB
        else {
            return PlatformIOS;
        }
    }
    
    return PlatformUnsuported;
}



#pragma mark Generate storyboards

+ (NSXMLLayoutDocument *)generateStoryboardFromXib:(NSXMLLayoutDocument *)xib forPlatform:(Platform)platform {
    
    return [[self class] generateStoryboardFromXibs:@[xib] forPlatform:platform];
}

+ (NSXMLLayoutDocument *)generateStoryboardFromXibs:(NSArray<NSXMLLayoutDocument *> *)xibs forPlatform:(Platform)platform {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"platform = %d", platform];
    NSArray<NSXMLLayoutDocument *> *filteredXibs = [xibs filteredArrayUsingPredicate:predicate];
    
    if (filteredXibs.count == 0) {
        return nil;
    }
    
    NSXMLDocument *result = [self storyboardTemplateForPlatform:platform];
    NSXMLElement *storyboardDocumentNode = [[result nodesForXPath:@"document" error:nil] firstObject];
    
    CGPoint canvasPosition = CGPointMake(0, 0);
    
    for (NSXMLLayoutDocument *xib in filteredXibs) {
        if (xib.platform == platform) {
            
            [self addXib:xib atCanvasPosition:canvasPosition toStoryboardDocumentNode:storyboardDocumentNode];
            
            canvasPosition.x += ViewControllerSpacing;
        }
    }
    
    return [[NSXMLLayoutDocument alloc] initWithRootElement:[result.rootElement copy] layoutType:LayoutTypeStoryboard];
}

- (void)addXibs:(NSArray<NSXMLLayoutDocument *> * _Nonnull)xibs {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"platform = %d", self.platform];
    NSArray<NSXMLLayoutDocument *> *filteredXibs = [xibs filteredArrayUsingPredicate:predicate];
    
    if (filteredXibs.count == 0) {
        return;
    }
    
    NSXMLElement *storyboardDocumentNode = [[self nodesForXPath:@"document" error:nil] firstObject];
    
    CGPoint canvasPosition = CGPointMake(ViewControllerSpacing, 0);
    
    for (NSXMLLayoutDocument *xib in xibs) {
        if (xib.platform == self.platform) {
            
            [[self class] addXib:xib atCanvasPosition:canvasPosition toStoryboardDocumentNode:storyboardDocumentNode];
            
            canvasPosition.x += ViewControllerSpacing;
        }
    }
}



#pragma mark Save

- (void)save {
    
    [self saveForURL:self.fileURL];
}

- (void)saveWithName:(NSString *)initialName onWindow:(NSWindow *)window {
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    if (initialName) {
        [panel setNameFieldStringValue:initialName];
    }
    
    NSModalResponse response = [panel runModal];
    if (response == NSModalResponseOK) {
        NSURL *outputURL = panel.URL;
        [self saveForURL:outputURL];
    }
}

- (void)saveForURL:(NSURL *)fileURL {
    
    NSData *data = [self XMLDataWithOptions:NSXMLNodePrettyPrint];
    __unused BOOL success = [data writeToURL:fileURL atomically:YES];
}



#pragma mark Platform helpers

+ (NSXMLDocument *)storyboardTemplateForPlatform:(Platform)platform {
    
    NSString *templateName;
    
    switch (platform) {
            
        case PlatformIOS:
            templateName = @"storyboard_template_ios";
            break;
            
        case PlatformTVOS:
            templateName = @"storyboard_template_tvos";
            break;
            
        default:
            break;
    }
    
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:templateName ofType:@"xml"];
    return [[NSXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:templatePath] options:NSXMLNodeOptionsNone error:nil];
}



#pragma mark Layout helpers

+ (NSString *)fileExtenstionForLayoutType:(LayoutType)layoutType {
    
    switch (layoutType) {
            
        case LayoutTypeXib:
            return @"xib";
            break;
            
        case LayoutTypeStoryboard:
            return @"storyboard";
            break;
            
        case LayoutTypeUnsuported:
        default:
            return @"";
            break;
    }
}



#pragma mark Manipulate IDs

+ (NSXMLElement *)xmlElement:(NSXMLElement *)element byReplaceingRootViewID:(NSString *)ID {
    
    return [self xmlElement:element byReplacingID:ID withID:@"i5M-Pr-FkT"];
}

+ (NSXMLElement *)xmlElement:(NSXMLElement *)element byReplacingFileOwnerDestinationWithID:(NSString *)ID {
    
    return [self xmlElement:element byReplacingID:ID withID:@"-1"];
}

+ (NSXMLElement *)xmlElement:(NSXMLElement *)element byReplacingID:(NSString *)ID withID:(NSString *)newID {
    
    NSMutableString *elementString = [element.XMLString mutableCopy];
    [elementString replaceOccurrencesOfString:[NSString stringWithFormat:@"\"%@\"", newID]
                                   withString:[NSString stringWithFormat:@"\"%@\"", ID]
                                      options:0
                                        range:NSMakeRange(0, elementString.length)];
    
    return [[NSXMLElement alloc] initWithXMLString:elementString error:nil];
}

+ (NSString *)generateUniqueObjectID {
    
    NSString *objectID = [NSString stringWithFormat:@"%@%@%@-%@%@-%@%@%@", [self randomCharacter], [self randomCharacter], [self randomCharacter], [self randomCharacter], [self randomCharacter], [self randomCharacter], [self randomCharacter], [self randomCharacter]];
    return objectID;
}

+ (NSString *)randomCharacter {
    
    NSString *characters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    unichar character[1];
    character[0] = [characters characterAtIndex:arc4random() % [characters length]];
    return [NSString stringWithCharacters:character length:1];
}

+ (NSXMLElement *)randomizeIDsAndLinks:(NSXMLElement *)element {
    
    NSArray<NSString *> *IDs = [self getIDsFromElement:element];
    
    NSString *elementString = [element XMLString];
    
    NSArray<NSString *> *keysToReplace = @[@"id", @"destination", @"firstItem", @"secondItem", @"reference"];
    
    for (NSString *ID in IDs) {
        NSString *newID = [self generateUniqueObjectID];
        
        for (NSString *keyToReplace in keysToReplace) {
            NSString *oldKeyString = [NSString stringWithFormat:@"%@=\"%@\"", keyToReplace, ID];
            NSString *newKeyString = [NSString stringWithFormat:@"%@=\"%@\"", keyToReplace, newID];

            elementString = [elementString stringByReplacingOccurrencesOfString:oldKeyString withString:newKeyString];
        }
    }
    
    return [[NSXMLElement alloc] initWithXMLString:elementString error:nil];
}

+ (NSArray<NSString *> *)getIDsFromElement:(NSXMLElement *)parentElement {
    
    NSMutableArray *IDs = [NSMutableArray new];
    
    NSXMLNode *elementID = [parentElement attributeForName:@"id"];
    if (elementID) {
        [IDs addObject:[elementID stringValue]];
    }
    
    for (id element in parentElement.children) {
        if ([element isKindOfClass:[NSXMLElement class]]) {
            [IDs addObjectsFromArray:[self getIDsFromElement:element]];
        }
    }
    
    return [IDs copy];
}



#pragma mark Manipulate Views

+ (NSXMLElement *)xmlElementByModifyingTableViewDataMode:(NSXMLElement *)element {
    
    NSMutableString *elementString = [element.XMLString mutableCopy];
    [elementString replaceOccurrencesOfString:@"<tableView " withString:@"<tableView dataMode=\"prototypes\" " options:0 range:NSMakeRange(0, elementString.length)];
    
    return [[NSXMLElement alloc] initWithXMLString:elementString error:nil];
}



#pragma mark Xib insertion

+ (void)addXib:(NSXMLLayoutDocument *)xib atCanvasPosition:(CGPoint)canvasPosition toStoryboardDocumentNode:(NSXMLElement *)storyboardDocumentNode {
    // Replace root view ID
    NSString *rootViewID = [[self class] generateUniqueObjectID];
    xib.rootElement = [[self class] xmlElement:xib.rootElement byReplaceingRootViewID:rootViewID];
    
    NSXMLElement *xibDocumentElement;
    if ([xib.rootElement.name isEqualToString:@"document"]) {
        xibDocumentElement = xib.rootElement;
    }
    
    if (xibDocumentElement) {
        
        // Copy resources
        NSXMLElement *sbResourcesElement = [[storyboardDocumentNode elementsForName:@"resources"] firstObject];
        NSXMLElement *xibResourcesElement = [[xibDocumentElement elementsForName:@"resources"] firstObject];
        
        
        
        for (NSXMLNode *xibNode in xibResourcesElement.children) {
            
            NSString *xibNodeName = [[[xibNode xmlElementOrNil] attributeForName:@"name"] stringValue];
            
            // Only add new resource if not yet in list
            BOOL canAddNode = YES;
            if (xibNodeName) {
                
                for (NSXMLNode *sbNode in sbResourcesElement.children) {
                    
                    NSString *sbNodeName = [[[sbNode xmlElementOrNil] attributeForName:@"name"] stringValue];
                    if ([xibNodeName isEqualToString:sbNodeName]) {
                        
                        canAddNode = NO;
                    }
                }
            }
            
            if (canAddNode) {
                
                [sbResourcesElement addChild:[xibNode copy]];
            }
        }
        
        // Check for a file owner
        NSXMLElement *xibObjectsElement = [[xibDocumentElement elementsForName:@"objects"] firstObject];
        
        // Replace file owner destination ID
        NSString *viewcontrollerID = [self generateUniqueObjectID];
        xibObjectsElement = [self xmlElement:xibObjectsElement byReplacingFileOwnerDestinationWithID:viewcontrollerID];
        
        // Make all UITableViews have prototypes
        xibObjectsElement = [self xmlElementByModifyingTableViewDataMode:xibObjectsElement];
        
        // Loop over xibObjectsElement remove placeholder & view
        NSArray *xibPlaceholderElements = [xibObjectsElement elementsForName:@"placeholder"];
        NSArray *xibViewElements = [xibObjectsElement elementsForName:@"view"];
        NSMutableArray *xibOtherElements = [NSMutableArray new];
        for (NSXMLElement *element in [xibObjectsElement children] ?: @[]) {
            if (![element.name isEqualToString:@"view"] && ![element.name isEqualToString:@"placeholder"]) {
                [xibOtherElements addObject:element];
            }
        }
        
        NSXMLElement *xibFileOwnerElement = nil;
        for (NSXMLElement *element in xibPlaceholderElements) {
            if ([[[element attributeForName:@"placeholderIdentifier"] stringValue] isEqualToString:@"IBFilesOwner"]) {
                xibFileOwnerElement = element;
                break;
            }
        }
        
        // Only continue if the xib has a file owner
        if (xibFileOwnerElement) {
            
            // Create scene
            NSString *sceneID = [self generateUniqueObjectID];
            NSXMLElement *sceneElement = [NSXMLElement elementWithName:@"scene" children:nil attributes:@[ [NSXMLNode attributeWithName:@"sceneID" stringValue:sceneID] ]];
            
            NSXMLElement *objectsElement = [NSXMLElement elementWithName:@"objects"];
            [sceneElement addChild:objectsElement];
            
            NSArray *pointAttributes = @[ [NSXMLNode attributeWithName:@"key" stringValue:@"canvasLocation"],
                                          [NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%.0f", canvasPosition.x]],
                                          [NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%.0f", canvasPosition.y]] ];
            NSXMLElement *pointElement = [NSXMLElement elementWithName:@"point" children:nil attributes:pointAttributes];
            [sceneElement addChild:pointElement];
            
            // Create viewcontroller
            NSString *customClassName = [[xibFileOwnerElement attributeForName:@"customClass"] stringValue];
            NSArray *xibOutletElements = [[[xibFileOwnerElement elementsForName:@"connections"] firstObject] elementsForName:@"outlet"];
            NSArray *xibOutletCollectionElements = [[[xibFileOwnerElement elementsForName:@"connections"] firstObject] elementsForName:@"outletCollection"];
            
            
            NSMutableArray *viewcontrollerAttributes = [NSMutableArray new];
            [viewcontrollerAttributes addObject:[NSXMLNode attributeWithName:@"id" stringValue:viewcontrollerID]];
            [viewcontrollerAttributes addObject:[NSXMLNode attributeWithName:@"sceneMemberID" stringValue:@"viewController"]];
            [viewcontrollerAttributes addObject:[NSXMLNode attributeWithName:@"useStoryboardIdentifierAsRestorationIdentifier" stringValue:@"YES"]];
            if (customClassName) {
                [viewcontrollerAttributes addObject:[NSXMLNode attributeWithName:@"customClass" stringValue:customClassName]];
                [viewcontrollerAttributes addObject:[NSXMLNode attributeWithName:@"storyboardIdentifier" stringValue:customClassName]];
                [viewcontrollerAttributes addObject:[NSXMLNode attributeWithName:@"userLabel" stringValue:customClassName]];
            }
            
            NSXMLElement *viewcontrollerElement = [NSXMLElement elementWithName:@"viewController" children:nil attributes:viewcontrollerAttributes];
            [objectsElement addChild:viewcontrollerElement];
            
            // Create first responder
            NSMutableArray *firstResponderAttributes = [NSMutableArray new];
            [firstResponderAttributes addObject:[NSXMLNode attributeWithName:@"placeholderIdentifier" stringValue:@"IBFirstResponder"]];
            [firstResponderAttributes addObject:[NSXMLNode attributeWithName:@"id" stringValue:[self generateUniqueObjectID]]];
            [firstResponderAttributes addObject:[NSXMLNode attributeWithName:@"userLabel" stringValue:@"First Responder"]];
            [firstResponderAttributes addObject:[NSXMLNode attributeWithName:@"sceneMemberID" stringValue:@"firstResponder"]];
            
            NSXMLElement *firstResponderElement = [NSXMLElement elementWithName:@"placeholder" children:nil attributes:firstResponderAttributes];
            [objectsElement addChild:firstResponderElement];
            
            // Connections
            NSXMLElement *connectionsElement = [NSXMLElement elementWithName:@"connections"];
            NSString *viewID = nil;
            
            // Copy outlets except for view
            for (NSXMLElement *element in xibOutletElements) {
                if ([[[element attributeForName:@"property"] stringValue] isEqualToString:@"view"]) {
                    viewID = [[element attributeForName:@"destination"] stringValue];
                }
                else {
                    [connectionsElement addChild:[element copy]];
                }
            }
            
            // Copy outlet collections
            for (NSXMLElement *element in xibOutletCollectionElements) {
                [connectionsElement addChild:[element copy]];
            }
            
            // Copy views
            for (NSXMLElement *element in xibViewElements) {
                if ([[[element attributeForName:@"id"] stringValue] isEqualToString:viewID]) {
                    [element addAttribute:[NSXMLNode attributeWithName:@"key" stringValue:@"view"]];
                    [viewcontrollerElement addChild:[element copy]];
                }
                else {
                    [objectsElement addChild:[element copy]];
                }
            }
            
            [viewcontrollerElement addChild:connectionsElement];
            
            for (NSXMLElement *otherElement in xibOtherElements) {
                [objectsElement addChild:[otherElement copy]];
            }
            
            // Randomize ID's
            sceneElement = [self randomizeIDsAndLinks:sceneElement];
            
            // Add new scene to storyboard
            NSXMLElement *sbScenesElement = [[storyboardDocumentNode elementsForName:@"scenes"] firstObject];
            [sbScenesElement addChild:sceneElement];
        }
    }
}

@end

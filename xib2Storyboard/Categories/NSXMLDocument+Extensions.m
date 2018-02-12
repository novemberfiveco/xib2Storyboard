//
//  NSXMLDocument+Extensions.m
//  xib2Storyboard
//
//  Created by Dries Van Schevensteen on 15/01/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import "NSXMLDocument+Extensions.h"



#pragma mark - NSXMLDocument Extensions Category -

@implementation NSXMLDocument (Extensions)

+ (NSXMLDocument *)storyboardFromDocuments:(NSArray<NSXMLXibDocument *> *)documents forPlatform:(Platform)platform {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"platform = %d", platform];
    NSArray<NSXMLXibDocument *> *filteredDocuments = [documents filteredArrayUsingPredicate:predicate];
    
    if (filteredDocuments.count == 0) {
        return nil;
    }
    
    NSXMLDocument *storyboardDocument = [self storyboardTemplateForPlatform:platform];
    NSXMLElement *storyboardDocumentNode = [[storyboardDocument nodesForXPath:@"document" error:nil] firstObject];
    
    CGPoint canvasPosition = CGPointMake(0, 0);
    
    for (NSXMLXibDocument *document in documents) {
        if (document.platform == platform) {
            NSXMLElement *xibDocumentElement;
            if ([document.rootElement.name isEqualToString:@"document"]) {
                xibDocumentElement = document.rootElement;
            }
            
            if (xibDocumentElement) {
                
                // Copy resources
                NSXMLElement *sbResourcesElement = [[storyboardDocumentNode elementsForName:@"resources"] firstObject];
                NSXMLElement *xibResourcesElement = [[xibDocumentElement elementsForName:@"resources"] firstObject];
                
                for (NSXMLNode *node in xibResourcesElement.children) {
                    [sbResourcesElement addChild:[node copy]];
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
                    NSXMLElement *sbScenesElement = [[storyboardDocumentNode elementsForName:@"scenes"] firstObject];
                    NSString *sceneID = [self generateUniqueObjectID];
                    NSXMLElement *sceneElement = [NSXMLElement elementWithName:@"scene" children:nil attributes:@[ [NSXMLNode attributeWithName:@"sceneID" stringValue:sceneID] ]];
                    [sbScenesElement addChild:sceneElement];
                    
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
                    
                    for (NSXMLElement* otherElement in xibOtherElements) {
                        [objectsElement addChild:[otherElement copy]];
                    }
                }
            }
            
            canvasPosition.x += 500;
        }
    }
    
    return storyboardDocument;
}

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



#pragma mark Manipulate IDs

+ (NSXMLElement *)xmlElement:(NSXMLElement *)element byReplacingFileOwnerDestinationWithID:(NSString *)ID {
    
    NSMutableString *elementString = [element.XMLString mutableCopy];
    [elementString replaceOccurrencesOfString:@"\"-1\"" withString:[NSString stringWithFormat:@"\"%@\"", ID] options:0 range:NSMakeRange(0, elementString.length)];
    
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



#pragma mark Manipulate Views

+ (NSXMLElement *)xmlElementByModifyingTableViewDataMode:(NSXMLElement *)element {
    
    NSMutableString *elementString = [element.XMLString mutableCopy];
    [elementString replaceOccurrencesOfString:@"<tableView " withString:@"<tableView dataMode=\"prototypes\" " options:0 range:NSMakeRange(0, elementString.length)];
    
    return [[NSXMLElement alloc] initWithXMLString:elementString error:nil];
}



#pragma mark Save

- (void)saveForURL:(NSURL *)outputURL {
    
    NSData *data = [self XMLDataWithOptions:NSXMLNodePrettyPrint];
    __unused BOOL success = [data writeToURL:outputURL atomically:YES];
}

- (void)saveWithName:(NSString *)initialName savePanelWindow:(NSWindow *)window {
    
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

@end

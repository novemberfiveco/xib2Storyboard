//
//  NSXMLXibDocument.m
//  xib2Storyboard
//
//  Created by Dries Van Schevensteen on 15/01/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import "NSXMLXibDocument.h"



#pragma mark - NSXMLXibDocument Class Extension -

@interface NSXMLXibDocument ()

#pragma mark Properties

@property (readwrite) NSURL *fileURL;

@end



#pragma mark - NSXMLXibDocument Implementation -

@implementation NSXMLXibDocument

#pragma mark Initialize & Destory

- (instancetype)initWithFileURL:(NSURL *)fileURL {
    
    self = [super initWithContentsOfURL:fileURL options:NSXMLNodeOptionsNone error:nil];
    if (self) {
        self.fileURL = fileURL;
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
    NSXMLNode *objectsNode = [[documentNode nodesForXPath:@"objects" error:nil] firstObject];

    if (dependenciesNode && objectsNode.childCount > 0) {

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

@end

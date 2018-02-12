//
//  NSXMLDocument+Extensions.h
//  xib2Storyboard
//
//  Created by Dries Van Schevensteen on 15/01/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import <AppKit/AppKit.h>

#import "NSXMLXibDocument.h"



#pragma mark - NSXMLDocument Extensions Category -

@interface NSXMLDocument (Extensions)

+ (nullable NSXMLDocument *)storyboardFromDocuments:(nullable NSArray<NSXMLXibDocument *> *)documents forPlatform:(Platform)platform;

- (void)saveForURL:(nonnull NSURL *)outputURL;

- (void)saveWithName:(nullable NSString *)initialName savePanelWindow:(nonnull NSWindow *)window;

@end

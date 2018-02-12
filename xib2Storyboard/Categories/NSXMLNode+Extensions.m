//
//  NSXMLNode+Extensions.m
//  xib2storyboard
//
//  Created by David De Bels on 10/12/2017.
//  (c) 2017 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import "NSXMLNode+Extensions.h"



#pragma mark - NSXMLNode Extensions Category -

@implementation NSXMLNode (Extensions)

- (NSXMLElement *)xmlElementOrNil {
    
    return [self isKindOfClass:[NSXMLElement class]] ? (NSXMLElement *)self : nil;
}

@end

//
//  NFDraggableView.m
//  xib2Storyboard
//
//  Created by Dries Van Schevensteen on 07/01/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import "NFDraggableView.h"



#pragma mark - NFDraggableView Class Extension -

@interface NFDraggableView() <NSDraggingDestination>

@end



#pragma mark - NFDraggableView Implementation -

@implementation NFDraggableView

#pragma mark View Lifecyle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
}



#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    
    return NSDragOperationEvery;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    
    if ([[pasteboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *fileURLStrings = [pasteboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *fileURLs = [NSMutableArray new];
        
        // Format URL's
        [fileURLStrings enumerateObjectsUsingBlock:^(NSString *  _Nonnull fileURLString, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *encodedFileURLString = [fileURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
            if ([encodedFileURLString hasPrefix:@"file://"]) {
                [fileURLs addObject:[NSURL URLWithString:encodedFileURLString]];
            }
            else {
                [fileURLs addObject:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", encodedFileURLString]]];
            }
        }];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(draggableView:didReceiveFiles:)]) {
            [self.delegate draggableView:self didReceiveFiles:[fileURLs copy]];
        }
    }
    
    return YES;
}

@end

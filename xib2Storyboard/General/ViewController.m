//
//  ViewController.m
//  xib2storyboard
//
//  Created by Dries Van Schevensteen on 15/01/2018.
//  (c) 2018 November Five BVBA
//
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//

#import "ViewController.h"

#import "NFDraggableView.h"
#import "NSXMLLayoutDocument.h"

typedef NS_ENUM(NSInteger, ExportOption) {
    ExportOptionIndividualStoryboards = 0,
    ExportOptionSingleStoryboard = 1,
    ExportOptionExistingStoryboard = 2
};



#pragma mark - ViewController class extension -

@interface ViewController () <NFDraggableViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

#pragma mark Outlets

@property (nonatomic, weak) IBOutlet NSTableView *mainTableView;
@property (nonatomic, weak) IBOutlet NSButton *removeXibButton;
@property (nonatomic, weak) IBOutlet NSComboBox *exportComboBox;
@property (nonatomic, weak) IBOutlet NSButton *exportButton;



#pragma mark Properties

@property (nonatomic, strong) NSMutableArray<NSURL *> *selectedFileURLs;

@end



#pragma mark - ViewController implementation -

@implementation ViewController

#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ((NFDraggableView *)self.view).delegate = self;
}



#pragma mark Custom getters & setters

- (NSMutableArray<NSURL *> *)selectedFileURLs {
    
    if (!_selectedFileURLs) {
        _selectedFileURLs = [NSMutableArray new];
    }
    return _selectedFileURLs;
}



#pragma mark IBActions

- (IBAction)didClickAddXibButton:(id)sender {
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsOtherFileTypes = NO;
    openPanel.allowsMultipleSelection = YES;
    openPanel.allowedFileTypes = @[@"xib"];
    
    __weak typeof(self)weakSelf = self;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            NSArray<NSURL *> *fileURLs = [openPanel URLs];
            [weakSelf addFileURLs:fileURLs];
        }
    }];
}

- (IBAction)didClickRemoveXibButton:(id)sender {
    
    [self removeSelectedURLs];
}

- (IBAction)didClickGenerateButton:(id)sender {
    
    NSMutableArray<NSXMLLayoutDocument *> *documents = [NSMutableArray new];
    for (NSURL *selectedFileURL in self.selectedFileURLs) {
        
        NSXMLLayoutDocument *document = [[NSXMLLayoutDocument alloc] initWithFileURL:selectedFileURL layoutType:LayoutTypeXib];
        [documents addObject:document];
        
    }
    
    ExportOption selectedExportOption = MAX(0, self.exportComboBox.indexOfSelectedItem);
    
    switch (selectedExportOption) {

        case ExportOptionIndividualStoryboards: {
            
            for (NSXMLLayoutDocument *document in documents) {
                
                NSString *outputURLString = [NSString stringWithFormat:@"%@.%@", [document.fileURL.absoluteString stringByDeletingPathExtension], @"storyboard"];
                NSURL *outputURL = [NSURL URLWithString:outputURLString];
                
                NSXMLLayoutDocument *iosStoryboard = [NSXMLLayoutDocument generateStoryboardFromXib:document forPlatform:PlatformIOS];
                if (iosStoryboard) {
                    [iosStoryboard saveForURL:outputURL];
                }
                
                NSXMLLayoutDocument *tvosStoryboard = [NSXMLLayoutDocument generateStoryboardFromXib:document forPlatform:PlatformTVOS];
                if (tvosStoryboard) {
                    [tvosStoryboard saveForURL:outputURL];
                }
            }
            
            break;
        }
            
        case ExportOptionSingleStoryboard: {
            
            NSXMLLayoutDocument *iosStoryboard = [NSXMLLayoutDocument generateStoryboardFromXibs:[documents copy] forPlatform:PlatformIOS];
            if (iosStoryboard) {
                [iosStoryboard saveWithName:@"iOS_converted.storyboard" onWindow:self.view.window];
            }
            
            NSXMLLayoutDocument *tvosStoryboard = [NSXMLLayoutDocument generateStoryboardFromXibs:[documents copy] forPlatform:PlatformTVOS];
            if (tvosStoryboard) {
                [tvosStoryboard saveWithName:@"tvOS_converted.storyboard" onWindow:self.view.window];
            }
            
            break;
        }
            
        case ExportOptionExistingStoryboard: {
            
            NSXMLLayoutDocument *document = [[NSXMLLayoutDocument alloc] initFromUserSelectionWithWindow:self.view.window layoutType:LayoutTypeStoryboard];
            if (document) {
                [document addXibs:documents];
                [document save];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)didClickLogo:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://novemberfive.co/?utm_source=open_source&utm_medium=mac&utm_campaign=xib2storyboard"]];
}



#pragma mark Event Listeners

- (void)keyDown:(NSEvent *)event {
    
    switch ([event keyCode]) {
        case 0x33: // Backspace key pressed
            [self removeSelectedURLs];
            break;
        default:
            break;
    }
}



#pragma mark NFDraggableViewDelegate

- (void)draggableView:(NFDraggableView *)draggableView didReceiveFiles:(NSArray<NSURL *> *)fileURLs {
    
    if (fileURLs) {
        NSArray<NSURL *> *filteredFileURLs = [fileURLs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *fileURL, NSDictionary *bindings) {
            return [[fileURL pathExtension] isEqualToString:@"xib"];
        }]];
        [self addFileURLs:filteredFileURLs];
    }
}



#pragma mark NSTableView Data Source & Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    return self.selectedFileURLs.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    if (tableColumn == tableView.tableColumns[0]) {
        NSTableCellView *view = [tableView makeViewWithIdentifier:@"fileNameTableCellViewIdentifier" owner:nil];
        if (view) {
            NSURL *fileURLForRow = self.selectedFileURLs[row];
            view.textField.stringValue = fileURLForRow.lastPathComponent;
            return view;
        }
    }
    
    return nil;
}



#pragma mark Helpers

- (void)addFileURLs:(NSArray<NSURL *> *)fileURLs {
    
    BOOL addedAllXibs = YES;
    for (NSURL *fileURL in fileURLs) {
        if ([self.selectedFileURLs containsObject:fileURL]) {
            addedAllXibs = NO;
        }
        else {
            [self.selectedFileURLs addObject:fileURL];
        }
    }
    
    [self.mainTableView reloadData];
    
    if (!addedAllXibs) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        if (fileURLs.count > 1) {
            [alert setMessageText:@"Some xib's are already added"];
        }
        else {
            [alert setMessageText:@"The selected xib is already added"];
        }
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert runModal];
    }
}

- (void)removeSelectedURLs {
    
    [self.selectedFileURLs removeObjectsAtIndexes:self.mainTableView.selectedRowIndexes];
    [self.mainTableView reloadData];
}

@end

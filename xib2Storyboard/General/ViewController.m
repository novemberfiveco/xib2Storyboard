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



#pragma mark - ViewController Class Extension -

@interface ViewController () <NFDraggableViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

#pragma mark Outlets

@property (nonatomic, weak) IBOutlet NSTableView *mainTableView;
@property (nonatomic, weak) IBOutlet NSButton *removeXibButton;
@property (nonatomic, weak) IBOutlet NSButton *exportAsSingleStoryboardToggle;
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
    
    NSMutableArray<NSXMLXibDocument *> *documents = [NSMutableArray new];
    for (NSURL *selectedFileURL in self.selectedFileURLs) {
        NSXMLXibDocument *document = [[NSXMLXibDocument alloc] initWithFileURL:selectedFileURL];
        [documents addObject:document];
    }
    
    BOOL exportAsSingleStoryboard = self.exportAsSingleStoryboardToggle.state == NSControlStateValueOn;
    if (exportAsSingleStoryboard) {
        NSXMLDocument *iosStoryboard = [NSXMLDocument storyboardFromDocuments:documents forPlatform:PlatformIOS];
        [iosStoryboard saveWithName:@"iOS_converted.storyboard" savePanelWindow:self.view.window];
        
        NSXMLDocument *tvosStoryboard = [NSXMLDocument storyboardFromDocuments:documents forPlatform:PlatformTVOS];
        [tvosStoryboard saveWithName:@"tvOS_converted.storyboard" savePanelWindow:self.view.window];
        return;
    }

    for (NSXMLXibDocument *document in documents) {
        NSString *outputURLString = [NSString stringWithFormat:@"%@.%@", [document.fileURL.absoluteString stringByDeletingPathExtension], @"storyboard"];
        NSURL *outputURL = [NSURL URLWithString:outputURLString];
        
        NSXMLDocument *iosStoryboard = [NSXMLDocument storyboardFromDocuments:@[document] forPlatform:PlatformIOS];
        [iosStoryboard saveForURL:outputURL];
        
        NSXMLDocument *tvosStoryboard = [NSXMLDocument storyboardFromDocuments:@[document] forPlatform:PlatformTVOS];
        [tvosStoryboard saveForURL:outputURL];
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

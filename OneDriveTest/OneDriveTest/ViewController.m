//
//  ViewController.m
//  OneDriveTest
//
//  Created by nl on 15/12/25.
//  Copyright © 2015年 nenglong. All rights reserved.
//


#import "ViewController.h"
#import <OneDriveSDK/OneDriveSDK.h>
#import "ODXTextViewController.h"
#import "ODXActionController.h"
#import "ODXProgressViewController.h"
#import "loginViewController.h"
#import "twoController.h"

@interface ViewController ()
@property NSMutableDictionary *thumbnails;

@property BOOL selection;

@property NSMutableArray *selectedItems;

@property UIRefreshControl *refreshControl;

@property UIBarButtonItem *actions;

@property ODXProgressViewController *progressController;

@property (nonatomic , strong) twoController *login;

@end

@implementation ViewController

- (twoController *)login{
    
    if (_login == nil) {
        _login = [[twoController alloc] init];
    }
    return _login;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.itemsLookup = [NSMutableArray array];
    self.items = [NSMutableDictionary dictionary];
    
    
    
    if (!self.currentItem){
        self.title = @"yangfeng";
    }
    
    
    
    
    
}

- (IBAction)signIN:(id)sender {
    
    [ODClient authenticatedClientWithCompletion:^(ODClient *client, NSError *error){
        if (!error){
            self.client = client;
            
            [self loadChildren];
            
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                //                self.navigationItem.rightBarButtonItem = self.actions;
                //                twoController *loginView = [[twoController alloc] init];
                //                [self.navigationController pushViewController:loginView animated:YES];
                
            });
            
        }
        else{
            [self showErrorAlert:error];
        }
    }];
    
    
}

- (void)loadChildren
{
    NSString *itemId = (self.currentItem) ? self.currentItem.id : @"root";
    ODChildrenCollectionRequest *childrenRequest = [[[[self.client drive] items:itemId] children] request];
    if (![self.client serviceFlags][@"NoThumbnails"]){
        [childrenRequest expand:@"thumbnails"];
    }
    [self loadChildrenWithRequest:childrenRequest];
}

- (void)loadChildrenWithRequest:(ODChildrenCollectionRequest*)childrenRequests
{
    [childrenRequests getWithCompletion:^(ODCollection *response, ODChildrenCollectionRequest *nextRequest, NSError *error){
        if (!error){
            self.login = [[twoController alloc] init];
            
            self.login.itemsLookup = self.itemsLookup;
            self.login.items = self.items;
            
            if (response.value){
                
                [self onLoadedChildren:response.value];
            }
            if (nextRequest){
                [self loadChildrenWithRequest:nextRequest];
            }
        }
        else if ([error isAuthenticationError]){
            [self showErrorAlert:error];
            [self onLoadedChildren:@[]];
        }
    }];
}

- (void)onLoadedChildren:(NSArray *)children
{
    if (self.refreshControl.isRefreshing){
        [self.refreshControl endRefreshing];
    }
    [children enumerateObjectsUsingBlock:^(ODItem *item, NSUInteger index, BOOL *stop){
        if (![self.itemsLookup containsObject:item.id]){
            [self.itemsLookup addObject:item.id];
        }
        self.items[item.id] = item;
    }];
    [self loadThumbnails:children];
    dispatch_async(dispatch_get_main_queue(), ^(){
        //        [self.collectionView reloadData];
        [self.login.tableView reloadData];
        
        [self.navigationController pushViewController:self.login animated:YES];
        
    });
}

- (void)loadThumbnails:(NSArray *)items{
    for (ODItem *item in items){
        if ([item thumbnails:0]){
            [[[[[[self.client drive] items:item.id] thumbnails:@"0"] small] contentRequest] downloadWithCompletion:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (!error){
                    self.thumbnails[item.id] = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
                    dispatch_async(dispatch_get_main_queue(), ^(){
                        //                        [self.collectionView reloadData];
                        [self.login.tableView reloadData];
                        [self.navigationController pushViewController:self.login animated:YES];
                        
                        
                    });
                }
            }];
        }
    }
}

//
//- (ODItem *)itemForIndex:(NSIndexPath *)indexPath
//{
//    NSString *itemId = self.itemsLookup[indexPath.row];
//    return self.items[itemId];
//}
//
//#pragma mark CollectionView Methods
//
//- (ODXItemCollectionViewController *)collectionViewWithItem:(ODItem *)item;
//{
//    ODXItemCollectionViewController *newController = [self.storyboard instantiateViewControllerWithIdentifier:self.storyBoardId];
//    newController.title = item.name;
//    newController.currentItem = item;
//    newController.client = self.client;
//    return newController;
//}
//
//-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
//{
//    return 1;
//}
//
//-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//{
//    return [self.itemsLookup count];
//}
//
//-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    __block ODItem *item = [self itemForIndex:indexPath];
//    if (item.folder){
//        dispatch_async(dispatch_get_main_queue(), ^(){
//            [self.navigationController pushViewController:[self collectionViewWithItem:item] animated:YES];
//        });
//    }
//    else if (self.selection){
//        if ([self.selectedItems containsObject:item]){
//            [self.selectedItems removeObject:item];
//        }
//        else{
//            [self.selectedItems addObject:item];
//        }
//        [self.collectionView reloadData];
//    }
//    else if ([item.file.mimeType isEqualToString:@"text/plain"]){
//        ODURLSessionDownloadTask *task = [[[[self.client drive] items:item.id] contentRequest] downloadWithCompletion:^(NSURL *filePath, NSURLResponse *response, NSError *error){
//            [self.progressController hideProgress];
//            if (!error){
//                NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//                NSString *newFilePath = [documentPath stringByAppendingPathComponent:item.name];
//                [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:[NSURL fileURLWithPath:newFilePath] error:nil];
//                ODXTextViewController *newController = [self.storyboard instantiateViewControllerWithIdentifier:@"FileViewController"];
//                [newController setItemSaveCompletion:^(ODItem *newItem){
//                    if (newItem){
//                        if (![self.itemsLookup containsObject:newItem.id]){
//                            [self.itemsLookup addObject:newItem.id];
//                        }
//                        self.items[newItem.id] = newItem;
//                        dispatch_async(dispatch_get_main_queue(), ^(){
//                            [self.collectionView reloadData];
//                        });
//                    }
//                }];
//                newController.title = item.name;
//                newController.item = item;
//                newController.client = self.client;
//                newController.filePath = newFilePath;
//                dispatch_async(dispatch_get_main_queue(), ^(){
//                    [super.navigationController pushViewController:newController animated:YES];
//                });
//            }
//            else{
//                [self showErrorAlert:error];
//                [self.selectedItems removeObject:item];
//            }
//        }];
//        [self.progressController showProgressWithTitle:[NSString stringWithFormat:@"Downloading %@", item.name] progress:task.progress];
//    }
//}
//
//-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    ODItem *item = [self itemForIndex:indexPath];
//
//    ODXItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
//    UIView *bgColorView = [[UIView alloc] init];
//    // Reset the old image
//    cell.imageView.image = nil;
//    cell.backgroundColor = [UIColor blackColor];
//    cell.label.textColor = [UIColor whiteColor];
//    cell.label.backgroundColor = [UIColor clearColor];
//    [cell.label setText:item.name];
//
//    if (self.selection && [self.selectedItems containsObject:item]){
//        cell.selected = YES;
//    }
//    if (self.thumbnails[item.id]){
//        UIImage *image = self.thumbnails[item.id];
//        cell.imageView.image = image;
//    }
//
//    bgColorView.backgroundColor = [UIColor grayColor];
//    [cell setSelectedBackgroundView:bgColorView];
//
//    if (item.folder){
//        cell.backgroundColor = [UIColor blueColor];
//    }
//    return cell;
//}
//
//
//#pragma mark Action Methods
//
//- (IBAction)didSelectActionButton:(UIBarButtonItem*)actionButton
//{
//    if (self.selection){
//        [self showSelectionActionViewWithButton:actionButton];
//    }
//    else{
//        [self showFolderActionViewWithButtonSource:actionButton];
//    }
//}
//
//
//- (void)showFolderActionViewWithButtonSource:(UIBarButtonItem*)buttonSource
//{
//    UIAlertController *folderActions = [UIAlertController alertControllerWithTitle:@"Folder Actions!"
//                                                                           message:nil
//                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
//
//    UIAlertAction *shareFolder = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Share %@",self.currentItem.name]
//                                                          style:UIAlertActionStyleDefault
//                                                        handler:^(UIAlertAction *action){
//                                                            [ODXActionController shareItem:self.currentItem withClient:self.client viewController:self completion:^(ODPermission *response, NSError *error){
//                                                                [self showShareLink:response.link.webUrl withError:error];
//                                                            }];
//                                                        }];
//
//    UIAlertAction *createFolder = [UIAlertAction actionWithTitle:@"New Folder"
//                                                           style:UIAlertActionStyleDefault
//                                                         handler:^(UIAlertAction *action){
//                                                             NSString *itemId = (self.currentItem) ? self.currentItem.id : @"root";
//                                                             [ODXActionController createNewFolderWithParentId:itemId client:self.client viewController:self completion:^(ODItem *item, NSError *error){
//                                                                 if(!error){
//                                                                     self.items[item.id] = item;
//                                                                     [self loadThumbnails:@[item]];
//                                                                     [self.collectionView reloadData];
//                                                                 }
//                                                                 else {
//                                                                     [self showErrorAlert:error];
//                                                                 }
//                                                             }];
//                                                         }];
//    UIAlertAction *createFile = [UIAlertAction actionWithTitle:@"Upload Text File" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
//        [ODXActionController createLocalPlainTextFileWithParent:self.currentItem client:self.client viewController:self];
//    }];
//
//
//
//
//    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
//
//    UIAlertAction *deleteFolder = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
//
//        [ODXActionController deleteItem:self.currentItem withClient:self.client viewController:self completion:^(NSError *error){
//            if (error){
//                [self showErrorAlert:error];
//            }
//            else{
//                dispatch_async(dispatch_get_main_queue(), ^(){
//                    [self.navigationController popViewControllerAnimated:YES];
//                });
//            }
//        }];
//    }];
//
//    UIAlertAction *selection = [UIAlertAction actionWithTitle:@"Select Stuff" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
//        self.selectedItems = [NSMutableArray array];
//        self.selection = YES;
//    }];
//
//    UIAlertAction *signOutAction = [UIAlertAction actionWithTitle:@"SignOut" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
//        [self signOutAction];
//    }];
//
//    [folderActions addAction:selection];
//    [folderActions addAction:shareFolder];
//    [folderActions addAction:createFolder];
//    [folderActions addAction:createFile];
//    [folderActions addAction:deleteFolder];
//    [folderActions addAction:signOutAction];
//    [folderActions addAction:cancel];
//    [folderActions popoverPresentationController].barButtonItem = buttonSource;
//    [self presentViewController:folderActions animated:YES completion:nil];
//}
//
//- (void)showSelectionActionViewWithButton:(UIBarButtonItem *)button
//{
//    UIAlertController *selectionActions = [UIAlertController alertControllerWithTitle:@"Item Actions!"
//                                                                              message:nil
//                                                                       preferredStyle:UIAlertControllerStyleActionSheet];
//
//    UIAlertAction *cancelSelectionAction = [UIAlertAction actionWithTitle:@"Stop Selecting" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
//        self.selection = NO;
//        self.selectedItems = nil;
//        [self.collectionView reloadData];
//    }];
//
//    UIAlertAction *moveAction = [UIAlertAction actionWithTitle:@"Move" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
//        if ([self.selectedItems count] != 1){
//            UIAlertController *failedAction = [UIAlertController alertControllerWithTitle:@"Don't do that" message:@"You can't move multiple items" preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
//
//            [failedAction addAction:ok];
//            dispatch_async(dispatch_get_main_queue(), ^(){
//                [self presentViewController:failedAction animated:YES completion:nil];
//            });
//        }
//        else{
//            [ODXActionController moveItem:self.selectedItems.firstObject withClient:self.client viewController:self completion:^(ODItem *response, NSError *error){
//                [self showMovedOrCopiedItem:response withError:error];
//            }];
//        }
//    }];
//
//    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
//        if ([self.selectedItems count] != 1){
//            UIAlertController *failedAction = [UIAlertController alertControllerWithTitle:@"Don't do that" message:@"You can't copy multiple items" preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
//
//            [failedAction addAction:ok];
//            dispatch_async(dispatch_get_main_queue(), ^(){
//                [self presentViewController:failedAction animated:YES completion:nil];
//            });
//        }
//        else {
//            [ODXActionController copyItem:self.selectedItems.firstObject withClient:self.client viewController:self completion:^(ODItem *item, ODAsyncOperationStatus *status, NSError *error){
//                if (item || error){
//                    [self showMovedOrCopiedItem:item withError:error];
//                }
//            }];
//        }
//    }];
//
//    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
//        if ([self.selectedItems count] != 1){
//            UIAlertController *failedAction = [UIAlertController alertControllerWithTitle:@"Don't do that" message:@"You can't copy multiple items" preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
//
//            [failedAction addAction:ok];
//            dispatch_async(dispatch_get_main_queue(), ^(){
//                [self presentViewController:failedAction animated:YES completion:nil];
//            });
//        }
//        else{
//            [ODXActionController renameItem:self.selectedItems.firstObject withClient:self.client viewController:self completion:^(ODItem *response, NSError *error){
//                ODItem *oldItem = self.selectedItems.firstObject;
//                [self showRenamedItem:oldItem.name newName:response.name error:error];
//            }];
//        }
//    }];
//
//
//    [selectionActions addAction:cancelSelectionAction];
//    [selectionActions addAction:moveAction];
//    [selectionActions addAction:copyAction];
//    [selectionActions addAction:renameAction];
//    [selectionActions popoverPresentationController].barButtonItem = button;
//    [self presentViewController:selectionActions animated:YES completion:nil];
//}
//
//
//#pragma mark Alert Methods
//
//- (void)showRenamedItem:(NSString *)oldName newName:(NSString *)newName error:(NSError *)error
//{
//    if (!error){
//        NSString *title = [NSString stringWithFormat:@"%@ renamed to %@", oldName, newName];
//        UIAlertController *renamedController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
//
//        [renamedController addAction:ok];
//        [self presentViewController:renamedController animated:YES completion:nil];
//    }
//    else{
//        [self showErrorAlert:error];
//    }
//}
//
//- (void)showShareLink:(NSString *)link withError:(NSError *)error
//{
//    if (!error){
//        UIAlertController *shareController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@" %@ sharing link", self.currentItem.name]
//                                                                                 message:link
//                                                                          preferredStyle:UIAlertControllerStyleAlert];
//        [shareController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
//        [self presentViewController:shareController animated:YES completion:nil];
//    }
//    else{
//        [self showErrorAlert:error];
//    }
//}
//
//- (void)showMovedOrCopiedItem:(ODItem*)item withError:(NSError *)error
//{
//    if (error){
//        [self showErrorAlert:error];
//    }
//    else {
//        ODItem *oldItem = self.items[item.id];
//        if (oldItem && ![oldItem.parentReference.path isEqualToString:item.parentReference.path]){
//            [self.items removeObjectForKey:item.id];
//            [self.itemsLookup removeObject:item.id];
//        }
//        NSString *message = [NSString stringWithFormat:@"%@ now at %@", item.name, item.parentReference.path];
//        UIAlertController *success = [UIAlertController alertControllerWithTitle:message message:@"Nice!" preferredStyle:UIAlertControllerStyleAlert];
//        [success addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}]];
//        [self presentViewController:success animated:YES completion:nil];
//    }
//}

- (void)showErrorAlert:(NSError*)error
{
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"There was an Error!"
                                                                        message:[NSString stringWithFormat:@"%@", error]
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
    [errorAlert addAction:ok];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:errorAlert animated:YES completion:nil];
    });
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

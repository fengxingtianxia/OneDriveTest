//
//  ViewController.h
//  OneDriveTest
//
//  Created by nl on 15/12/25.
//  Copyright © 2015年 nenglong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OneDriveSDK/OneDriveSDK.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) ODClient *client;

@property (assign, nonatomic) NSInteger num;

@property (strong, nonatomic) ODItem *currentItem;

@property NSMutableArray *itemsLookup;

@property NSMutableDictionary *items;



@end


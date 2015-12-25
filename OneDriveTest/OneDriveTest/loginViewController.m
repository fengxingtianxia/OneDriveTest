//
//  loginViewController.m
//  twoTEST
//
//  Created by nl on 15/12/15.
//  Copyright © 2015年 nenglong. All rights reserved.
//

#import "loginViewController.h"
#import "ODItem.h"

@interface loginViewController ()

@end

@implementation loginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (ODItem *)itemForIndex:(NSIndexPath *)indexPath
{
    NSString *itemId = self.itemsLookup[indexPath.row];
    return self.items[itemId];
}

- (void)setItems:(NSMutableDictionary *)items{

    _items = items;
}

- (void)setItemsLookup:(NSMutableArray *)itemsLookup{

    _itemsLookup = itemsLookup;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{


    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return _itemsLookup.count;

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    NSString *itemId = self.itemsLookup[indexPath.row];
    cell.textLabel.text = self.items[itemId];
    
    return cell;
}

@end

//
//  EighthViewController.h
//  MultiThread
//
//  Created by rimi on 15/7/17.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EighthViewController : UIViewController

#warning 使用原子属性atomic
@property (atomic,strong) NSMutableArray *imageNames;

@end

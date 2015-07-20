//
//  KCImageData.h
//  MultiThread
//
//  Created by rimi on 15/7/16.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCImageData : NSObject

#pragma mark 索引
@property (nonatomic,assign) int index;

#pragma mark 图片数据
@property (nonatomic,strong) NSData *data;

@end

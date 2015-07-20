//
//  MultiThreadViewController.m
//  MultiThread
//
//  Created by rimi on 15/7/16.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//  https://github.com/LeeSefung/NSThreadAndGCD.git
//

/*
 
 NSThread是轻量级的多线程开发，使用起来也并不复杂，但是使用NSThread需要自己管理线程生命周期。可以使用对象方法
 + (void)detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(id)argument
 直接将操作添加到线程中并启动，也可以使用对象方法
 - (instancetype)initWithTarget:(id)target selector:(SEL)selector object:(id)argument 
 创建一个线程对象，然后调用start方法启动线程。
 
 */

/*
 
 这个例子开辟线程下载图片，图片下载完成后再回到主线程显示图片。
 注意：1.开辟线程下载图片
      2.下载图片时，最好在运行池中（对于多线程操作建议把线程操作放到@autoreleasepool中）
      3.将数据显示到UI控件,注意只能在主线程中更新UI
 
 */

#import "FirstViewController.h"

@interface FirstViewController () {
    
    UIImageView *_imageView;
}


@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutUI];
}

#pragma mark 界面布局
-(void)layoutUI{
    _imageView =[[UIImageView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];
    _imageView.contentMode=UIViewContentModeScaleAspectFit;
    [self.view addSubview:_imageView];
    
    UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame=CGRectMake(0, 40, 375, 25);
    button.backgroundColor = [UIColor orangeColor];
    [button setTitle:@"加载图片" forState:UIControlStateNormal];
    //添加方法
    [button addTarget:self action:@selector(loadImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

#pragma mark 多线程下载图片
-(void)loadImageWithMultiThread{
    //方法1：使用对象方法
    //创建一个线程，第一个参数是请求的操作，第二个参数是操作方法的参数
    //    NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(loadImage) object:nil];
    //    //启动一个线程，注意启动一个线程并非就一定立即执行，而是处于就绪状态，当系统调度时才真正执行
    //    [thread start];
    
    //方法2：使用类方法
    [NSThread detachNewThreadSelector:@selector(loadImage) toTarget:self withObject:nil];
}

#pragma mark 加载图片
-(void)loadImage{
    //请求数据
    NSData *data= [self requestData];
    /*将数据显示到UI控件,注意只能在主线程中更新UI,
     另外performSelectorOnMainThread方法是NSObject的分类方法，每个NSObject对象都有此方法，
     它调用的selector方法是当前调用控件的方法，例如使用UIImageView调用的时候selector就是UIImageView的方法
     Object：代表调用方法的参数,不过只能传递一个参数(如果有多个参数请使用对象进行封装)
     waitUntilDone:是否线程任务完成执行
     */
    [self performSelectorOnMainThread:@selector(updateImage:) withObject:data waitUntilDone:YES];
}

#pragma mark 请求图片数据
-(NSData *)requestData{
    //对于多线程操作建议把线程操作放到@autoreleasepool中
    @autoreleasepool {
        NSURL *url=[NSURL URLWithString:@"http://img4.douban.com/view/photo/photo/public/p1910830216.jpg"];
        NSData *data=[NSData dataWithContentsOfURL:url];
        return data;
    }
}

#pragma mark 将图片显示到界面
-(void)updateImage:(NSData *)imageData{
    UIImage *image=[UIImage imageWithData:imageData];
    _imageView.image=image;
}

@end

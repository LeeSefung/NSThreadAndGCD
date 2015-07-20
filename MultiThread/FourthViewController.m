//
//  MultiThread_GCDViewController.m
//  MultiThread
//
//  Created by rimi on 15/7/16.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//  https://github.com/LeeSefung/NSThreadAndGCD.git
//

#import "FourthViewController.h"
#import "KCImageData.h"
#define ROW_COUNT 3
#define COLUMN_COUNT 3
#define ROW_HEIGHT 355/3.0*444/300
#define ROW_WIDTH 355/3.0
#define CELL_SPACING 5

@interface FourthViewController () {
    
    NSMutableArray *_imageViews;
    NSMutableArray *_imageNames;
}

@end

@implementation FourthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self layoutUI];
}

#pragma mark 界面布局
- (void)layoutUI{
    
    //创建多个图片控件用于显示图片
    _imageViews=[NSMutableArray array];
    for (int r=0; r<ROW_COUNT; r++) {
        for (int c=0; c<COLUMN_COUNT; c++) {
            
            UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(c*ROW_WIDTH+(c*CELL_SPACING), 20+r*ROW_HEIGHT+(r*CELL_SPACING), ROW_WIDTH, ROW_HEIGHT)];
            imageView.contentMode=UIViewContentModeScaleAspectFit;
            [self.view addSubview:imageView];
            [_imageViews addObject:imageView];
            
        }
    }
    
    UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame=CGRectMake(0, 667-64-25-5, 375, 25);
    [button setTitle:@"加载图片" forState:UIControlStateNormal];
    //添加方法
    [button addTarget:self action:@selector(loadImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    //创建图片链接
    _imageNames=[NSMutableArray array];
    for (int i=0; i<9; i++) {
        [_imageNames addObject:[NSString stringWithFormat:@"http://images.cnblogs.com/cnblogs_com/kenshincui/613474/o_%i.jpg",i]];
    }
}

#warning NSBlockOperation
//1.创建操作队列
//2.向操作队列中添加NSBlockOperation代码块

#pragma mark 多线程下载图片（没有优先级）
//- (void)loadImageWithMultiThread{
//    
//    int count=ROW_COUNT*COLUMN_COUNT;
//    //创建操作队列
//    NSOperationQueue *operationQueue = [[NSOperationQueue alloc]init];
//    operationQueue.maxConcurrentOperationCount = 5;//设置最大并发线程数
//    //创建多个线程用于填充图片
//    for (int i=0; i<count; ++i) {
//        
//        //方法1：创建操作块添加到队列
//        //        //创建多线程操作
//        //        NSBlockOperation *blockOperation=[NSBlockOperation blockOperationWithBlock:^{
//        //            [self loadImage:[NSNumber numberWithInt:i]];
//        //        }];
//        //        //创建操作队列
//        //
//        //        [operationQueue addOperation:blockOperation];
//        
//        //方法2：直接使用操队列添加操作
//        [operationQueue addOperationWithBlock:^{
//            [self loadImage:[NSNumber numberWithInt:i]];
//        }];
//    }
//}

#warning 线程执行顺序
/*
 
 前面使用NSThread很难控制线程的执行顺序，但是使用NSOperation就容易多了，每个NSOperation可以设置依赖线程。假设操作A依赖于操作B，线程操作队列在启动线程时就会首先执行B操作，然后执行A。对于前面优先加载最后一张图的需求，只要设置前面的线程操作的依赖线程为最后一个操作即可。
 
 */

#pragma mark 多线程下载图片（具有优先级）
//优先执行最后一个线程（优先添加最后一张图片）
//设置依赖：（前者依赖后者）[blockOperation addDependency:lastBlockOperation];
- (void)loadImageWithMultiThread{
    
    int count=ROW_COUNT*COLUMN_COUNT;
    //创建操作队列
    NSOperationQueue *operationQueue=[[NSOperationQueue alloc]init];
    operationQueue.maxConcurrentOperationCount=5;//设置最大并发线程数
    
    NSBlockOperation *lastBlockOperation=[NSBlockOperation blockOperationWithBlock:^{
        [self loadImage:[NSNumber numberWithInt:(count-1)]];
    }];
    //创建多个线程用于填充图片
    for (int i=0; i<count-1; ++i) {
        //方法1：创建操作块添加到队列
        //创建多线程操作
        NSBlockOperation *blockOperation=[NSBlockOperation blockOperationWithBlock:^{
            [self loadImage:[NSNumber numberWithInt:i]];
        }];
        //设置依赖操作为最后一张图片加载操作
        [blockOperation addDependency:lastBlockOperation];
        
        [operationQueue addOperation:blockOperation];
        
    }
    //将最后一个图片的加载操作加入线程队列
    [operationQueue addOperation:lastBlockOperation];
}

/*
 
 可以看到虽然加载最后一张图片的操作最后被加入到操作队列，但是它却是被第一个执行的。操作依赖关系可以设置多个，例如A依赖于B、B依赖于C…但是千万不要设置为循环依赖关系（例如A依赖于B，B依赖于C，C又依赖于A），否则是不会被执行的。
 
 */

#pragma mark 加载图片
- (void)loadImage:(NSNumber *)index{
    
    int i = [index intValue];
    
    //请求数据
    NSData *data= [self requestData:i];
    NSLog(@"%@",[NSThread currentThread]);
    //更新UI界面,此处调用了主线程队列的方法（mainQueue是UI主线程）
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [self updateImageWithData:data andIndex:i];
    }];
}

#pragma mark 请求图片数据
- (NSData *)requestData:(int )index{
    
    //对于多线程操作建议把线程操作放到@autoreleasepool中
    @autoreleasepool {
        
        NSURL *url=[NSURL URLWithString:_imageNames[index]];
        NSData *data=[NSData dataWithContentsOfURL:url];
        return data;
    }
}

#pragma mark 将图片显示到界面
- (void)updateImageWithData:(NSData *)data andIndex:(int )index{
    
    UIImage *image=[UIImage imageWithData:data];
    UIImageView *imageView= _imageViews[index];
    imageView.image=image;
}

@end

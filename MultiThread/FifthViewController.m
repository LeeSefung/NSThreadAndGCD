//
//  MultiThread_LockViewController.m
//  MultiThread
//
//  Created by rimi on 15/7/16.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//  https://github.com/LeeSefung/NSThreadAndGCD.git
//

/*
 
 GCD(Grand Central Dispatch)是基于C语言开发的一套多线程开发机制，也是目前苹果官方推荐的多线程开发方法。前面也说过三种开发中GCD抽象层次最高，当然是用起来也最简单，只是它基于C语言开发，并不像NSOperation是面向对象的开发，而是完全面向过程的。对于熟悉C#异步调用的朋友对于GCD学习起来应该很快，因为它与C#中的异步调用基本是一样的。这种机制相比较于前面两种多线程开发方式最显著的优点就是它对于多核运算更加有效。
 
 GCD中也有一个类似于NSOperationQueue的队列，GCD统一管理整个队列中的任务。但是GCD中的队列分为并行队列和串行队列两类：
 
 串行队列：只有一个线程，加入到队列中的操作按添加顺序依次执行。
 并发队列：有多个线程，操作进来之后它会将这些队列安排在可用的处理器上，同时保证先进来的任务优先处理。
 其实在GCD中还有一个特殊队列就是主队列，用来执行主线程上的操作任务（从前面的演示中可以看到其实在NSOperation中也有一个主队列）。
 
 */

/*
 
 使用串行队列时首先要创建一个串行队列，然后调用异步调用方法，在此方法中传入串行队列和线程操作即可自动执行。下面使用线程队列演示图片的加载过程，你会发现多张图片会按顺序加载，因为当前队列中只有一个线程。
 
 */

/*
 
 并发队列同样是使用dispatch_queue_create()方法创建，只是最后一个参数指定为DISPATCH_QUEUE_CONCURRENT进行创建，但是在实际开发中我们通常不会重新创建一个并发队列而是使用dispatch_get_global_queue()方法取得一个全局的并发队列（当然如果有多个并发队列可以使用前者创建）。
 
 */

#import "FifthViewController.h"
#import "KCImageData.h"
#define ROW_COUNT 3
#define COLUMN_COUNT 3
#define ROW_HEIGHT 355/3.0*444/300
#define ROW_WIDTH 355/3.0
#define CELL_SPACING 5

@interface FifthViewController () {
    
    NSMutableArray *_imageViews;
    NSMutableArray *_imageNames;
}

@end

@implementation FifthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self layoutUI];
}

#pragma mark 界面布局
- (void)layoutUI {
    
    //创建多个图片控件用于显示图片
    _imageViews=[NSMutableArray array];
    for (int r=0; r<ROW_COUNT; r++) {
        for (int c=0; c<COLUMN_COUNT; c++) {
            
            UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(c*ROW_WIDTH+(c*CELL_SPACING), 60+r*ROW_HEIGHT+(r*CELL_SPACING), ROW_WIDTH, ROW_HEIGHT)];
            imageView.contentMode=UIViewContentModeScaleAspectFit;
            //            imageView.backgroundColor=[UIColor redColor];
            [self.view addSubview:imageView];
            [_imageViews addObject:imageView];
        }
    }
    
    UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame=CGRectMake(0, 667-64-20, 375, 25);
    [button setTitle:@"加载图片" forState:UIControlStateNormal];
    //添加方法
    [button addTarget:self action:@selector(loadImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    //创建图片链接
    _imageNames=[NSMutableArray array];
    for (int i=0; i<ROW_COUNT*COLUMN_COUNT; i++) {
        
        [_imageNames addObject:[NSString stringWithFormat:@"http://images.cnblogs.com/cnblogs_com/kenshincui/613474/o_%i.jpg",i]];
    }
}

#warning GCD串行队列异步加载图片(图片顺序加载)
#pragma mark 多线程下载图片
//- (void)loadImageWithMultiThread {
//    
//    int count=ROW_COUNT*COLUMN_COUNT;
//    
//    /*创建一个串行队列
//     第一个参数：队列名称
//     第二个参数：队列类型
//     */
//    dispatch_queue_t serialQueue = dispatch_queue_create("myThreadQueue1", DISPATCH_QUEUE_SERIAL);//注意queue对象不是指针类型
//    //创建多个线程用于填充图片
//    for (int i=0; i<count; ++i) {
//        
//        //异步执行队列任务
//        dispatch_async(serialQueue, ^{
//            
//            [self loadImage:[NSNumber numberWithInt:i]];
//        });
//        
//    }
//    //非ARC环境请释放
//    //    dispatch_release(seriQueue);
//}

#warning GCD并发队列异步加载图片(图片无序加载,这才是真正的多线程）
#pragma mark 多线程下载图片
- (void)loadImageWithMultiThread {
    
    int count = ROW_COUNT*COLUMN_COUNT;
    
    /*取得全局队列（并发队列）
     第一个参数：线程优先级
     第二个参数：标记参数，目前没有用，一般传入0
     */
    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建多个线程用于填充图片
    for (int i=0; i<count; ++i) {
        
        //异步执行队列任务
        dispatch_async(globalQueue, ^{
            
            [self loadImage:[NSNumber numberWithInt:i]];
        });
    }
}

#warning GCD并发队列同步加载图片(同步加载容易造成线程阻塞)
/*
 
 可以看点击按钮后按钮无法再次点击，因为所有图片的加载全部在主线程中（可以打印线程查看），主线程被阻塞，造成图片最终是一次性显示。可以得出结论：
 
 在GDC中一个操作是多线程执行还是单线程执行取决于当前队列类型和执行方法，只有队列类型为并行队列并且使用异步方法执行时才能在多个线程中执行。
 串行队列可以按顺序执行，并行队列的异步方法无法确定执行顺序。
 UI界面的更新最好采用同步方法，其他操作采用异步方法。
 GCD中多线程操作方法不需要使用@autoreleasepool，GCD会管理内存。
 
 */
#pragma mark 多线程下载图片
//- (void)loadImageWithMultiThread {
//    
//    int count = ROW_COUNT*COLUMN_COUNT;
//    
//    /*取得全局队列（并发队列）
//     第一个参数：线程优先级
//     第二个参数：标记参数，目前没有用，一般传入0
//     */
//    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    //创建多个线程用于填充图片
//    for (int i=0; i<count; ++i) {
//        
//        //同步执行队列任务
//        dispatch_sync(globalQueue, ^{
//            
//            [self loadImage:[NSNumber numberWithInt:i]];
//        });
//    }
//}

#warning 结论

/*
 
 1.在GDC中一个操作是多线程执行还是单线程执行取决于当前队列类型和执行方法，只有队列类型为并行队列并且使用异步方法执行时才能在多个线程中执行。
 2.串行队列可以按顺序执行，并行队列的异步方法无法确定执行顺序。
 3.UI界面的更新最好采用同步方法，其他操作采用异步方法。
 4.GCD中多线程操作方法不需要使用@autoreleasepool，GCD会管理内存。
 
 */

#pragma mark 加载图片
- (void)loadImage:(NSNumber *)index {
    
    //如果在串行队列中会发现当前线程打印变化完全一样，因为他们在一个线程中
    NSLog(@"thread is :%@",[NSThread currentThread]);
    
    int i=[index intValue];
    //请求数据
    NSData *data= [self requestData:i];
    //更新UI界面,此处调用了GCD主线程队列的方法
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        
        [self updateImageWithData:data andIndex:i];
    });
}

#pragma mark 请求图片数据
- (NSData *)requestData:(int )index {
    
    NSURL *url=[NSURL URLWithString:_imageNames[index]];
    NSData *data=[NSData dataWithContentsOfURL:url];
    
    return data;
}

#pragma mark 将图片显示到界面
- (void)updateImageWithData:(NSData *)data andIndex:(int )index {
    
    UIImage *image = [UIImage imageWithData:data];
    UIImageView *imageView = _imageViews[index];
    imageView.image = image;
}

@end

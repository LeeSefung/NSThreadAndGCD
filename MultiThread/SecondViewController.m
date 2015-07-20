//
//  MultiThread_NSOperationViewController.m
//  MultiThread
//
//  Created by rimi on 15/7/16.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//  https://github.com/LeeSefung/NSThreadAndGCD.git
//

/*
 
 通过NSThread的currentThread可以取得当前操作的线程，其中会记录线程名称name和编号number，需要注意主线程编号永远为1。多个线程虽然按顺序启动，但是实际执行未必按照顺序加载照片（loadImage:方法未必依次创建，可以通过在loadImage:中打印索引查看），因为线程启动后仅仅处于就绪状态，实际是否执行要由CPU根据当前状态调度。
 
 从上面的运行效果大家不难发现，图片并未按顺序加载，原因有两个：第一，每个线程的实际执行顺序并不一定按顺序执行（虽然是按顺序启动）；第二，每个线程执行时实际网络状况很可能不一致。当然网络问题无法改变，只能尽可能让网速更快，但是可以改变线程的优先级，让15个线程优先执行某个线程。线程优先级范围为0~1，值越大优先级越高，每个线程的优先级默认为0.5。修改图片下载方法如下，改变最后一张图片加载的优先级，这样可以提高它被优先加载的几率，但是它也未必就第一个加载。因为首先其他线程是先启动的，其次网络状况我们没办法修改
 
 */

#import "SecondViewController.h"
#import "KCImageData.h"
#define ROW_COUNT 3
#define COLUMN_COUNT 3
#define ROW_HEIGHT 355/3.0*444/300
#define ROW_WIDTH 355/3.0
#define CELL_SPACING 5

@interface SecondViewController () {
    
    NSMutableArray *_imageViews;
}

@end

@implementation SecondViewController

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
            
            UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(5+c*ROW_WIDTH+(c*CELL_SPACING), 25+r*ROW_HEIGHT+(r*CELL_SPACING), ROW_WIDTH, ROW_HEIGHT)];
            imageView.contentMode=UIViewContentModeScaleAspectFit;
            [self.view addSubview:imageView];
            [_imageViews addObject:imageView];
        }
    }
    
    UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame=CGRectMake(0, 667-64-25-5, 375, 25);
    button.backgroundColor = [UIColor orangeColor];
    [button setTitle:@"加载图片" forState:UIControlStateNormal];
    //添加方法
    [button addTarget:self action:@selector(loadImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

#pragma mark 多线程下载图片
- (void)loadImageWithMultiThread{
    
    //创建多个线程用于填充图片
    for (int i=0; i<ROW_COUNT*COLUMN_COUNT; ++i) {
        
        //方法一：类方法
        //        [NSThread detachNewThreadSelector:@selector(loadImage:) toTarget:self withObject:[NSNumber numberWithInt:i]];
        //方法二：对象方法
        NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(loadImage:) object:[NSNumber numberWithInt:i]];
        thread.name=[NSString stringWithFormat:@"myThread%i",i];//设置线程名称
        [thread start];
    }
}

#pragma mark 加载图片
- (void)loadImage:(NSNumber *)index{
    
    //    NSLog(@"%i",i);
    //currentThread方法可以取得当前操作线程
    NSLog(@"current thread:%@",[NSThread currentThread]);
    
    int i = [index intValue];
    
    //    NSLog(@"%i",i);//未必按顺序输出
    
    NSData *data = [self requestData:i];
    
    KCImageData *imageData = [[KCImageData alloc]init];
    imageData.index = i;
    imageData.data = data;
    [self performSelectorOnMainThread:@selector(updateImage:) withObject:imageData waitUntilDone:YES];
}

#pragma mark 请求图片数据
- (NSData *)requestData:(int )index{
    
    //对于多线程操作建议把线程操作放到@autoreleasepool中
    @autoreleasepool {
        
        NSURL *url=[NSURL URLWithString:@"http://img4.douban.com/view/photo/photo/public/p1910830216.jpg"];
        NSData *data=[NSData dataWithContentsOfURL:url];
        return data;
    }
}

#pragma mark 将图片显示到界面
- (void)updateImage:(KCImageData *)imageData{
    
    UIImage *image=[UIImage imageWithData:imageData.data];
    UIImageView *imageView= _imageViews[imageData.index];
    imageView.image = image;
}


#warning 修改线程的优先级、延迟

/*
 
 从上面的运行效果大家不难发现，图片并未按顺序加载，原因有两个：第一，每个线程的实际执行顺序并不一定按顺序执行（虽然是按顺序启动）；第二，每个线程执行时实际网络状况很可能不一致。当然网络问题无法改变，只能尽可能让网速更快，但是可以改变线程的优先级，让15个线程优先执行某个线程。线程优先级范围为0~1，值越大优先级越高，每个线程的优先级默认为0.5。修改图片下载方法如下，改变最后一张图片加载的优先级，这样可以提高它被优先加载的几率，但是它也未必就第一个加载。因为首先其他线程是先启动的，其次网络状况我们没办法修改
 
 */

#pragma mark - 修改优先级
//- (void)loadImageWithMultiThread{
//    
//    NSMutableArray *threads=[NSMutableArray array];
//    int count=ROW_COUNT*COLUMN_COUNT;
//    //创建多个线程用于填充图片
//    for (int i=0; i<count; ++i) {
//        //        [NSThread detachNewThreadSelector:@selector(loadImage:) toTarget:self withObject:[NSNumber numberWithInt:i]];
//        NSThread *thread=[[NSThread alloc]initWithTarget:self selector:@selector(loadImage:) object:[NSNumber numberWithInt:i]];
//        thread.name=[NSString stringWithFormat:@"myThread%i",i];//设置线程名称
//        if(i==(count-1)){
//            thread.threadPriority=1.0;
//        }else{
//            thread.threadPriority=0.0;
//        }
//        [threads addObject:thread];
//    }
//    
//    for (int i=0; i<count; i++) {
//        NSThread *thread=threads[i];
//        [thread start];
//    }
//}

/*
 
 在线程操作过程中可以让某个线程休眠等待，优先执行其他线程操作，而且在这个过程中还可以修改某个线程的状态或者终止某个指定线程。为了解决上面优先加载最后一张图片的问题，不妨让其他线程先休眠一会等待最后一个线程执行。
 
 */

#pragma mark - 延迟执行线程
//- (NSData *)requestData:(int )index{
//    
//    //对于多线程操作建议把线程操作放到@autoreleasepool中
//    @autoreleasepool {
//        //对非最后一张图片加载线程休眠2秒
//        if (index!=(ROW_COUNT*COLUMN_COUNT-1)) {
//            [NSThread sleepForTimeInterval:2.0];
//        }
//        NSURL *url=[NSURL URLWithString:_imageNames[index]];
//        NSData *data=[NSData dataWithContentsOfURL:url];
//        
//        return data;
//    }
//}

#warning 扩展（停止当前线程）

/*
 
 线程状态分为isExecuting（正在执行）、isFinished（已经完成）、isCancellled（已经取消）三种。其中取消状态程序可以干预设置，只要调用线程的cancel方法即可。但是需要注意在主线程中仅仅能设置线程状态，并不能真正停止当前线程，如果要终止线程必须在线程中调用exist方法，这是一个静态方法，调用该方法可以退出当前线程。
 
 */

//currentThread获取当前线程的线程（单个）NSThread *currentThread=[NSThread currentThread];
//isFinished:判断线程是否完成
//cancel:注意设置为取消状态仅仅是改变了线程状态而言，并不能终止线程
//isCancelled:判断当前线程处于取消状态
//exit:取消当前线程


@end



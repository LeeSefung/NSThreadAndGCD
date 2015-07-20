//
//  SixthViewController.m
//  MultiThread
//
//  Created by rimi on 15/7/17.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//  https://github.com/LeeSefung/NSThreadAndGCD.git
//

/*
 
 线程同步
 
 说到多线程就不得不提多线程中的锁机制，多线程操作过程中往往多个线程是并发执行的，同一个资源可能被多个线程同时访问，造成资源抢夺，这个过程中如果没有锁机制往往会造成重大问题。举例来说，每年春节都是一票难求，在12306买票的过程中，成百上千的票瞬间就消失了。不妨假设某辆车有1千张票，同时有几万人在抢这列车的车票，顺利的话前面的人都能买到票。但是如果现在只剩下一张票了，而同时还有几千人在购买这张票，虽然在进入购票环节的时候会判断当前票数，但是当前已经有100个线程进入购票的环节，每个线程处理完票数都会减1,100个线程执行完当前票数为-99，遇到这种情况很明显是不允许的。
 
 要解决资源抢夺问题在iOS中有常用的有两种方法：一种是使用NSLock同步锁，另一种是使用@synchronized代码块。两种方法实现原理是类似的，只是在处理上代码块使用起来更加简单（C#中也有类似的处理机制synchronized和lock）。
 
 这里不妨还拿图片加载来举例，假设现在有9张图片，但是有9个线程都准备加载这9张图片，约定不能重复加载同一张图片，这样就形成了一个资源抢夺的情况。在下面的程序中将创建9张图片，每次读取照片链接时首先判断当前链接数是否大于1，用完一个则立即移除，最多只有6个。
 在使用同步方法之前先来看一下错误的写法：
 
 */

#warning Bug 此处对按钮点击事件没做处理，导致增加了出现超过6张图片的概率的三个原因之一。

#import "SixthViewController.h"
#import "KCImageData.h"
#define ROW_COUNT 3
#define COLUMN_COUNT 3
#define ROW_HEIGHT 355/3.0*444/300
#define ROW_WIDTH 355/3.0
#define CELL_SPACING 5

@interface SixthViewController () {
    
    NSMutableArray *_imageViews;
    NSMutableArray *_imageNames;
}

@end

@implementation SixthViewController

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
}

#pragma mark 多线程下载图片
- (void)loadImageWithMultiThread {
    
    //创建图片链接
    _imageNames=[NSMutableArray array];
    for (int i=0; i<6; i++) {
        
        [_imageNames addObject:[NSString stringWithFormat:@"http://images.cnblogs.com/cnblogs_com/kenshincui/613474/o_%i.jpg",i]];
    }
    
    int count=ROW_COUNT*COLUMN_COUNT;
    
    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建多个线程用于填充图片
    for (int i=0; i<count; ++i) {
        
        //异步执行队列任务
        dispatch_async(globalQueue, ^{
            
            [self loadImage:[NSNumber numberWithInt:i]];
        });
    }
}

#pragma mark 加载图片
- (void)loadImage:(NSNumber *)index {
    
    int i=[index intValue];
    //请求数据
    NSData *data= [self requestData:i];
    //更新UI界面,此处调用了GCD主线程队列的方法
    dispatch_queue_t mainQueue= dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        
        [self updateImageWithData:data andIndex:i];
    });
}

#pragma mark 请求图片数据
- (NSData *)requestData:(int )index {
    
    NSData *data;
    NSString *name;
    if (_imageNames.count>0) {
        
        name=[_imageNames lastObject];
        [_imageNames removeObject:name];
    }
    if(name){
        
        NSURL *url=[NSURL URLWithString:name];
        data=[NSData dataWithContentsOfURL:url];
    }
    return data;
}

#pragma mark 将图片显示到界面
- (void)updateImageWithData:(NSData *)data andIndex:(int )index {
    
    UIImage *image=[UIImage imageWithData:data];
    UIImageView *imageView= _imageViews[index];
    imageView.image = image;
}

#warning 结果
/*
 
 上面这个结果不一定每次都出现，关键要看从_imageNames读取链接、删除链接的速度，如果足够快可能不会有任何问题，但是如果速度稍慢就会出现上面的情况，很明显上面情况并不满足前面的需求。

 */
#warning 结论
/*
 
 分析这个问题造成的原因主：当一个线程A已经开始获取图片链接，获取完之后还没有来得及从_imageNames中删除，另一个线程B已经进入相应代码中，由于每次读取的都是_imageNames的最后一个元素，因此后面的线程其实和前面线程取得的是同一个图片链接这样就造成图中看到的情况。要解决这个问题，只要保证线程A进入相应代码之后B无法进入，只有等待A完成相关操作之后B才能进入即可。下面分别使用NSLock和@synchronized对代码进行修改。
 
 */

@end

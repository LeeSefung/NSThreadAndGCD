//
//  TenthViewController.m
//  MultiThread
//
//  Created by rimi on 15/7/20.
//  Copyright (c) 2015年 LeeSefung. All rights reserved.
//  https://github.com/LeeSefung/NSThreadAndGCD.git
//

/*
 
 扩展--控制线程通信
 
 由于线程的调度是透明的，程序有时候很难对它进行有效的控制，为了解决这个问题iOS提供了NSCondition来控制线程通信(同前面GCD的信号机制类似)。NSCondition实现了NSLocking协议，所以它本身也有lock和unlock方法，因此也可以将它作为NSLock解决线程同步问题，此时使用方法跟NSLock没有区别，只要在线程开始时加锁，取得资源后释放锁即可，这部分内容比较简单在此不再演示。当然，单纯解决线程同步问题不是NSCondition设计的主要目的，NSCondition更重要的是解决线程之间的调度关系（当然，这个过程中也必须先加锁、解锁）。NSCondition可以调用wati方法控制某个线程处于等待状态，直到其他线程调用signal（此方法唤醒一个线程，如果有多个线程在等待则任意唤醒一个）或者broadcast（此方法会唤醒所有等待线程）方法唤醒该线程才能继续。
 
 假设当前imageNames没有任何图片，而整个界面能够加载9张图片（每张都不能重复），现在创建9个线程分别从imageNames中取图片加载到界面中。由于imageNames中没有任何图片，那么9个线程都处于等待状态，只有当调用图片创建方法往imageNames中添加图片后（每次创建一个）并且唤醒其他线程（这里只唤醒一个线程）才能继续执行加载图片。如此，每次创建一个图片就会唤醒一个线程去加载，这个过程其实就是一个典型的生产者-消费者模式。下面通过NSCondition实现这个流程的控制：
 
 */

#import "TenthViewController.h"
#import "KCImageData.h"
#define ROW_COUNT 3
#define COLUMN_COUNT 3
#define ROW_HEIGHT 355/3.0*444/300
#define ROW_WIDTH 355/3.0
#define CELL_SPACING 5
#define IMAGE_COUNT 6

@interface TenthViewController () {
    
    NSMutableArray *_imageViews;
    NSCondition *_condition;
}

@end

@implementation TenthViewController

#pragma mark - 事件
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self layoutUI];
}

#pragma mark - 内部私有方法
#pragma mark 界面布局
- (void)layoutUI {
    
    //创建多个图片控件用于显示图片
    _imageViews=[NSMutableArray array];
    for (int r=0; r<ROW_COUNT; r++) {
        for (int c=0; c<COLUMN_COUNT; c++) {
            
            UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(c*ROW_WIDTH+(c*CELL_SPACING), 60+r*ROW_HEIGHT+(r*CELL_SPACING), ROW_WIDTH, ROW_HEIGHT)];
            imageView.contentMode=UIViewContentModeScaleAspectFit;
            [self.view addSubview:imageView];
            [_imageViews addObject:imageView];  
        }
    }
    
    UIButton *btnLoad=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnLoad.frame=CGRectMake(0, 667-64-20, 375/2, 25);
    [btnLoad setTitle:@"加载图片" forState:UIControlStateNormal];
    [btnLoad addTarget:self action:@selector(loadImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnLoad];
    
    UIButton *btnCreate=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnCreate.frame=CGRectMake(188, 667-64-20, 375/2, 25);
    [btnCreate setTitle:@"创建图片" forState:UIControlStateNormal];
    [btnCreate addTarget:self action:@selector(createImageWithMultiThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnCreate];
    
    //创建图片链接
    _imageNames=[NSMutableArray array];
    
#warning 初始化锁对象
    //初始化锁对象
    _condition=[[NSCondition alloc]init];
    
    _currentIndex=0;
    
}

#pragma mark - UI调用方法
#pragma mark 异步创建一张图片链接
- (void)createImageWithMultiThread {
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建图片链接
    dispatch_async(globalQueue, ^{
        
        [self createImageName];
    });
}

#warning 创建图片
#pragma mark 创建图片
- (void)createImageName {
    
    [_condition lock];
    //如果当前已经有图片了则不再创建，线程处于等待状态
    if (_imageNames.count>0) {
        
        NSLog(@"createImageName wait, current:%i",_currentIndex);
        [_condition wait];
    }else{
        
        NSLog(@"createImageName work, current:%i",_currentIndex);
        //生产者，每次生产1张图片
        [_imageNames addObject:[NSString stringWithFormat:@"http://images.cnblogs.com/cnblogs_com/kenshincui/613474/o_%i.jpg",_currentIndex++]];
        
        //创建完图片则发出信号唤醒其他等待线程
        [_condition signal];
    }
    [_condition unlock];
}

#pragma mark 多线程下载图片
- (void)loadImageWithMultiThread{
    
    int count=ROW_COUNT*COLUMN_COUNT;
    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    for (int i=0; i<count; ++i) {
        
        //加载图片
        dispatch_async(globalQueue, ^{
            
            [self loadImage:[NSNumber numberWithInt:i]];
        });
    }
}

#warning 加载图片
#pragma mark 加载图片
- (void)loadImage:(NSNumber *)index {
    
    int i=(int)[index integerValue];
    //加锁
    [_condition lock];
    //如果当前有图片资源则加载，否则等待
    if (_imageNames.count>0) {
        
        NSLog(@"loadImage work,index is %i",i);
        [self loadAnUpdateImageWithIndex:i];
        [_condition broadcast];
    }else{
        
        NSLog(@"loadImage wait,index is %i",i);
        NSLog(@"%@",[NSThread currentThread]);
        //线程等待
        [_condition wait];
        NSLog(@"loadImage resore,index is %i",i);
        //一旦创建完图片立即加载
        [self loadAnUpdateImageWithIndex:i];
    }
    //解锁
    [_condition unlock];
}

#pragma mark 加载图片并将图片显示到界面
- (void)loadAnUpdateImageWithIndex:(int )index {
    
    //请求数据
    NSData *data= [self requestData:index];
    //更新UI界面,此处调用了GCD主线程队列的方法
    dispatch_queue_t mainQueue= dispatch_get_main_queue();
    dispatch_sync(mainQueue, ^{
        
        UIImage *image=[UIImage imageWithData:data];
        UIImageView *imageView= _imageViews[index];
        imageView.image=image;
    });
}

#pragma mark 请求图片数据
- (NSData *)requestData:(int )index {
    
    NSData *data;
    NSString *name;
    name=[_imageNames lastObject];
    [_imageNames removeObject:name];
    if(name){
        
        NSURL *url=[NSURL URLWithString:name];
        data=[NSData dataWithContentsOfURL:url];
    }
    return data;
}

#warning 结论()
/*
 
 在上面的代码中loadImage:方法是消费者，当在界面中点击“加载图片”后就创建了9个消费者线程。在这个过程中每个线程进入图片加载方法之后都会先加锁，加锁之后其他进程是无法进入“加锁代码”的。但是第一个线程进入“加锁代码”后去加载图片却发现当前并没有任何图片，因此它只能等待。一旦调用了NSCondition的wait方法后其他线程就可以继续进入“加锁代码”（注意，这一点和前面说的NSLock、@synchronized等是不同的，使用NSLock、@synchronized等进行加锁后无论什么情况下，只要没有解锁其他线程就无法进入“加锁代码”），同时第一个线程处于等待队列中（此时并未解锁）。第二个线程进来之后同第一线程一样，发现没有图片就进入等待状态，然后第三个线程进入。。。如此反复，直到第9个线程也处于等待。此时点击“创建图片”后会执行createImageName方法，这是一个生产者，它会创建一个图片链接放到imageNames中，然后通过调用NSCondition的signal方法就会在条件等待队列中选择一个线程（该线程会任意选取，假设为线程A）开启，那么此时这个线程就会继续执行。在上面代码中，wati方法之后会继续执行图片加载方法，那么此时线程A启动之后继续执行图片加载方法，当然此时可以成功加载图片。加载完图片之后线程A就会释放锁，整个线程任务完成。此时再次点击”创建图片“按钮重复前面的步骤加载其他图片。
 
 */

#warning iOS中的其他锁

/*
 
 iOS中的其他锁
 
 在iOS开发中，除了同步锁有时候还会用到一些其他锁类型，在此简单介绍一下：
 
 NSRecursiveLock ：递归锁，有时候“加锁代码”中存在递归调用，递归开始前加锁，递归调用开始后会重复执行此方法以至于反复执行加锁代码最终造成死锁，这个时候可以使用递归锁来解决。使用递归锁可以在一个线程中反复获取锁而不造成死锁，这个过程中会记录获取锁和释放锁的次数，只有最后两者平衡锁才被最终释放。
 
 NSDistributedLock：分布锁，它本身是一个互斥锁，基于文件方式实现锁机制，可以跨进程访问。
 
 pthread_mutex_t：同步锁，基于C语言的同步锁机制，使用方法与其他同步锁机制类似。
 
 提示：在开发过程中除非必须用锁，否则应该尽可能不使用锁，因为多线程开发本身就是为了提高程序执行顺序，而同步锁本身就只能一个进程执行，这样不免降低执行效率。
 
 */

#warning 提示：在开发过程中除非必须用锁，否则应该尽可能不使用锁，因为多线程开发本身就是为了提高程序执行顺序，而同步锁本身就只能一个进程执行，这样不免降低执行效率。

#warning 总结：
/*
 
1>无论使用哪种方法进行多线程开发，每个线程启动后并不一定立即执行相应的操作，具体什么时候由系统调度（CPU空闲时就会执行）。

2>更新UI应该在主线程（UI线程）中进行，并且推荐使用同步调用，常用的方法如下：

- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(id)arg waitUntilDone:(BOOL)wait (或者-(void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(id)arg waitUntilDone:(BOOL) wait;方法传递主线程[NSThread mainThread])
[NSOperationQueue mainQueue] addOperationWithBlock:
dispatch_sync(dispatch_get_main_queue(), ^{})
3>NSThread适合轻量级多线程开发，控制线程顺序比较难，同时线程总数无法控制（每次创建并不能重用之前的线程，只能创建一个新的线程）。

4>对于简单的多线程开发建议使用NSObject的扩展方法完成，而不必使用NSThread。

5>可以使用NSThread的currentThread方法取得当前线程，使用 sleepForTimeInterval:方法让当前线程休眠。

6>NSOperation进行多线程开发可以控制线程总数及线程依赖关系。

7>创建一个NSOperation不应该直接调用start方法（如果直接start则会在主线程中调用）而是应该放到NSOperationQueue中启动。

8>相比NSInvocationOperation推荐使用NSBlockOperation，代码简单，同时由于闭包性使它没有传参问题。

9>NSOperation是对GCD面向对象的ObjC封装，但是相比GCD基于C语言开发，效率却更高，建议如果任务之间有依赖关系或者想要监听任务完成状态的情况下优先选择NSOperation否则使用GCD。

10>在GCD中串行队列中的任务被安排到一个单一线程执行（不是主线程），可以方便地控制执行顺序；并发队列在多个线程中执行（前提是使用异步方法），顺序控制相对复杂，但是更高效。

11>在GDC中一个操作是多线程执行还是单线程执行取决于当前队列类型和执行方法，只有队列类型为并行队列并且使用异步方法执行时才能在多个线程中执行（如果是并行队列使用同步方法调用则会在主线程中执行）。

12>相比使用NSLock，@synchronized更加简单，推荐使用后者。
 
 */

@end

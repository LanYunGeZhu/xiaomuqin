//
//  XMQRecorder.m
//  XMQRecording
//
//  Created by bin xie on 2019/10/2.
//  Copyright © 2019 Xiaomuqin. All rights reserved.
//

#import "XMQRecorder.h"
#import <AVFoundation/AVFoundation.h>
#include "xmqpro.h"

#define kNumberAudioQueueBuffers 3   //输出音频队列缓冲个数
// 调整这个值使得录音的缓冲区大小为512,实际会小于或等于512,需要处理小于512的情况
#define kDefaultSampleRate 16000     //定义采样率为16000

typedef struct CallbackStruct {
    AudioStreamBasicDescription  recordFormat;
    AudioQueueRef                audioQueue;
    AudioQueueBufferRef          audioBuffers[kNumberAudioQueueBuffers];
} CallbackStruct;

@interface XMQRecorder()

@property (nonatomic, assign) CallbackStruct  recorder;
@property (nonatomic, assign) BOOL            isRecording;

@property (nonatomic, assign) NSInteger timerAdd;
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation XMQRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        /** 获取一个全局的线程来运行计时器*/
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        /** 创建一个计时器*/
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        /** 设置计时器, 这里是每1毫秒执行一次*/
        dispatch_source_set_timer(self.timer, dispatch_walltime(nil, 0), 1*NSEC_PER_MSEC, 0);
        /** 设置计时器的里操作事件*/
        dispatch_source_set_event_handler(self.timer, ^{
            self.timerAdd ++;
        });
    }
    return self;
}

- (void)dealloc
{
    _recorder.audioQueue = nil;
}

#pragma mark - 初始化 AVAudioSession

- (void)initAudioSession
{
    NSError *error = nil;
    //PlayAndRecord 如果录音时同时需要播放媒体，那么必须加上这两行代码
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    memset(&_recorder.recordFormat, 0, sizeof(_recorder.recordFormat));
    _recorder.recordFormat.mFormatID = kAudioFormatLinearPCM;
    _recorder.recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    _recorder.recordFormat.mSampleRate = kDefaultSampleRate;
    _recorder.recordFormat.mChannelsPerFrame = 1;
    _recorder.recordFormat.mBitsPerChannel = 16;
    UInt32 bytes = (_recorder.recordFormat.mBitsPerChannel / 8) * _recorder.recordFormat.mChannelsPerFrame;
    _recorder.recordFormat.mBytesPerPacket = bytes;
    _recorder.recordFormat.mBytesPerFrame = bytes;
    _recorder.recordFormat.mFramesPerPacket = 1;
    //初始化音频输入队列
    AudioQueueNewInput(&_recorder.recordFormat,
                       inputBufferHandler,
                       (__bridge void *)(self),
                       NULL, NULL,
                       0,
                       &_recorder.audioQueue);
    //计算估算的缓存区大小
    int bufferByteSize = 512;
    //创建缓冲器
    for (NSInteger i = 0; i < kNumberAudioQueueBuffers; i++)
    {
        AudioQueueAllocateBuffer(_recorder.audioQueue, bufferByteSize, &_recorder.audioBuffers[i]);
        AudioQueueEnqueueBuffer(_recorder.audioQueue, _recorder.audioBuffers[i], 0, NULL);
    }
}

- (void)startRecord
{
    BOOL isAuthorized = [self getMicrophoneAuthorization];

    if (isAuthorized)
    {
        [self initAudioSession];
        AudioQueueStart(_recorder.audioQueue, NULL);
        _isRecording = YES;
    }
    else
    {
        [self userAuthorizationAction];
    }
}

- (void)stopRecord
{
    if (_isRecording)
    {
         _isRecording = NO;
        //停止录音队列和移除缓冲区,以及关闭session，这里无需考虑成功与否
        AudioQueueStop(_recorder.audioQueue, true);
        //移除缓冲区,true代表立即结束录制，false代表将缓冲区处理完再结束
        AudioQueueDispose(_recorder.audioQueue, true);
    }
    
    NSLog(@"停止录制");
}

#pragma mark - 录音pcm原始数据实时回调方法

static void inputBufferHandler(void *inUserData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer,
                               const AudioTimeStamp *inStartTime,
                               UInt32 inNumPackets,
                               const AudioStreamPacketDescription *inPacketDesc)
{
    XMQRecorder *recordManage = (__bridge XMQRecorder*)inUserData;
    
    if (inNumPackets > 0)
    {
        NSMutableData *data = [NSMutableData dataWithBytes:inBuffer->mAudioData
                                                    length:inBuffer->mAudioDataByteSize];
//        if (data.length < 512)
//        {
//            //处理长度小于512的情况,此处是补00
//            Byte byte[] = {0x00};
//            NSData *zeroData = [[NSData alloc] initWithBytes:byte length:1];
//
//            for (NSUInteger i = data.length; i < 512; i++)
//            {
//                [data appendData:zeroData];
//            }
//        }
        
        if (data.length == 512) {
            
            if (recordManage.recorderDelegate)
            {
                [recordManage.recorderDelegate returnAudioBufferData:data];
            }
        }else{
            NSLog(@"%@", data);
        }
        
    }
    
    if (recordManage.isRecording)
    {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

#pragma mark - 传值AI算法c语言double 数组
- (void)toCBasisArray:(NSArray *)basisArr withAscendingArr:(NSArray *)ascendingArr
{
    int firstcount = (int)basisArr.count;
    int secondcount = (int)ascendingArr.count;
    int **firstArray = malloc(sizeof(int*)*(basisArr.count));
    int *secondArray = malloc(sizeof(int)*ascendingArr.count);
    int *thirdArray = malloc(sizeof(int)*2);

    //第一个数组
    for (int i = 0; i<basisArr.count; i++)
    {
        firstArray[i] = malloc(sizeof(int)*10);
        
        for (int j = 0; j<10; j++)
        {
            firstArray[i][j] = 0;
        }
    }
    
    for (int i = 0; i<basisArr.count; i++)
    {
        for (int j = 0; j<10; j++)
        {
            firstArray[i][j] = 0;
        }
    }
    
    int index = 0;
    
    for (int i = 0; i<firstcount; i++)
    {
        for (int j = 0; j<10; j++)
        {
            NSString *valueStr = [NSString stringWithFormat:@"%@",basisArr[i][j]];
            int valueInt = valueStr.intValue;
            firstArray[index][j] = valueInt;
        }
        
        index++;
  
    }
    
    //第二个数据
    for (int i = 0; i<ascendingArr.count; i++)
    {
        NSString *valueStr = [NSString stringWithFormat:@"%@",ascendingArr[i]];
        int valueInt = valueStr.intValue;
        secondArray[i] = valueInt;
    }
    
    //第三个数据
    NSArray *thirdA = [[NSUserDefaults standardUserDefaults] objectForKey:@"fragment"];
    if (thirdA.count > 0) {
        for (int i = 0; i<thirdA.count; i++)
        {
            NSString *valueStr = [NSString stringWithFormat:@"%@",thirdA[i]];
            int valueInt = valueStr.intValue;
            thirdArray[i] = valueInt;
        }
    }else{
        thirdArray[0] = 0;
        thirdArray[1] = 7;
    }

    
    
    init(firstArray, secondArray, thirdArray, firstcount, secondcount);

}

#pragma mark - 录音pcm原始数据转为C需要的数据类型

- (void)processAudioBuffer:(NSMutableData *)audioData
{
    //开启定时器-判断16毫秒内是否算法已经处理完并返回数据
    self.timerAdd = 0;
    dispatch_resume(self.timer);
    
    Byte *testByte = (Byte *)[audioData bytes];
    short *data = (short *)testByte;
    NSMutableArray *indexArr = [NSMutableArray array];
    int array[8] = {0};
    double doubleArr[256] = {0};
    
    for (NSInteger i = 0; i<audioData.length/2; i++)
    {
        double dValue = (double)(data[i])/32768;
        doubleArr[i] = dValue;
    }
//    free(testByte);
    
//    [self writeDoubleArr:doubleArr writeAudioData:audioData];
    [self writePcmData:audioData];

    testcode(doubleArr, array, 8, 1);
    
    self.changeIndex++;
    
    for (int i = 0; i<8; i++)
    {
        [indexArr addObject:[NSNumber numberWithDouble:array[i]]];
    }
    
 
    //出现漏检情况
//    int fourIndex = array[4];
//    NSMutableArray *newIndexArr = [NSMutableArray array];
//    if (fourIndex == 2) {
//
//        NSMutableData *newAudioData = [self.recorderDelegate getLoseDataArr:indexArr];
//        Byte *newTestByte = (Byte *)[newAudioData bytes];
//        short *newData = (short *)newTestByte;
//        double newDoubleArr[2048] = {0};
//
//        if (newAudioData.length>4096) {
//            NSLog(@"\n----漏检后抓取数据出错大于了8帧----\n");
//        }
//        for (NSInteger i = 0; i<2048; i++)
//        {
//            double newDValue = (double)(newData[i])/32768;
//            newDoubleArr[i] = newDValue;
//        }
////        free(newTestByte);
//        int newArray[8] = {0};
//        testcode(newDoubleArr, newArray, 8, 2);
//
//        for (int i = 0; i<8; i++)
//        {
//            [newIndexArr addObject:[NSNumber numberWithDouble:newArray[i]]];
//        }
//    }
//
    if (self.recorderDelegate)
    {
        //
        [self.recorderDelegate returnAllProcessIndexArr:indexArr];
        //
        dispatch_suspend(self.timer);
        if (self.timerAdd < 16) {
            [self.recorderDelegate manualCallAudioBufferToC];
        }
        //
//        if (newIndexArr.count > 0)
//        {
//            NSInteger firstIndexAgain = [newIndexArr[0] integerValue];
//            NSInteger secondIndex = [newIndexArr[2] integerValue];
//            if (firstIndexAgain != 0  && secondIndex == 1)
//            {
//                [self.recorderDelegate returnProcessIndexArr:newIndexArr];
//            }
//        }
        
        NSInteger firstIndex = [indexArr[0] integerValue];
        if (firstIndex != 0)
        {

            NSLog(@"---------%@",indexArr);
//            if (newIndexArr.count >0 && [newIndexArr[2] integerValue] != 1) {
//                [indexArr replaceObjectAtIndex:0 withObject:[NSNumber numberWithLong:firstIndex-1]];
//            }
            [self.recorderDelegate returnProcessIndexArr:indexArr];
        }
    }
}


#pragma mark - 保存录音文件pcm格式
- (void)writePcmData:(NSData *)data
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *plistpath = [paths objectAtIndex:0];
    NSString *savePath = [plistpath stringByAppendingPathComponent:@"/record.pcm"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath] == false)
    {
        [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
    }
    
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
    [handle seekToEndOfFile];
    [handle writeData:data];
}
//#pragma mark - 保存喂给算法的入参数组
//- (void)writeDoubleArr:(double[])data writeAudioData:(NSMutableData *)audioData
//{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
//    NSString *plistpath = [paths objectAtIndex:0];
//    NSString *savePath = [plistpath stringByAppendingPathComponent:@"/doubleArr.txt"];
//
//    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath] == false)
//    {
//        [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
//    }
//
//    NSMutableArray *arr = [[NSMutableArray alloc]init];
//
//    for (int i = 0; i<256; i++) {
//        [arr addObject:[NSNumber numberWithDouble:data[i]]];
//    }
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr options:NSJSONWritingPrettyPrinted error:nil];
//    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
//    [handle seekToEndOfFile];
//    [handle writeData:jsonData];
//
//     [self writePcmData:audioData];
//}
#pragma mark - 保存录音文件pcm转为wav格式

- (void)createPlayableFileFromPcmData:(NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *plistpath = [paths objectAtIndex:0];
    NSString *wavFilePath = [plistpath stringByAppendingPathComponent:@"/record.wav"];
    
    FILE *fout;
    
    short NumChannels = 1;        //录音通道数
    short BitsPerSample = 16;     //线性采样位数
    int SamplingRate = 16000;     //录音采样率(Hz)
    int numOfSamples = (int)[[NSData dataWithContentsOfFile:filePath] length];
    
    int ByteRate = NumChannels*BitsPerSample*SamplingRate/8;
    short BlockAlign = NumChannels*BitsPerSample/8;
    int DataSize = NumChannels*numOfSamples*BitsPerSample/8;
    int chunkSize = 16;
    int totalSize = 46 + DataSize;
    short audioFormat = 1;
    
    if((fout = fopen([wavFilePath cStringUsingEncoding:1], "w")) == NULL)
    {
        printf("Error opening out file ");
    }
    
    fwrite("RIFF", sizeof(char), 4,fout);
    fwrite(&totalSize, sizeof(int), 1, fout);
    fwrite("WAVE", sizeof(char), 4, fout);
    fwrite("fmt ", sizeof(char), 4, fout);
    fwrite(&chunkSize, sizeof(int),1,fout);
    fwrite(&audioFormat, sizeof(short), 1, fout);
    fwrite(&NumChannels, sizeof(short),1,fout);
    fwrite(&SamplingRate, sizeof(int), 1, fout);
    fwrite(&ByteRate, sizeof(int), 1, fout);
    fwrite(&BlockAlign, sizeof(short), 1, fout);
    fwrite(&BitsPerSample, sizeof(short), 1, fout);
    fwrite("data", sizeof(char), 4, fout);
    fwrite(&DataSize, sizeof(int), 1, fout);
    
    fclose(fout);
    
    NSMutableData *pamdata = [NSMutableData dataWithContentsOfFile:filePath];//取出存入的data音频数据
    NSFileHandle *handle;
    handle = [NSFileHandle fileHandleForUpdatingAtPath:wavFilePath];
    [handle seekToEndOfFile];
    [handle writeData:pamdata];//待上传的wav格式的数据
    [handle closeFile];
    
}

#pragma mark - 判断麦克风授权情况

- (BOOL)getMicrophoneAuthorization
{
    __block BOOL isAuthorization = true;
    NSString *mediaType = AVMediaTypeAudio;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    switch (status)
    {
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (granted)
                    {
                        isAuthorization = YES;
                    }
                    else
                    {
                        isAuthorization = NO;
                    }
                });
            }];
        }
            break;
            
        case AVAuthorizationStatusDenied:
        {
            isAuthorization = NO;
        }
            break;
            
        case AVAuthorizationStatusAuthorized:
        {
            isAuthorization = YES;
        }
            break;
            
        default:
            break;
    }
    
    return isAuthorization;
}

- (void)userAuthorizationAction
{
    NSString *messageStr = @"您未开启APP打开麦克风授权，请到“设置-小木琴教师-麦克风”中启用访问";
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示"
                                                                     message:messageStr
                                                              preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"去设置"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:setAction];
    [self.currViewController presentViewController:alertVC animated:YES completion:nil];
}



@end

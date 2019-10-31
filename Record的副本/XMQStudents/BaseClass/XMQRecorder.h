//
//  XMQRecorder.h
//  XMQRecording
//
//  Created by bin xie on 2019/10/2.
//  Copyright © 2019 Xiaomuqin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XMQRecorderDelegate <NSObject>

// 返回pcm源数据做全局数组再间隔给到C进行处理
- (void)returnAudioBufferData:(NSMutableData *)bufferData;
// 返回C处理的数据给到H5使用(不包含为0的数据)
- (void)returnProcessIndexArr:(NSArray *)indexArr;
// 返回C处理的数据给到H5使用(全部数据)
- (void)returnAllProcessIndexArr:(NSArray *)indexArr;

- (NSMutableData *)getLoseDataArr:(NSArray *)indexArr;

- (void)manualCallAudioBufferToC;//手动调用audioBufferToC方法实现及时喂给算法数据

@end

@interface XMQRecorder : NSObject

@property (nonatomic,  weak) UIViewController        *currViewController;
@property (nonatomic,  weak) id<XMQRecorderDelegate> recorderDelegate;
@property (nonatomic, assign) NSInteger  changeIndex;

- (void)startRecord;  // 开始录音
- (void)stopRecord;   // 暂停录音
- (void)toCBasisArray:(NSArray *)basisArr withAscendingArr:(NSArray *)ascendingArr;
- (void)processAudioBuffer:(NSMutableData *)audioData;

- (void)writePcmData:(NSData *)data;
- (void)createPlayableFileFromPcmData:(NSString *)filePath;//保存录音文件pcm转为wav格式

@end

NS_ASSUME_NONNULL_END

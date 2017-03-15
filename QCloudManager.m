//
//  QCloudManager.m
//  IXQ
//
//  Created by roycms on 16/7/22.
//  Copyright © 2016年 北京三芳科技有限公司. All rights reserved.
//[[QCloudManager shareQCloudManager] upload:@[imageData,imageData,imageData,imageData,imageData] success:^(NSArray *urls) {
//    NSLog(@"%@-------------------------+++++++++++++++:",urls);
//}];
//

#import "QCloudManager.h"
#import "BaseWebService.h"
#import "NetworkManager.h"

@interface QCloudManager ()
@property (nonatomic,strong) TXYUploadManager *uploadImageManager;
@property (strong,nonatomic)NSString *qCloudToken;
@property (assign,nonatomic)double qCloudTokenOutTime;
@end

@implementation QCloudManager

+ (instancetype)shareQCloudManager {
    
    static QCloudManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[QCloudManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init {
    self = [super init];
    if(self != nil){
        self.uploadImageManager = [[TXYUploadManager alloc] initWithCloudType:TXYCloudTypeForImage
                                                                persistenceId:@"persistenceId"
                                                                        appId:QQCLOUD_APPID];
    }
    return self;
}

-(void)getUploadImageSign:(void (^)(id, NSError *))completion
{
    NSDictionary * params = [NSDictionary
                             dictionaryWithObjectsAndKeys:
                             QQCLOUD_APPID,@"app_id",
                             QQCLOUD_SECRET_ID,@"secret_id",
                             QQCLOUD_SECRET_KEY,@"secret_key",
                             QQCLOUD_BUCKET,@"bucket",
                             nil];
    
    [[NetworkManager shareManager] requestType:RequestTypePost URLString:QQCLOUD_SIGNURL params:params completion:completion];
}

- (void)uploadPhoto:(TXYPhotoUploadTask *)uploadPhotoTask success:(void (^)(NSDictionary *))success fail:(void (^)(NSString *))fail{
    
    
    [self.uploadImageManager upload:uploadPhotoTask
                           complete:^(TXYTaskRsp *resp, NSDictionary *context) {
                               
                               TXYPhotoUploadTaskRsp *photoResp = (TXYPhotoUploadTaskRsp *)resp;
                               NSLog(@"上传图片的url%@ 上传图片的fileid = %@",photoResp.photoURL,photoResp.photoFileId);
                               NSLog(@"upload return=%d",photoResp.retCode);
                               
                               
                               NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                                         photoResp.photoURL,@"path",
                                                         photoResp.photoFileId,@"fileId",nil];
                               success(dic);
                           }
                           progress:^(int64_t totalSize, int64_t sendSize, NSDictionary *context) {
                               //命中妙传，不走这里的！
                               NSLog(@" totalSize %lld",totalSize);
                               NSLog(@" sendSize %lld",sendSize);
                               NSLog(@" sendSize %@",context);
                               
                           }
                        stateChange:^(TXYUploadTaskState state, NSDictionary *context) {
                            switch (state) {
                                case TXYUploadTaskStateWait:
                                    NSLog(@"任务等待中");
                                    break;
                                case TXYUploadTaskStateConnecting:
                                    NSLog(@"任务连接中");
                                    break;
                                case TXYUploadTaskStateFail:
                                    NSLog(@"任务失败");
                                    fail(@"任务失败");
                                    break;
                                case TXYUploadTaskStateSuccess:
                                    NSLog(@"任务成功");
                                    break;
                                default:
                                    break;
                            }}];
    
}

- (NSArray *)photoTasks:(NSArray *)images{
    
    NSMutableArray *uploadPhotoTaskArray = [NSMutableArray array];
    
    for (NSData *image in images) {
        if(images == nil){
            continue;
        }
        else{
            UInt64 recordTime = [[NSDate date] timeIntervalSince1970] * 1000;
            TXYPhotoUploadTask *uploadPhotoTask = [[TXYPhotoUploadTask alloc] initWithImageData:image
                                                                                       fileName:[NSString stringWithFormat:@"%llu",recordTime]
                                                                                           sign:self.qCloudToken
                                                                                         bucket:QQCLOUD_BUCKET
                                                                                    expiredDate:0
                                                                                     msgContext:@"服务器透穿信息"
                                                                                         fileId:nil];
            [uploadPhotoTaskArray addObject:uploadPhotoTask];
        }
    }
    return uploadPhotoTaskArray;
}

- (void)upload:(NSArray *)imageNSDatas success:(void (^)(NSArray *))success fail:(void (^)(NSError *))fail {
    
    @try {
        NSArray *photoTasks;
        
        if (self.qCloudToken==nil || self.qCloudTokenOutTime < [[NSDate date] timeIntervalSince1970] * 1000){
            
            [self getUploadImageSign:^(NSDictionary *res, NSError *error) {
                
                if (error) {
                    
                    fail(error);
                    return;
                }
                
                if (![res[@"code"] isEqualToString:@"200"]) {
                    NSError *error = [[NSError alloc] init];
                    fail(error);
                    return;
                }
                
                self.qCloudTokenOutTime = [res[@"expired_date"] doubleValue];
                self.qCloudToken = res[@"sign"];
                
                [self upload:imageNSDatas success:success fail:fail];
            }];
            return;
        }
        
        photoTasks = [self photoTasks:imageNSDatas];
        
        __block NSMutableArray *array =[NSMutableArray array];
        for (TXYPhotoUploadTask *uploadPhotoTask in photoTasks) {
            [self uploadPhoto:uploadPhotoTask success:^(NSDictionary *dic) {
                [array addObject:dic];
                if(array.count == photoTasks.count)
                {
                    success(array);
                }
            } fail:^(NSString *msg) {
                
                NSError *error = [[NSError alloc] init];
                fail(error);
                return;
            }];
        }
        
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

@end

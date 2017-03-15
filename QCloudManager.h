//
//  QCloudManager.h
//  IXQ
//
//  Created by roycms on 16/7/22.
//  Copyright © 2016年 北京三芳科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXYUploadManager.h"

@interface QCloudManager : NSObject
+ (instancetype)shareQCloudManager;
-(void)getUploadImageSign:(void (^)(id, NSError *))completion;
- (void)upload:(NSArray *)imageNSDatas success:(void (^)(NSArray *))success fail:(void(^)(NSError *))fail;

@end

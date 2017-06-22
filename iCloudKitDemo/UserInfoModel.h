//
//  UserInfoModel.h
//  iCloudKitDemo
//
//  Created by 张友波 on 2017/6/16.
//  Copyright © 2017年 张友波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UserInfoModel : NSObject

/** 账户名称 */
@property (nonatomic,strong)NSString *userAccout;

/** 用户名字 */
@property (nonatomic,strong) NSString *userName;

/** 用户头像 */
@property (nonatomic,strong) UIImage  *userAvtars;

/** 用户手机号码 */
@property (nonatomic,strong) NSString *userPhoneNum;

/** 用户邮箱号 */
@property (nonatomic,strong) NSString *userEmail;

/** 用户密码 */
@property (nonatomic,strong) NSString *userPassword;

@end

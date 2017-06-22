//
//  ViewController.m
//  iCloudKitDemo
//
//  Created by 张友波 on 2017/6/16.
//  Copyright © 2017年 张友波. All rights reserved.
//

#import "ViewController.h"
#import <CloudKit/CloudKit.h>
#import "UserInfoModel.h"
#import <objc/runtime.h>

@interface ViewController (){
    UserInfoModel * userInfo;
}


@end

@implementation ViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.userInfoTextView.text = @"";
    [self initUserInfoModel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initUserInfoModel{
    userInfo = [[UserInfoModel alloc] init];
    userInfo.userAccout = @"13818956024";
    userInfo.userName = @"张友波";
    userInfo.userAvtars = [UIImage imageNamed:@"yaoyiyao_content_0"];
    userInfo.userPhoneNum = @"13818956024";
    userInfo.userEmail = @"13818956024@163.com";
    userInfo.userPassword = @"123456";
    
}

#pragma mark - Action
- (IBAction)clearLocalData:(id)sender {
    self.userInfoTextView.text = @"";
    self.avtarImageView.image = nil;
}

- (IBAction)addData:(id)sender {
    [self saveWithModel:userInfo];
}
- (IBAction)fetchData:(id)sender {
    [self cloudGetUserInfoWithUseraccout:userInfo.userAccout Succeed:^(UserInfoModel *succeed)
    {
        
    }failed:^(NSError *failed){
        
    }];
}
- (IBAction)deleteData:(id)sender {
    [self cloudDeleteModelWithModel:userInfo];
}

#pragma mark - CloudKit
// 使用CloudKit 保存数据
- (void)saveWithModel:(UserInfoModel*)userInfoModel{
    //因为账户名不变的 以帐户名做微ID最好不过了
    CKRecordID *postrecordID = [[CKRecordID alloc] initWithRecordName:userInfoModel.userAccout];
    
    CKRecord *postRecrod = [[CKRecord alloc] initWithRecordType:@"People"recordID:postrecordID];
  
    
    //将用户类的属性和属性值打包成一个字典  其中属性对应key 属性值对应Value  因为属性中有一栏是图片类，CloudKit不支持直接对图片进行保存，但是可以转换成NSdata，这洋就可以进行保存了.   这里说明一下 cloudKit的提交 只接受NSString、NSNumber、NSData、CLLocation，和 CKReference、CKAsset 等直接的存储， 其它的需要
    
    NSMutableArray *propArr = [self getAllProp:[userInfoModel class]];   //这里使用getAllProp 在下面贴出
    for (NSString *prop in propArr) {
         if([[userInfoModel valueForKey:prop] isKindOfClass:[UIImage class]]){
             // 图片特殊情况另外处理  如果实别的不符合存储的也同样需要处理
             UIImage *image = [userInfoModel valueForKey:prop];
        
             postRecrod[prop] = [NSData dataWithData:UIImagePNGRepresentation(image)]; //record可以像字典一样进行数据的收纳
        }else{
            postRecrod[prop] = [userInfoModel valueForKey:prop];
        }
    }
    
    //用户信息 提交到 云
    [[[CKContainer defaultContainer] privateCloudDatabase] saveRecord:postRecrod completionHandler:^(CKRecord *savedPlace, NSError *error) {
        if(savedPlace){
            NSLog(@"存储成功 :%@",savedPlace);  // 成功  打印存储的内容
            
        }else{
            NSLog(@"存储失败 :%@",error);       // 失败 打印错误
        }
    }];
    
}

// 使用CloudKit 查询数据
- (void )cloudGetUserInfoWithUseraccout:(NSString *)userAccout Succeed:(void(^)(UserInfoModel* ))succeed failed:(void(^)(NSError *))failed{
    
    UserInfoModel *model = [[UserInfoModel alloc]init];
    if(userAccout){
        CKRecordID *postrecordID = [[CKRecordID alloc] initWithRecordName:userAccout];
        [[[CKContainer defaultContainer] privateCloudDatabase] fetchRecordWithID:postrecordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
            // handle errors here
            if(error){
                if(failed){
                    failed(error);
                }
            }else{  //说明查询成功
                if(succeed){
                    //已经获取到了存入的数据， 并经过转换存入了字典 dic  将字典中的键值对赋给一个类对应的属性 同理因为其中有一个图片 所以需要做一个NSdata的转换
                    NSMutableString *appendStr = [NSMutableString new];
                    NSMutableArray *mArray = [self getAllProp:[model class]];
                    for (NSString *prop in mArray) { //这里如果不是在后台人为添加的数据 不会出现没有对应的属性的情况  但是为了保险起见。在UserInfoModel 重写 setVale：forUndefinedKey方法
                        id info = [record valueForKey:prop];
                        
                        if([info isKindOfClass:[NSString class]]){
                            //                        [model setValue:[dic valueForKey:prop] forKey:prop];
                            [model setValue:record[prop] forKey:prop];
                            NSLog(@"获取数据 :%@ = %@",prop,info);
                            
                            [appendStr appendFormat:@"%@ = %@ ",prop,info];
                            
                        }else{
                            UIImage *image = [UIImage imageWithData:info];
                            [model setValue:image forKey:prop];
                            
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.avtarImageView.image = model.userAvtars;
                        self.userInfoTextView.text = appendStr;
                        
                    });
                   
                    succeed(model); //回调获取到的模型
                }
            }
        } ];
    }
}

// 使用CloudKit 删除数据
- (void)cloudDeleteModelWithModel:(UserInfoModel *)userInfoModel{
    //之前也说了在存储的时候， 我们操纵cloud上的数据都是通过record ID来实现的， 所以record ID的名字应该是一个不经常改变的属性， 这里用的就是用户的账户名
    CKRecordID *postrecordID = [[CKRecordID alloc]initWithRecordName:userInfoModel.userAccout];
    [[[CKContainer defaultContainer] privateCloudDatabase] deleteRecordWithID:postrecordID completionHandler:^(CKRecordID * _Nullable recordID, NSError * _Nullable error) {
        if(!error){
            //删除成功
        }else{
            NSLog(@"删除失败%@",error);    //打印错误
        }
    }];
}

- (NSMutableArray *)getAllProp:(Class)cls{
    // 获取当前类的所有属性
    unsigned int count;// 记录属性个数
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    // 遍历
    NSMutableArray *mArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        // 获取属性的名称 C语言字符串
        const char *cName = property_getName(property);
        // 转换为Objective C 字符串
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        [mArray addObject:name];
    }
    return mArray;
}

@end



























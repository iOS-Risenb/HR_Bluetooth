//
//  HR_BT_Center.h
//  BT_Center
//
//  Created by Obgniyum on 2017/9/27.
//  Copyright © 2017年 Risenb. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HR_BT_Model;
@import CoreBluetooth;

@interface HR_BT_Center : NSObject

+ (instancetype)HR_Init;

#pragma mark - 蓝牙检测
+ (void)HR_ObserveState:(void(^)(CBManagerState state))handle;
@property (nonatomic, assign) CBManagerState state;

#pragma mark - 扫描设备
// 开始扫描
+ (void)HR_StartScanWithSUUIDStrings:(NSArray <NSString *>*)sUUIDs filter:(BOOL(^)(CBPeripheral *peripheral))filter result:(void(^)(CBPeripheral *peripheral))result;
// 扫描到的设备数组
@property (nonatomic, copy) NSMutableArray <CBPeripheral *>*scanPeripherals;
// 停止扫描
+ (void)HR_StopScan;

#pragma mark - 连接设备
// 连接设备
+ (void)HR_ConnectPeripheral:(CBPeripheral *)peripheral
                     success:(void(^)(void))success
                     failure:(void(^)(NSString *errMsg))failure
                     timeout:(void(^)(void))timeout
                  disconnect:(void(^)(CBPeripheral *peripheral, BOOL abnormal))disconnect;

@property (nonatomic, strong, readonly) CBPeripheral *connectedPeripheral;
// 断开连接
+ (void)HR_DisconnectPeripheral;

#pragma mark - 数据操作
// 读
+ (void)HR_ReadWithService:(NSString *)sUUID
            characteristic:(NSString *)cUUID
                   success:(void(^)(NSString *value))success
                   failure:(void(^)(NSString *errMsg))failure;
// 写
+ (void)HR_WriteWithService:(NSString *)sUUID
             characteristic:(NSString *)cUUID
                       data:(NSData *)data
                    success:(void(^)(void))success
                    failure:(void(^)(NSString *errMsg))failure;

// 写+通知
+ (void)HR_NotifyWithService:(NSString *)sUUID
              characteristic:(NSString *)cUUID
                        data:(NSData *)data
                     success:(void(^)(void))success
                      update:(void(^)(NSString *value))update
                     failure:(void(^)(NSString *errMsg))failure;

@property (nonatomic, copy, readonly) NSString *sUUID;
@property (nonatomic, copy, readonly) NSString *cUUID;

@end



#import "HR_BT_Center.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "NSData+HR_HexString.h"

typedef NS_ENUM(NSUInteger, HR_BT_OP_TPYE) {
    HR_BT_OP_TPYE_R, // 读
    HR_BT_OP_TPYE_W, // 写
    HR_BT_OP_TPYE_N  // 写+通知
};

@interface HR_BT_Center () <
CBCentralManagerDelegate,
CBPeripheralDelegate>

// 蓝牙管理者
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, copy) void(^observer)(CBManagerState state);

// 扫描
@property (nonatomic, copy) BOOL(^scanFilterBlock)(CBPeripheral *);
@property (nonatomic, copy) void(^scanResultBlock)(CBPeripheral *);

// 连接
@property (nonatomic, copy) void(^connectSuccessBlock)(void);
@property (nonatomic, copy) void(^connectFailureBlock)(NSString *);
@property (nonatomic, copy) void(^connectTimeoutBlock)(void);
@property (nonatomic, assign) BOOL handleConnectTimeOut;
@property (nonatomic, copy) void(^disconnectBlock)(CBPeripheral *, BOOL);
@property (nonatomic, assign) BOOL abnormalDisconnect;

// 数据（读）
@property (nonatomic, assign) HR_BT_OP_TPYE opType;
@property (nonatomic, copy) void(^readSuccessBlock)(NSString *value);
@property (nonatomic, copy) void(^readFailureBlock)(NSString *errMsg);

// 数据（写）
@property (nonatomic, copy) NSData *writeData;
@property (nonatomic, copy) void(^writeSuccessBlock)(void);
@property (nonatomic, copy) void(^writeFailureBlock)(NSString *errMsg);

// 数据（写通知）
@property (nonatomic, strong) NSData *notifyWriteData;
@property (nonatomic, copy) void(^notifySuccessBlock)(void);
@property (nonatomic, copy) void(^notifyUpdateBlock)(NSString *value);
@property (nonatomic, copy) void(^notifyFailureBlock)(NSString *errMsg);

@end

@implementation HR_BT_Center

+ (instancetype)HR_Init {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [[self class] HR_Init];
}

- (instancetype)copyWithZone:(struct _NSZone *)zone{
    return [[self class] HR_Init];
}

#pragma mark - 1.1.0 蓝牙检测
+ (void)HR_ObserveState:(void(^)(CBManagerState state))handle {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center.observer = handle;
    NSLog(@"动作(1.1.0)-蓝牙检测(监听)");
    center.manager = [[CBCentralManager alloc] initWithDelegate:center queue:nil];
}

#pragma mark 1.2.0 蓝牙检测(回调)
// 蓝牙状态回调
/**
 CBManagerStateUnknown = 0,  未知
 CBManagerStateResetting,    重置中
 CBManagerStateUnsupported,  不支持
 CBManagerStateUnauthorized, 未授权
 CBManagerStatePoweredOff,   未开启
 CBManagerStatePoweredOn,    可用
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center.state = central.state;
    if (center.observer) {
        center.observer(central.state);
    }
    /*
     CBManagerStateUnknown = 0,
     CBManagerStateResetting,
     CBManagerStateUnsupported,
     CBManagerStateUnauthorized,
     CBManagerStatePoweredOff,
     CBManagerStatePoweredOn,
     */
    switch (central.state) {
        case CBManagerStatePoweredOn: {
            NSLog(@"响应(1.2.0.1)-蓝牙-打开");
        }
            break;
        case CBManagerStateUnknown: {
            NSLog(@"响应(1.2.0.2)-蓝牙-未知");
        }
            break;
        case CBManagerStateResetting: {
            NSLog(@"响应(1.2.0.3)-蓝牙-重启");
        }
            break;
        case CBManagerStateUnsupported: {
            NSLog(@"响应(1.2.0.4)-蓝牙-不可用");
        }
            break;
        case CBManagerStateUnauthorized: {
            NSLog(@"响应(1.2.0.5)-蓝牙-未授权");
        }
            break;
        case CBManagerStatePoweredOff: {
            NSLog(@"响应(1.2.0.6)-蓝牙-关闭");
        }
            break;
    }
}

#pragma mark - 2.1.1 开始扫描
+ (void)HR_StartScanWithSUUIDStrings:(NSArray <NSString *>*)sUUIDs filter:(BOOL(^)(CBPeripheral *peripheral))filter result:(void(^)(CBPeripheral *peripheral))result {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center.scanFilterBlock = filter;
    center.scanResultBlock = result;
    [center.scanPeripherals removeAllObjects];
    if ([center.manager isScanning]) {
        NSLog(@"蓝牙已处于扫描状态");
    } else {
        NSLog(@"动作(2.1.1)-扫描设备");
        NSMutableArray <CBUUID *>*sUUIDMArr = [NSMutableArray array];
        for (NSString *uuid in sUUIDs) {
            CBUUID *sUUID = [CBUUID UUIDWithString:uuid];
            [sUUIDMArr addObject:sUUID];
        }
        [center.manager scanForPeripheralsWithServices:sUUIDMArr options:nil];
    }
}
#pragma mark 2.1.2 停止扫描
+ (void)HR_StopScan {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    if ([center.manager isScanning]) {
        [center.manager stopScan];
        NSLog(@"动作(2.1.2)-扫描停止");
    } else {
        NSLog(@"蓝牙未处于扫描状态");
    }
}

#pragma mark 2.2.0 扫描设备结果(回调)
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if (self.scanFilterBlock) {
        BOOL filter = self.scanFilterBlock(peripheral);
        if (filter) {
            NSLog(@"响应(2.2.0)发现目标设备:%@", peripheral);
            [self.scanPeripherals addObject:peripheral];
            if (self.scanResultBlock) {
                self.scanResultBlock(peripheral);
            }
        }
    }
}

#pragma mark - 3.1.1 连接设备
+ (void)HR_ConnectPeripheral:(CBPeripheral *)peripheral
                     success:(void(^)(void))success
                     failure:(void(^)(NSString *errMsg))failure
                     timeout:(void(^)(void))timeout
                  disconnect:(void(^)(CBPeripheral *peripheral, BOOL abnormal))disconnect {
    
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center->_connectedPeripheral = peripheral;
    center->_connectedPeripheral.delegate = center;
    center.abnormalDisconnect = YES;
    center.connectSuccessBlock = success;
    center.connectFailureBlock = failure;
    center.connectTimeoutBlock = timeout;
    center.disconnectBlock = disconnect;
    if (center.manager.state == CBManagerStatePoweredOn) { // 蓝牙可用
        if (peripheral) { // 有效外设
            if (center.connectedPeripheral.state == CBPeripheralStateConnecting || center.connectedPeripheral.state == CBPeripheralStateConnected) {
                if (center.connectedPeripheral == peripheral) {
                    if (center.connectFailureBlock) {
                        center.connectFailureBlock(@"该外设备已与当前设备配对");
                    }
                } else {
                    if (center.connectFailureBlock) {
                        center.connectFailureBlock(@"该外设已与其他设备配对");
                    }
                }
            } else {
                // 先断开已连接的外设
                if (center.connectedPeripheral) {
                    [center.manager cancelPeripheralConnection:center.connectedPeripheral];
                    center->_connectedPeripheral = nil;
                }
                // 连接新外设
                [center.manager connectPeripheral:peripheral options:nil];
                // 超时 (开启处理超时情况)
                center.handleConnectTimeOut = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (center.handleConnectTimeOut) {
                        NSLog(@"连接超时");
                        if (timeout) {
                            timeout();
                        }
                    }
                });
            }
        } else {
            if (center.connectFailureBlock) {
                center.connectFailureBlock(@"无效的外设");
            }
        }
    } else {
        if (center.connectFailureBlock) {
            center.connectFailureBlock(@"蓝牙非打开状态");
        }
    }
    NSLog(@"动作(3.1.1)-设备-连接");
}
#pragma mark 3.1.2 断开设备连接
+ (void)HR_DisconnectPeripheral {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center.abnormalDisconnect = NO;
    if (center.connectedPeripheral) {
        if (center.connectedPeripheral.state == CBPeripheralStateConnecting || center.connectedPeripheral.state == CBPeripheralStateConnected) {
            NSLog(@"动作(3.1.2)-设备-断开");
            [center.manager cancelPeripheralConnection:center.connectedPeripheral];
        } else {
            NSLog(@"外设处于非连接状态，不可连接");
        }
    } else {
        NSLog(@"缓存外设无效，不可连接");
    }
}

#pragma mark 3.2.1 连接成功(回调)
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    // 关闭处理连接超时情况
    self.handleConnectTimeOut = NO;
    // 停止扫描
    [self.manager stopScan];
    // 缓存已连接的设备
    _connectedPeripheral = peripheral;
    NSLog(@"响应(3.2.1)-连接-成功");
    if (self.connectSuccessBlock) {
        self.connectSuccessBlock();
    }
}
#pragma mark 3.2.2 连接失败(回调)
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // 关闭处理连接超时情况
    self.handleConnectTimeOut = NO;
    // 停止扫描
    [self.manager stopScan];
    // 清空连接外设缓存
    _connectedPeripheral = nil;
    NSLog(@"响应(3.2.2)-连接-失败");
    if (self.connectFailureBlock) {
        self.connectFailureBlock(error.localizedDescription);
    }
}
#pragma mark 3.2.3 连接断开(回调)

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    // 清空连接外设缓存
    _connectedPeripheral = nil;
    //
    if (self.abnormalDisconnect) {
        NSLog(@"响应(3.2.3.1)-连接-异常断开");
    } else {
        NSLog(@"响应(3.2.3.2)-连接-主动断开");
    }
    if (self.disconnectBlock) {
        if (self.abnormalDisconnect) {
            self.disconnectBlock(peripheral, YES);
        }
    }
}

#pragma mark - 4.1.1 搜索服务(读)

+ (void)HR_ReadWithService:(NSString *)sUUID
            characteristic:(NSString *)cUUID
                   success:(void(^)(NSString *value))success
                   failure:(void(^)(NSString *errMsg))failure {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center->_sUUID = sUUID;
    center->_cUUID = cUUID;
    center.opType = HR_BT_OP_TPYE_R;
    center.readSuccessBlock = success;
    center.readFailureBlock = failure;
    // 搜索服务
    if (center.connectedPeripheral) {
        NSLog(@"动作(4.1.1)-服务-搜索(读取)");
        CBUUID *serviceUUID = [CBUUID UUIDWithString:sUUID];
        [center.connectedPeripheral discoverServices:@[serviceUUID]];
    } else {
        if (failure) {
            failure(@"未连接机器人");
        }
    }
}
#pragma mark 4.1.2 搜索服务(写)
+ (void)HR_WriteWithService:(NSString *)sUUID
             characteristic:(NSString *)cUUID
                       data:(NSData *)data
                    success:(void(^)(void))success
                    failure:(void(^)(NSString *errMsg))failure {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center->_sUUID = sUUID;
    center->_cUUID = cUUID;
    center.opType = HR_BT_OP_TPYE_W;
    center.writeData = data;
    center.writeSuccessBlock = success;
    center.writeFailureBlock = failure;
    // 搜索服务
    NSLog(@"动作(4.1.2)-服务-搜索(写入)");
    CBUUID *serviceUUID = [CBUUID UUIDWithString:sUUID];
    [center.connectedPeripheral discoverServices:@[serviceUUID]];
}
#pragma mark 4.1.3 搜索服务(写+通知)
+ (void)HR_NotifyWithService:(NSString *)sUUID
              characteristic:(NSString *)cUUID
                        data:(NSData *)data
                     success:(void(^)(void))success
                      update:(void(^)(NSString *value))update
                     failure:(void(^)(NSString *errMsg))failure {
    HR_BT_Center *center = [HR_BT_Center HR_Init];
    center->_sUUID = sUUID;
    center->_cUUID = cUUID;
    center.opType = HR_BT_OP_TPYE_N;
    center.notifyWriteData = data;
    center.notifySuccessBlock = success;
    center.notifyUpdateBlock = update;
    center.notifyFailureBlock = failure;
    // 搜索服务
    NSLog(@"动作(4.1.3)-服务-搜索(写入+通知)");
    CBUUID *serviceUUID = [CBUUID UUIDWithString:sUUID];
    [center.connectedPeripheral discoverServices:@[serviceUUID]];
}
#pragma mark -
#pragma mark 4.2.0 搜索服务结果(回调) + 5.1.0 搜索特性
#pragma mark -
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        switch (self.opType) {
            case HR_BT_OP_TPYE_R:
                if (self.readFailureBlock) {
                    self.readFailureBlock(error.localizedDescription);
                }
                break;
            case HR_BT_OP_TPYE_W:
                if (self.writeFailureBlock) {
                    self.writeFailureBlock(error.localizedDescription);
                }
                break;
            case HR_BT_OP_TPYE_N:
                if (self.notifyFailureBlock) {
                    self.notifyFailureBlock(error.localizedDescription);
                }
                break;
        }
        return;
    }
    //
    BOOL finded = NO;
    for (CBService * service in peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:self.sUUID]) {
            NSLog(@"响应(4.0)-服务-发现");
            NSLog(@"动作(5.0)-特性-搜索");
            finded = YES;
            CBUUID *characteristicUUID = [CBUUID UUIDWithString:self.cUUID];
            [peripheral discoverCharacteristics:@[characteristicUUID] forService:service];
        }
    }
    if (!finded) {
        switch (self.opType) {
            case HR_BT_OP_TPYE_R: {
                if (self.readFailureBlock) {
                    self.readFailureBlock(@"未搜索指定服务");
                }
            }
                break;
            case HR_BT_OP_TPYE_W: {
                if (self.writeFailureBlock) {
                    self.writeFailureBlock(@"未搜索指定服务");
                }
            }
                break;
            case HR_BT_OP_TPYE_N:
                if (self.notifyFailureBlock) {
                    self.notifyFailureBlock(error.localizedDescription);
                }
                break;
        }
    }
}
#pragma mark -
#pragma mark 5.2.0 搜索特性(回调) + 6.1.0 数据读写
#pragma mark -
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    //
    if (error) {
        switch (self.opType) {
            case HR_BT_OP_TPYE_R:
                if (self.readFailureBlock) {
                    self.readFailureBlock(error.localizedDescription);
                }
                break;
            case HR_BT_OP_TPYE_W:
                if (self.writeFailureBlock) {
                    self.writeFailureBlock(error.localizedDescription);
                }
                break;
            case HR_BT_OP_TPYE_N:
                if (self.notifyFailureBlock) {
                    self.notifyFailureBlock(error.localizedDescription);
                }
                break;
        }
        return;
    }
    //
    BOOL finded = NO;
    for (CBCharacteristic * characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:self.cUUID]) {
            finded = YES;
            NSLog(@"响应(5.2.0)-特性发现");
            switch (_opType) {
                case HR_BT_OP_TPYE_R: {
                    // 读取数据
                    if (characteristic.properties & CBCharacteristicPropertyRead) {
                        NSLog(@"动作(6.1.1)-数据读取");
                        [peripheral readValueForCharacteristic:characteristic];
                    } else {
                        if (self.readFailureBlock) {
                            self.readFailureBlock(@"该特征不可执行读操作");
                        }
                    }
                }
                    break;
                case HR_BT_OP_TPYE_W: {  // 写入数据
                    if (characteristic.properties & CBCharacteristicPropertyWrite) {
                        NSLog(@"动作(6.1.2)-数据写入");
                        [peripheral writeValue:self.writeData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    } else {
                        if (self.writeFailureBlock) {
                            self.writeFailureBlock(@"该特征不可执写入操作");
                        }
                    }
                }
                    break;
                case HR_BT_OP_TPYE_N: {
                    if (characteristic.properties & CBCharacteristicPropertyWrite || characteristic.properties & CBCharacteristicPropertyNotify) {
                        //
                        NSLog(@"动作(6.1.3)-数据通知");
                        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                        [peripheral writeValue:self.notifyWriteData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                        
                    } else {
                        if (self.notifyFailureBlock) {
                            self.notifyFailureBlock(@"该特征不可执行通知操作");
                        }
                    }
                    break;
                }
            }
        }
    }
    if (!finded) {
        switch (self.opType) {
            case HR_BT_OP_TPYE_R: {
                if (self.readFailureBlock) {
                    self.readFailureBlock(@"未搜索指定特征");
                }
            }
                break;
            case HR_BT_OP_TPYE_W: {
                if (self.writeFailureBlock) {
                    self.writeFailureBlock(@"未搜索指定特征");
                }
            }
                break;
            case HR_BT_OP_TPYE_N:
                if (self.notifyFailureBlock) {
                    self.notifyFailureBlock(@"未搜索指定特征");
                }
                break;
        }
    }
}

#pragma mark - 6.2.1 数据-读取(回调)
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    NSLog(@"响应(6.2.1)-数据-读取完成");
    if (!error) {
//        NSLog(@"响应(6.2.1.1)-数据-读取成功");
        NSString *characteristicHexString = [characteristic.value HR_HexString];
//        NSLog(@"特征数据(Hex):%@", characteristicHexString);
        if (characteristic.properties & 0x10) {
            if (self.notifyUpdateBlock) {
                self.notifyUpdateBlock(characteristicHexString);
            }
        } else {
            if (self.readSuccessBlock) {
                self.readSuccessBlock(characteristicHexString);
            }
        }
    } else {
        NSLog(@"响应(6.2.1.2)-数据-读取失败");
        if (characteristic.properties & 0x10) {
            if (self.notifyFailureBlock) {
                self.notifyFailureBlock(error.localizedDescription);
            }
        } else {
            if (self.readFailureBlock) {
                self.readFailureBlock(error.localizedDescription);
            }
        }
    }
}

#pragma mark 6.2.2 数据-写入(回调)
/** 写入数据回调 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"响应(6.2.2)-数据-写入完成");
    if (!error) {
        NSLog(@"响应(6.2.2.1)-数据-写入成功");
        if (characteristic.properties & 0x10) {
            if (self.notifySuccessBlock) {
                self.notifySuccessBlock();
            }
        } else {
            if (self.writeSuccessBlock) {
                self.writeSuccessBlock();
            }
        }
    } else {
        NSLog(@"响应(6.2.2.2)-数据-写入失败");
        if (characteristic.properties & 0x10) {
            if (self.notifyFailureBlock) {
                self.notifyFailureBlock(error.localizedDescription);
            }
        } else {
            if (self.writeFailureBlock) {
                self.writeFailureBlock(error.localizedDescription);
            }
        }
    }
}

#pragma mark 6.2.3 数据-通知(回调)

#pragma mark - Lazy

- (NSMutableArray<CBPeripheral *> *)scanPeripherals {
    if (!_scanPeripherals) {
        _scanPeripherals = [NSMutableArray array];
    }
    return _scanPeripherals;
}

@end

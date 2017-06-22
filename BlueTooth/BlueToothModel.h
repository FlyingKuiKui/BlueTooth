//
//  BlueToothModel.h
//  BlueTooth
//
//  Created by 王盛魁 on 2017/6/22.
//  Copyright © 2017年 WangShengKui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CBPeripheral.h>

@interface BlueToothModel : NSObject
@property (nonatomic, copy) NSString *name;  /**< 设备名称 */
@property (nonatomic, copy) NSString *identifier; /**< 设备标识 */
@property (nonatomic, assign) BOOL isConnectable; /**< 设备是否可链接 */
@property (nonatomic, copy) NSNumber *RSSI; /**< 设备信号强度 */

@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,copy) NSDictionary *advertisementData;

- (void)setModelWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

@end

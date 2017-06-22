//
//  BlueToothModel.m
//  BlueTooth
//
//  Created by 王盛魁 on 2017/6/22.
//  Copyright © 2017年 WangShengKui. All rights reserved.
//

#import "BlueToothModel.h"

@implementation BlueToothModel
- (void)setModelWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    self.peripheral = peripheral;
    if (peripheral.name == NULL) {
        self.name = @"未知设备";
    }else{
        self.name = peripheral.name;
    }
    self.identifier = peripheral.identifier.UUIDString;
    if ([advertisementData.allKeys containsObject:@"kCBAdvDataIsConnectable"]) {
        NSInteger intConnectable = [[advertisementData objectForKey:@"kCBAdvDataIsConnectable"] integerValue];
        self.isConnectable = (intConnectable == 1) ? YES:NO;
    }else{
        self.isConnectable = nil;
    }
    self.advertisementData = advertisementData;
    self.RSSI = [NSNumber numberWithInt:abs([RSSI intValue])];
}
@end

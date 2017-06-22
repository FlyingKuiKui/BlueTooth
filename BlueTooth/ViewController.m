//
//  ViewController.m
//  BlueTooth
//
//  Created by 王盛魁 on 2017/6/22.
//  Copyright © 2017年 WangShengKui. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BlueToothModel.h"
#import "tableViewCell.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) CBCentralManager *manager;
@property (nonatomic,strong) CBPeripheral *connectPeripheral;

@property (nonatomic,strong) NSMutableArray *peripheralArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[tableViewCell class] forCellReuseIdentifier:@"CELL"];
    [self.view addSubview:self.tableView];
    self.peripheralArray = [NSMutableArray array];
    self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)addNewServicesToArrayWithModel:(BlueToothModel *)model{
    NSLog(@"\n设备名称：%@\n设备识别码：%@\n设备是否可连接：%d\n设备信号强度：%@db\nadvertisementData:%@",model.name,model.identifier,model.isConnectable,model.RSSI,model.advertisementData);
    BOOL isAlreadyAdd = NO;
    for (int i = 0; i< self.peripheralArray.count; i++) {
        BlueToothModel *oldModel = self.peripheralArray[i];
        if ([oldModel.identifier isEqualToString:model.identifier]) {
            isAlreadyAdd = YES;
            break;
        }
    }
    if (isAlreadyAdd == NO) {
        [self.peripheralArray addObject:model];
        [self.tableView reloadData];
    }
}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.peripheralArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    tableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    BlueToothModel *model = [self.peripheralArray objectAtIndex:indexPath.row];
    cell.textLabel.text = model.name;
    return cell;
}
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.manager stopScan];
    if (self.connectPeripheral != nil) {
        [self.manager cancelPeripheralConnection:self.connectPeripheral];
        self.connectPeripheral = nil;
    }
    BlueToothModel *model = [self.peripheralArray objectAtIndex:indexPath.row];
    if (model.isConnectable) {
        [self.manager connectPeripheral:model.peripheral options:nil];
        self.connectPeripheral = model.peripheral;
    }else{
        NSLog(@"当前设备不可链接");
    }
}

#pragma mark - CBCentralManagerDelegate
// 主设备状态改变的代理，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
// 必须实现
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@">>>CBManagerStateUnknown");
            break;
        case CBManagerStateResetting:
            NSLog(@">>>CBManagerStateResetting");
            break;
        case CBManagerStateUnsupported:
            NSLog(@">>>CBManagerStateUnsupported");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@">>>CBManagerStateUnauthorized");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@">>>CBManagerStatePoweredOff");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@">>>CBManagerStatePoweredOn");
            //开始扫描周围的外设
            /* 第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入 */
            /*
             小米：FEE0
             */
            [central scanForPeripheralsWithServices:nil options:nil];
            //            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FEE0"]] options:nil];
            //            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FEE0"]]  options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
            break;
        default:
            break;
    }
}
//找到外设的方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    //接下连接我们的测试设备
    BlueToothModel *model = [[BlueToothModel alloc]init];
    [model setModelWithPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    [self addNewServicesToArrayWithModel:model];
    /*
     对象peripheral内包含多个外接设备的值：
        外接设备名称：peripheral.name
        外接设备识别码：peripheral.identifier
     字典advertisementData内包含以下几个字段：
        kCBAdvDataIsConnectable：外接设备是否可连接 1可以 0不可；
     这个值在搜索外接设备时肯定会存在，以下的几个字段在搜索到本人的电脑时就不存在，在搜索到的小米手环时就存在。
        kCBAdvDataLocalName：外接设备内置的名称
        kCBAdvDataManufacturerData：外接设备生产商数据
        kCBAdvDataServiceUUIDs：设备的UUIDService
     最后一个值RRSI：外接设备的信号强度，获取的值为负数，可以做以下处理，同时可以根据信号强度大致估计外接设备与设备之间的距离
     利用绝对值方法处理：abs([RSSI intValue])
     */
}   
//连接外设成功的方法
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    //设置的peripheral代理CBPeripheralDelegate
    [peripheral setDelegate:self];
    // 扫描外设Services,成功进入CBPeripheralDelegate代理内
    // - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error;
    [peripheral discoverServices:nil];
    
}
//外设连接失败的方法
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}
//断开外设的方法
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    if (error){
        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    for (CBService *service in peripheral.services) {
        NSLog(@"%@",service.UUID);
        /* 扫描每个service的Characteristics，扫描到后会进入方法：
         -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
         */
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"2A23"]] forService:service];
    }
}
#pragma mark - 4.2 获取外设的Characteristics,获取Characteristics的值，获取Characteristics的Descriptor和Descriptor的值
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error){
        NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics){
        NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
    }
    
    /*获取Characteristic的值，读到数据会进入方法：
     -(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     */
//    for (CBCharacteristic *characteristic in service.characteristics){
//        [peripheral readValueForCharacteristic:characteristic];
//    }
    /*搜索Characteristic的Descriptors，读到数据会进入方法：
     -(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     */
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}
//获取的charateristic的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);
    
}
//搜索到Characteristic的Descriptors
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出Characteristic和他的Descriptors
    NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }
    
}
//获取到Descriptors的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}
#pragma mark - 5 把数据写到Characteristic中
//写数据
- (void)writeCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic
                      value:(NSData *)value{
    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前两个是读写权限，后两个都是通知，两种不同的通知方式。
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast                                              = 0x01,
     CBCharacteristicPropertyRead                                                   = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse                                   = 0x04,
     CBCharacteristicPropertyWrite                                                  = 0x08,
     CBCharacteristicPropertyNotify                                                 = 0x10,
     CBCharacteristicPropertyIndicate                                               = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites                              = 0x40,
     CBCharacteristicPropertyExtendedProperties                                     = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)  = 0x200
     };
     
     */
    NSLog(@"%lu", (unsigned long)characteristic.properties);
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"该字段不可写！");
    }
}
#pragma mark - 6 订阅Characteristic的通知
//设置通知
- (void)notifyCharacteristic:(CBPeripheral *)peripheral
              characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}
//取消通知
- (void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                    characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}
#pragma mark - 7 断开连接
//停止扫描并断开连接
- (void)disconnectPeripheral:(CBCentralManager *)centralManager
                  peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

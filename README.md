# BleDemo
swfit bluetooth demo

主要是用swift写的ble的demo; ble看明白，很简单，调试下；看看结果就知道了
参考如下: 
[https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothOverview/CoreBluetoothOverview.html#//apple_ref/doc/uid/TP40013257-CH2-SW1](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothOverview/CoreBluetoothOverview.html#//apple_ref/doc/uid/TP40013257-CH2-SW1)

[http://southpeak.github.io/blog/2014/07/29/core-bluetoothkuang-jia-zhi-%5B%3F%5D-:centralyu-peripheral/](http://southpeak.github.io/blog/2014/07/29/core-bluetoothkuang-jia-zhi-%5B%3F%5D-:centralyu-peripheral/)

[https://github.com/coolnameismy/BabyBluetooth](https://github.com/coolnameismy/BabyBluetooth)
BabyBluetooth 做了一个简单的封装，可以参考下；但针对swift,需要注意使用；例如:

![BabyBluetooth code](https://github.com/kuanglijun312/BleDemo/blob/master/screenshots/code1.jpg)

下面是一些swift的代码:
`
	// 设备状态变动
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            self.reloadAction("设备打开成功")
            //扫描设备(server)
            central.scanForPeripheralsWithServices(nil, options: nil)
            
            self.bleButton.setTitle("关闭设备", forState: UIControlState.Normal)
            
        case CBCentralManagerState.PoweredOff:
            self.reloadAction("设备已关闭")
            self.bleButton.setTitle("开启设备", forState: UIControlState.Normal)
        case CBCentralManagerState.Unsupported:
            self.reloadAction("设备不支持")
        default:
            break
        }
    }
    
    //发现设备
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        self.reloadAction("搜索到了设备:\(peripheral.name)")
        if peripheral.name != nil && peripheral.name == "weigher" {
            self.currentPeripheral = peripheral
            //找到，就停止扫描
            central.stopScan()
            //连接设备，options -- 传递nil，则管理器会返回所有发现的Peripheral设备,可传递一个指定的uuid的数组，查找特定的设备
            central.connectPeripheral(peripheral, options: nil)
        }
    }
    
    //已连接设备
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        self.reloadAction("设备：\(peripheral.name)--连接成功")
        peripheral.delegate = self
        //去发现服务
        peripheral.discoverServices(nil)
        isLinkPeripheral = true
    }
    
    //取消连接设备
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        if error == nil {
            self.reloadAction("设备：\(peripheral.name)--取消连接成功")
            isLinkPeripheral = false
        } else {
            self.reloadAction("设备：\(peripheral.name)--取消连接失败:(\(error.description))")
        }
    }
    
    //发现服务
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        for service in peripheral.services as! [CBService] {
            self.reloadAction("搜索到服务:\(service.UUID.UUIDString)")
            //去发现特征
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    //发现特征
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        for characteristic in service.characteristics as! [CBCharacteristic] {
            self.reloadAction("特征名称:\(characteristic.UUID)")
            peripheral.readValueForCharacteristic(characteristic)
            if characteristic.UUID.UUIDString == Notify_Characteristic_UUID {
                self.notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            } else if characteristic.UUID.UUIDString == Battery_Characteristic_UUID {
                self.batteryCharacteristic = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            } else if characteristic.UUID.UUIDString == Hand_Characteristic_UUID {
                self.writeCharacteristic = characteristic
            } else if characteristic.UUID.UUIDString == Reset_Characteristic_UUID {
                self.resetCharacteristic = characteristic
            }
        }
        
    }
    
    //读取到特征的值-- 注意，只有在连接成功的时候，读取到； 若要监听，使用Notify
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if characteristic.value != nil {
            let data = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)
            if let val = data {
                self.reloadValue("特征(\(characteristic.UUID))的值:\(val)")
	//                if characteristic.UUID.UUIDString == "FFF4" {
	//                    self.reloadValue("监听特征(\(characteristic.UUID))的值:\(val)")
	//                }
            }
        }
    }
    
    //监听特征delegate
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
	//        self.reloadValue("监听特征(\(characteristic.UUID))的值:\(characteristic.value)")
        if error != nil {
            self.reloadAction("订阅特征(\(characteristic.UUID))失败:\(error.description):\(error.description)")
        } else {
            if characteristic.UUID.UUIDString == Notify_Characteristic_UUID {
                self.isNotify4 = !self.isNotify4
            } else if characteristic.UUID.UUIDString == Battery_Characteristic_UUID {
                self.isNotify5 = !self.isNotify5
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error == nil {
            self.reloadAction("写入特征(\(characteristic.UUID))值\(characteristic.value)成功!")
        } else {
            self.reloadAction("写入特征(\(characteristic.UUID))值\(characteristic.value)失败!")
        }
    }

`


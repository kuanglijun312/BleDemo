//
//  ViewController.swift
//  BleDemo
//
//  Created by zm002 on 15/9/23.
//  Copyright (c) 2015年 zm002. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,CBCentralManagerDelegate,CBPeripheralDelegate {

    @IBOutlet weak var bleButton: UIButton!
    @IBOutlet weak var writeButton: UIButton!
    
    @IBOutlet weak var dataTableView: UITableView!
    @IBOutlet weak var actionTableView: UITableView!
    @IBOutlet weak var dataTextField: UITextField!
    @IBOutlet weak var resetTextField: UITextField!
    
    @IBOutlet weak var notify4button: UIButton!
    @IBOutlet weak var notify5button: UIButton!
    
    
    var actionList = [String]()
    var dataList = [String]()
    
    var isOn = false
    
    let Notify_Characteristic_UUID = "FFF4"
    let Battery_Characteristic_UUID = "FFF5"
    let Hand_Characteristic_UUID = "FFF1"
    let Reset_Characteristic_UUID = "FFF3"
    
    var centralManager:CBCentralManager!
    var currentPeripheral:CBPeripheral!
    var notifyCharacteristic:CBCharacteristic!
    var batteryCharacteristic:CBCharacteristic!
    var writeCharacteristic:CBCharacteristic!
    var resetCharacteristic:CBCharacteristic!
    
    
//    var bleState:CBCentralManagerState!
    var isLinkPeripheral:Bool = false {
        didSet {
            if isLinkPeripheral {
                self.bleButton.setTitle("取消连接设备", forState: UIControlState.Normal)
            } else {
                self.bleButton.setTitle("连接设备", forState: UIControlState.Normal)
            }
        }
    }
    var isNotify4:Bool = false {
        didSet {
            if isNotify4 {
                self.notify4button.setTitle("取消监听FFF4", forState: UIControlState.Normal)
            } else {
                self.notify4button.setTitle("监听FFF4", forState: UIControlState.Normal)
            }
        }
    }
    var isNotify5:Bool = false {
        didSet {
            if isNotify5 {
                self.notify4button.setTitle("取消监听FFF5", forState: UIControlState.Normal)
            } else {
                self.notify4button.setTitle("监听FFF5", forState: UIControlState.Normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.dataTableView.delegate = self
        self.dataTableView.dataSource = self
        self.actionTableView.delegate = self
        self.actionTableView.dataSource = self
        
        self.dataTableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentify)
        self.actionTableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: cellIdentify)
        
        //Central管理器 -- client
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        self.view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissKeyboard(gesture:UIGestureRecognizer) {
        self.view.endEditing(true)
    }

    @IBAction func bleHandleAction(sender: AnyObject) {
        if isLinkPeripheral {
            self.reloadAction("手动取消连接设备")
            self.bleButton.setTitle("连接设备", forState: UIControlState.Normal)
            self.centralManager.cancelPeripheralConnection(self.currentPeripheral)
        } else {
            self.reloadAction("手动连接设备")
            self.bleButton.setTitle("取消连接设备", forState: UIControlState.Normal)
            self.centralManager.connectPeripheral(self.currentPeripheral, options: nil)
        }
    }

    @IBAction func writeDataAction(sender: AnyObject) {
        if sender.tag == 1 {
            //握手
            if !self.dataTextField.text.isEmpty && self.writeCharacteristic != nil {
                self.reloadAction("写入握手数据:\(self.dataTextField.text)")
                self.currentPeripheral.writeValue((self.dataTextField.text as NSString).dataUsingEncoding(NSUTF8StringEncoding) , forCharacteristic: self.writeCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            }
        } else if sender.tag == 2 {
            //去皮
            if !self.resetTextField.text.isEmpty && self.resetCharacteristic != nil {
                self.reloadAction("写入去皮数据:\(self.resetTextField.text)")
                self.currentPeripheral.writeValue((self.resetTextField.text as NSString).dataUsingEncoding(NSUTF8StringEncoding) , forCharacteristic: self.resetCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            }
        }
    }
    
    @IBAction func notifyDataAction(sender: AnyObject) {
        if sender.tag == 4 {
            //监听fff4
            if isNotify4 {
                self.reloadAction("手动监听FFF4")
                self.currentPeripheral.setNotifyValue(false, forCharacteristic: self.notifyCharacteristic)
            } else {
                self.reloadAction("手动取消监听FFF4")
                self.currentPeripheral.setNotifyValue(true, forCharacteristic: self.notifyCharacteristic)
            }
        } else if sender.tag == 5 {
            //监听fff5
            if isNotify5 {
                self.reloadAction("手动监听FFF5")
                self.currentPeripheral.setNotifyValue(false, forCharacteristic: self.batteryCharacteristic)
            } else {
                self.reloadAction("手动取消监听FFF5")
                self.currentPeripheral.setNotifyValue(true, forCharacteristic: self.batteryCharacteristic)
            }
        }
    }
    
    
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
    
    private func reloadAction(str:String!) {
        if str == nil {
            actionList.removeAll(keepCapacity: false)
        } else {
            actionList.insert(str, atIndex: 0)
        }
        println("action: \(str)")
        self.actionTableView.reloadData()
    }
    
    private func reloadValue(str:String!) {
        if str == nil {
            dataList.removeAll(keepCapacity: false)
        } else {
            dataList.insert(str, atIndex: 0)
        }
        println("data: \(str)")
        self.dataTableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == actionTableView {
            return actionList.count
        }
        if tableView == dataTableView {
            return dataList.count
        }
        return 0
    }
    
    let cellIdentify = "cell"
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentify, forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        cell.textLabel?.font = UIFont.systemFontOfSize(11)
        
        if tableView == actionTableView {
            cell.textLabel?.text = actionList[indexPath.row]
        } else if tableView == dataTableView {
            cell.textLabel?.text = dataList[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 22))
        let titleView = UILabel(frame: headerView.frame)
        titleView.font = UIFont.systemFontOfSize(13)
        headerView.addSubview(titleView)
        headerView.backgroundColor = UIColor.blueColor()
        
        let clearButton = UIButton(frame: CGRectMake(headerView.frame.size.width - 60, 0, 60, headerView.frame.size.height))
        clearButton.setTitle("清除", forState: UIControlState.Normal)
        clearButton.titleLabel?.font = UIFont.systemFontOfSize(13)
        clearButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        headerView.addSubview(clearButton)
        
        if tableView == actionTableView {
            titleView.text = "操作"
            clearButton.addTarget(self, action: "clearActionTableView:", forControlEvents: UIControlEvents.TouchUpInside)
        } else if tableView == dataTableView {
            titleView.text = "数据"
            clearButton.addTarget(self, action: "clearDataTableView:", forControlEvents: UIControlEvents.TouchUpInside)
        }

        return headerView
    }
    
    func clearActionTableView(sender:UIButton) {
        self.reloadAction(nil)
    }
    
    func clearDataTableView(sender:UIButton) {
        self.reloadValue(nil)
    }
}


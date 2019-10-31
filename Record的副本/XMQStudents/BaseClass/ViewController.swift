//
//  ViewController.swift
//  XMQRecording
//
//  Created by bin xie on 2019/10/2.
//  Copyright © 2019 Xiaomuqin. All rights reserved.
//

import UIKit

class ViewController: UIViewController  {
    
    lazy var testIndex = Int()//调试用
    
//    lazy var dataTimer = Timer()
    lazy var gcdTimer = DispatchSource.makeTimerSource()
    
    lazy var dataIndex = Int()//给算法喂一次数据该对象加一（不包含漏检的次数）
    lazy var dataIndexArr = [Int]()//存储喂给算法的次数-用来和存储的音频数据对比确保存储的音频数据都喂给了算法
    lazy var isStop = Bool()
    lazy var txtDataArr = NSArray()
    lazy var bufferRefArr = [NSMutableData]()//存储麦克风接收的音频数据
    lazy var allCReturnArr = [Any]()//存储所有算法返回的数据-对应接收的音频数据
    lazy var backCIndexArr = [Any]()//存储每次传给H5时的算法返回的数据（算法返回的纯0数据不会传给H5）
    
    lazy var txtArr:[String] = ["车尔尼599-019","11_穿过云间","599-030","599-040","599-066","599-068","599-074-TR","849-14"]
    lazy var currentSong = NSInteger()
    
    lazy var recorder: XMQRecorder = {
        let recorder = XMQRecorder()
        recorder.currViewController = self
        recorder.recorderDelegate = self
        return recorder
    }()
    
    lazy var saveBtn: UIButton = {
        let saveBtn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 120, height: 40))
        saveBtn.setTitle("上传数据文件", for: .normal)
        saveBtn.layer.cornerRadius = 8
        saveBtn.backgroundColor = UIColor.black
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        saveBtn.tag = 100
        return saveBtn
    }()

    lazy var recordBtn: UIButton = {
        let recordBtn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 60, height: 40))
        recordBtn.backgroundColor = UIColor.black
        recordBtn.setTitle("录音", for: .normal)
        recordBtn.setTitleColor(.white, for: .normal)
        recordBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        recordBtn.layer.cornerRadius = 8
        recordBtn.tag = 101
        return recordBtn
    }()

    lazy var stopRecordBtn: UIButton = {
        let stopRecordBtn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 60, height: 40))
        stopRecordBtn.backgroundColor = UIColor.black
        stopRecordBtn.setTitle("暂停", for: .normal)
        stopRecordBtn.setTitleColor(.white, for: .normal)
        stopRecordBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        stopRecordBtn.layer.cornerRadius = 8
        stopRecordBtn.tag = 102
        return stopRecordBtn
    }()
    
    lazy var changeSongBtn: UIButton = {
        let changeSongBtn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 60, height: 40))
        changeSongBtn.backgroundColor = UIColor.black
        changeSongBtn.setTitle("切歌", for: .normal)
        changeSongBtn.setTitleColor(.white, for: .normal)
        changeSongBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        changeSongBtn.layer.cornerRadius = 8
        changeSongBtn.tag = 103
        return changeSongBtn
    }()
    
    lazy var changeSongView: UITableView = {
        let changeSongView = UITableView.init(frame: CGRect.init(x: 0, y: 64, width: Int(ScreenSize().screenW), height: 44*txtArr.count))
        changeSongView.dataSource = (self as UITableViewDataSource)
        changeSongView.delegate = (self as UITableViewDelegate)
        changeSongView.isHidden = true
        return changeSongView;
    }()
    
    lazy var webView: RSWKWebView = {
            let webView = RSWKWebView.init(frame: view.bounds)
            return webView
     }()
    
    // pragma MARK: -------------------- life cycle --------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        currentSong = 0
//        sendTxtDataToC(name: txtArr[currentSong])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearCache()
    }
    
    deinit {
        recorder.removeObserver(self, forKeyPath: "changeIndex")
    }
}

// pragma MARK: -------------------- getter/setter ---------------------

extension ViewController {
    
    private func setupView() {
        view.backgroundColor = .white
        view.addSubview(webView)
        let leftBarItem1 = UIBarButtonItem.init(customView: saveBtn)
        let leftBarItem2 = UIBarButtonItem.init(customView: changeSongBtn)
        navigationItem.leftBarButtonItems  = [leftBarItem1,leftBarItem2]
        let rightBarItem1 = UIBarButtonItem.init(customView: recordBtn)
        let rightBarItem2 = UIBarButtonItem.init(customView: stopRecordBtn)
        navigationItem.rightBarButtonItems = [rightBarItem1,rightBarItem2]
        
        saveBtn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        recordBtn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        stopRecordBtn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        changeSongBtn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        
        recorder.addObserver(self, forKeyPath: "changeIndex", options: [.new], context: nil)
        
        webView.addSubview(changeSongView)
        changeSongView.reloadData()
        
    }
    
    private func sendTxtDataToC(name:String) {
        
        let path = Bundle.main.path(forResource: name, ofType: "txt")
        let url = URL(fileURLWithPath: path!)
        let data = try! Data(contentsOf: url)
        let textData = NSString.init(data: data, encoding: String.Encoding.utf8.rawValue)
        txtDataArr = getArrayFromJSONString(jsonString: textData! as String)
        recorder.toCBasisArray(txtDataArr.firstObject as! [Any],
                               withAscendingArr: txtDataArr[1] as! [Any])
    }
    
    private func aliyunWithFileName() {
                
        let formatter: DateFormatter = DateFormatter()
        /// 设置时间格式
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: NSDate() as Date)
        let name = "\(dateString)"
        //
        let volumeName = String(describing: "iOSXMQRecord"+name).appending(".wav")
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                        .userDomainMask,
                                                        true).first?.appending("/record.wav")
        let volumeData = NSData.init(contentsOfFile: paths!)
        //
        let indexTxtName = String(describing: "iOSXMQRecord"+name).appending("indexArr.txt")
        let indexTxtPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                               .userDomainMask,
                                                               true).first?.appending("/indexArr.txt")
        let backIndexArr: NSArray = backCIndexArr as NSArray
        backIndexArr.write(toFile: indexTxtPath!, atomically: true)
        let indexTxtData = NSData.init(contentsOfFile: indexTxtPath!)
        
        //
//        let doubleArrName = String(describing: "iOSXMQRecord"+name).appending("doubleArr.txt")
//        let doubleArrPaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
//                                                                 .userDomainMask,
//                                                                 true).first?.appending("/doubleArr.txt")
//        let doubleArrData = NSData.init(contentsOfFile: doubleArrPaths!)
        if volumeData != nil
        {
            UIApplication.shared.keyWindow?.showHud(isCovered: true)
            
            //创建一个并行队列
            let queue = DispatchQueue(label: "haha", attributes: .concurrent)
            queue.async {

                XMQAliyunOSS.share.uploadObjectAsync(indexTxtData! as Data, indexTxtName)
                XMQAliyunOSS.share.uploadObjectAsync(volumeData! as Data, volumeName)
                //            if (doubleArrData != nil) {
                //                XMQAliyunOSS.share.uploadObjectAsync(doubleArrData! as Data, doubleArrName)
                //            }
                
                self.dataIndexArr.removeAll()
                self.backCIndexArr.removeAll()
                self.bufferRefArr.removeAll()
                self.dataIndex = 0
                self.clearCache()

                DispatchQueue.main.async {
                    UIApplication.shared.keyWindow?.hideHud()
                }
                showTextHUD("上传成功")
            }

        }
        
    }
    
    private func saveWav() {
        
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                               .userDomainMask,
                                                               true).first?.appending("/record.pcm")
        recorder.createPlayableFile(fromPcmData: paths!)
        showTextHUD("数据保存完成")

    }
}

// pragma MARK: ----------------------- Action -------------------------
extension ViewController {
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        if keyPath == "changeIndex"
        {
            dataIndex += 1
        }
    }
    
    @objc
    private func btnAction(button: UIButton) {
                    
        switch button.tag
        {
        case 100:
            
            aliyunWithFileName()

        case 101:
            sendTxtDataToC(name: txtArr[currentSong])
            recordBtn.isEnabled = false
            recordBtn.backgroundColor = .red
            recordBtn.setTitle("录音中...", for: .normal)
            isStop = false
            recorder.startRecord()
            openTimer()
            changeSongBtn.isEnabled = false
            
        case 102:
            recordBtn.isEnabled = true
            recordBtn.backgroundColor = .black
            recordBtn.setTitle("录音", for: .normal)
            webView.reloadWeb(number: txtArr[currentSong])
            isStop = true
            recorder.stopRecord()
            saveWav()
            changeSongBtn.isEnabled = true
//            //重新调取算法的初始化方法-目的-下次播放从头播放
//            sendTxtDataToC(name: txtArr[currentSong])
            UserDefaults.standard.set(nil, forKey: "fragment")
            UserDefaults.standard.synchronize()
            
            if dataIndexArr.count == bufferRefArr.count
            {
                stopTimer()
                print("---------停止录音-----------")
            }
            
        case 103:
            if changeSongView.isHidden == true {
                changeSongView.isHidden = false
            }else{
                changeSongView.isHidden = true
            }
            
        default:
            break
        }
    }
    
    private func openTimer() {
        
        gcdTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        gcdTimer.schedule(deadline: .now(), repeating: 0.015)
        gcdTimer.setEventHandler {
            DispatchQueue.main.async {
                self.audioBufferToC()
//                print("======")
            }
        }
        gcdTimer.resume()
        
//        dataTimer = Timer.init(timeInterval: 0.0015,
//                               target: self,
//                               selector: #selector(audioBufferToC),
//                               userInfo: nil,
//                               repeats: true)
//        RunLoop.main.add(dataTimer, forMode: .common)
        
    }
    
    private func stopTimer() {
//        dataTimer.invalidate()
        gcdTimer.cancel()
    }
        
    @objc func audioBufferToC() {
        if dataIndex < bufferRefArr.count && !dataIndexArr.contains(dataIndex)
        {
            dataIndexArr.append(dataIndex)
            //pragma MARK: 把接收的音频数据喂给算法（单独一个线程-采用NSTimer定时器）
            recorder.processAudioBuffer(bufferRefArr[dataIndex])
        }else{
            if isStop {
                gcdTimer.cancel()
            }
        }
    }
}

// pragma MARK: ------------------- private Method -------------------

extension ViewController {
    
    /// 类型转换：String 转为 Int
    private func stringForInt(str: String) -> Int {
        
        let string = str
        var int: Int?
        
        if let intValue = Int(string)
        {
            int = Int(intValue)
        }
        
        if int == nil
        {
            return 0
        }
        
        return int!
    }
    
    private func clearCache() {
        
        // 取出cache文件夹目录 缓存文件都在这个目录下
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        // 取出文件夹下所有文件数组
        let fileArr = FileManager.default.subpaths(atPath: cachePath!)
        // 遍历删除
        for file in fileArr!
        {
            let path = cachePath! + "/" + file
            
            if FileManager.default.fileExists(atPath: path)
            {
                do{
                    try FileManager.default.removeItem(atPath: path)
                }catch{
                    
                }
            }
        }
        
    }
}

// pragma MARK: -------------------- Delegate ----------------------

extension ViewController: XMQRecorderDelegate {
    
    func manualCallAudioBufferToC() {
        audioBufferToC()//喂数据方法
    }
    
    func getLoseDataArr(_ indexArr: [Any]) -> NSMutableData {
        
        let fiveIndex = indexArr[5] as! NSInteger
        let sixIndex = indexArr[6] as! NSInteger
        let differ = sixIndex-fiveIndex

        var one = NSMutableData()
        var two = NSMutableData()
        var three = NSMutableData()
        var four = NSMutableData()
        var five = NSMutableData()
        var six = NSMutableData()
        var seven = NSMutableData()
        var eight = NSMutableData()
        
        if differ < 16 || (differ>=16 && fiveIndex == 0){
            
            one.resetBytes(in: NSRange.init(location: 0, length: one.length))
            one = bufferRefArr[sixIndex-8]
            two = bufferRefArr[sixIndex-7]
            three = bufferRefArr[sixIndex-6]
            four = bufferRefArr[sixIndex-5]
            five = bufferRefArr[sixIndex-4]
            six = bufferRefArr[sixIndex-3]
            seven = bufferRefArr[sixIndex-2]
            eight = bufferRefArr[sixIndex-1]
            
        }else{
            
            let newStart = differ/2 + fiveIndex
            one.resetBytes(in: NSRange.init(location: 0, length: one.length))
            one = bufferRefArr[newStart]
            two = bufferRefArr[newStart+1]
            three = bufferRefArr[newStart+2]
            four = bufferRefArr[newStart+3]
            five = bufferRefArr[newStart+4]
            six = bufferRefArr[newStart+5]
            seven = bufferRefArr[newStart+6]
            eight = bufferRefArr[newStart+7]
            
        }
        
        one.append(two as Data)
        one.append(three as Data)
        one.append(four as Data)
        one.append(five as Data)
        one.append(six as Data)
        one.append(seven as Data)
        one.append(eight as Data)
        
        return one
    }
    
    
    func returnAudioBufferData(_ bufferData: NSMutableData) {
        //pragma MARK: 接收音频数据（单独一个线程）
        if isStop == false{
            bufferRefArr.append(bufferData)
        }
    }
    
    func returnAllProcessIndexArr(_ indexArr: [Any]) {
        if isStop == false {
            allCReturnArr.append(indexArr)
        }
    }
    
    func returnProcessIndexArr(_ indexArr: [Any]) {
        //pragma MARK:将录音数据存入数组，1.如果查询丢失的数据就从这个数组里面查询;2.如果需要把数据存入阿里云也是用这个数组
        backCIndexArr.append(indexArr)

        if isStop && dataIndexArr.count == bufferRefArr.count
        {
            stopTimer()
        }
        
        //pragma MARK: 算法返回的数据传给H5
        DispatchQueue.global(qos: .default).async {
                        
            let firstIndex = indexArr[0] as! NSNumber
//            let secondDataArr = self.txtDataArr[1] as! Array<Any>
            let threeDataArr = self.txtDataArr[2] as! Array<Any>
            var index = Int()
            
            for number in indexArr
            {
                if self.stringForInt(str: "\(number)") == 0
                {
                    index += 1
                }
            }
            
            if firstIndex != 0 && index < 8
            {
                let arrIndex = self.stringForInt(str: "\(firstIndex)")-1
                
                let h5Dict = ["isNoteRight"  : indexArr[2],
                              "notePosition" : [threeDataArr[arrIndex]]] as [String : Any]
                let jsString = getJSONStringFromDictionary(h5Dict)
                
                DispatchQueue.main.async {
                    
                    self.webView.webView.evaluateJavaScript("GET_STAFF_DATA('\(jsString)')", completionHandler: { (result, error) in
//                        debugPrint("h5..........................",result as Any,error as Any,self.dataIndex)
                    })
                }
//                DispatchQueue.main.suspend()//暂停该队列
//                DispatchQueue.main.resume()//继续该队列
            }
        }
        //
        
//        DispatchQueue.global(qos: .default).async {
//
//            let firstIndexArr = indexArr.first as! Array<Any>
//            let lastIndexArr = indexArr.last as! Array<Any>
//            let secondDataArr = self.txtDataArr[1] as! Array<Any>
//            let threeDataArr = self.txtDataArr[2] as! Array<Any>
//            let arrIndex = firstIndexArr[3] as! Int
//            let locationIndex = firstIndexArr[6] as! Int
//            let lengthIndex = firstIndexArr[5] as! Int
//            let lastIndex = lengthIndex > lastIndexArr.count ? lastIndexArr.count : lengthIndex
//            var matchingResultArr = [Any]()
//
//            for i in 0..<lastIndex
//            {
//                matchingResultArr.append(lastIndexArr[i])
//            }
//
//            let h5Dict = ["isNoteRight"           : self.stringToInt(str: "\(firstIndexArr[0])")-1,
//                          "notesWrongType"        : firstIndexArr[1],
//                          "playTypes"             : firstIndexArr[2],
//                          "notePosition"          : [secondDataArr[arrIndex],threeDataArr[arrIndex]],
//                          "positionState"         : firstIndexArr[4],
//                          "positionResults"       : firstIndexArr[5],
//                          "positionLocation"      : [secondDataArr[locationIndex],threeDataArr[locationIndex]],
//                          "locationMatchingResult": matchingResultArr] as [String : Any]
//            let jsString = getJSONStringFromDictionary(h5Dict)
//            self.webView.webView.evaluateJavaScript("GET_STAFF_DATA('\(jsString)')", completionHandler: { (result, error) in
//
////                debugPrint(result as Any,error as Any,"========")
//            })
//        }
    }
    
    
}

extension ViewController:UITableViewDataSource,UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return txtArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellid = "songCellID"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellid)
        if cell==nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellid)
        }
        if txtArr.count > 0 {
            cell?.detailTextLabel?.text = txtArr[indexPath.row]
        }
        return cell!
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeSongView.isHidden = true
        if currentSong != indexPath.row {
            currentSong = indexPath.row
            sendTxtDataToC(name: txtArr[currentSong])
            webView.reloadWeb(number: txtArr[currentSong])
        }
    }
    
}

// pragma MARK: ------------------ Network Request -----------------

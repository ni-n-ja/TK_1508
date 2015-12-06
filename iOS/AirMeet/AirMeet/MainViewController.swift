//
//  ViewController.swift
//  AirMeet
//
//  Created by koooootake on 2015/11/28.
//  Copyright © 2015年 koooootake. All rights reserved.
//

import UIKit
import CoreLocation

class MainViewController: UIViewController,UITableViewDelegate, UITableViewDataSource ,CLLocationManagerDelegate,ENSideMenuDelegate,NSURLSessionDelegate,NSURLSessionDataDelegate{
    
    let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //送信機側と合わせるUUID
    let proximityUUID = NSUUID(UUIDString:"B9407F30-F5F8-466E-AFF9-33333B57FE6D")
    var region  = CLBeaconRegion()//UUIDの設定
    var manager = CLLocationManager()//iBeconを操作
    
    //majorIDリスト
    var majorIDList:[NSNumber] = []
    var majorIDListOld:[NSNumber] = []
    
    @IBOutlet weak var backImageView: UIImageView!//背景画像
    @IBOutlet weak var userImageView: UIImageView!//ユーザ画像
    
    @IBOutlet weak var nameLabel: UILabel!//ユーザ名
    @IBOutlet weak var detailLabel: UILabel!//自己紹介
    
    @IBOutlet weak var profileChangeButton: UIButton!
    
    @IBOutlet weak var facebookLinkLabel: UILabel!
    @IBOutlet weak var twitterLinkLabel: UILabel!
    
    @IBOutlet weak var MenuBarButtonItem: UIBarButtonItem!//保留
    
    @IBOutlet weak var EventTableView: UITableView!
    var events:[EventModel] = [EventModel]()
    
    //くるくる
    let indicator:SpringIndicator = SpringIndicator()
    
    //Viewの初回読み込み
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //よこからメニューのdelegate
        self.sideMenuController()?.sideMenu?.delegate = self
        
        //Navigationbar色
        self.navigationController?.navigationBar.barTintColor=UIColor(red: 128.0/255.0, green: 204.0/255.0, blue: 223.0/255.0, alpha: 1)//水色
        self.navigationController?.navigationBar.tintColor=UIColor.whiteColor()
        
        //Navigationbar画像
        let titleImageView = UIImageView( image: UIImage(named: "AirMeet-white.png"))
        titleImageView.contentMode = .ScaleAspectFit
        titleImageView.frame = CGRectMake(0, 0, self.view.frame.width, self.navigationController!.navigationBar.frame.height*0.8)
        self.navigationItem.titleView = titleImageView
        
        //子供モード、親モードか否か
        appDelegate.isChild = false
        appDelegate.isParent = false
        appDelegate.isBeacon = true
        
        EventTableView.delegate = self
        EventTableView.dataSource = self
        
        //アイコンまるく
        userImageView.layer.cornerRadius = userImageView.frame.size.width/2.0
        userImageView.layer.masksToBounds = true
        userImageView.layer.borderColor = UIColor.whiteColor().CGColor
        userImageView.layer.borderWidth = 3.0
        
        //プロフィール変更ボタン
        profileChangeButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        profileChangeButton.layer.borderWidth = 1.0
        
        //戻るボタン設定
        let backButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        
        //ぐるぐる設定
        indicator.frame = CGRectMake(self.view.frame.width/2-self.view.frame.width/8,self.view.frame.height/2-self.view.frame.width/8,self.view.frame.width/4,self.view.frame.width/4)
        indicator.lineWidth = 3
        
        //テストデータ（仮）
        let event = EventModel(eventName: "testEvent", roomName: "testRoom", childNumber: 0, eventDescription: "testDescription",eventTag:["趣味","特技"], eventID: 100)
        events.append(event)
    
        //iBeacon領域生成
        region = CLBeaconRegion(proximityUUID:proximityUUID!,identifier:"AirMeet")
        manager.delegate = self
        
        //iBeacon初期設定
        switch CLLocationManager.authorizationStatus() {
        
            case .Authorized, .AuthorizedWhenInUse:
                print("iBeacon Permit")
            
            case .NotDetermined:
                print("iBeacon No Permit")
                //デバイスに許可を促す
                let deviceVer = UIDevice.currentDevice().systemVersion
                
                if(Int(deviceVer.substringToIndex(deviceVer.startIndex.advancedBy(1))) >= 8){
                    self.manager.requestAlwaysAuthorization()
                }else{
                    self.manager.startMonitoringForRegion(self.region)
                }
                
            case .Restricted, .Denied:
                //デバイスから拒否状態
                print("iBeacon Restricted")
        }
        
    }
    
    //main画面が呼ばれるたびに呼ばれるよ
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("Profile Reload")
        
        //初期の初期設定
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.stringForKey("name") == nil || defaults.stringForKey("facebook") == nil || defaults.objectForKey("image") == nil{
            print("First Launch")
            
            //デフォルト
            defaults.setObject("空気 会太郎", forKey: "name")
            defaults.setObject("よろしくおねがいします", forKey: "detail")
            defaults.setObject("空気会太郎", forKey: "facebook")
            defaults.setObject("@AirMeet", forKey: "twitter")
            
            defaults.setObject(UIImagePNGRepresentation(userImageView.image!), forKey: "image")
            defaults.setObject(UIImagePNGRepresentation(backImageView.image!), forKey: "back")
            
            //iBeaconによる領域観測を開始する
            print("iBeacon Start\n　|\n　∨")
            self.manager.startMonitoringForRegion(self.region)
            
            //プロフィール設定画面に遷移
            let storyboard: UIStoryboard = UIStoryboard(name: "Profile", bundle: NSBundle.mainBundle())
            let profileViewController: ProfileViewController = storyboard.instantiateInitialViewController() as! ProfileViewController
            self.navigationController?.pushViewController(profileViewController, animated: true)
        
        //プロフィール更新
        }else{
            
            if (appDelegate.isBeacon == true){
                
                //iBeaconによる領域観測を開始する
                print("iBeacon Start\n　|\n　∨")
                self.manager.startMonitoringForRegion(self.region)
                //appDelegate.isBeacon = false
                
            }
            //名前
            nameLabel.text = "\(defaults.stringForKey("name")!)"
            //自己紹介
            detailLabel.text = "\(defaults.stringForKey("detail")!)"
            //facebook
            facebookLinkLabel.text = "\(defaults.stringForKey("facebook")!)"
            //twitter
            twitterLinkLabel.text = "\(defaults.stringForKey("twitter")!)"
            
            //画像
            let imageData:NSData = defaults.objectForKey("image") as! NSData
            userImageView.image = UIImage(data:imageData)
            let backData:NSData = defaults.objectForKey("back") as! NSData
            backImageView.image = UIImage(data: backData)
        }
        
    }
    
    //観測開始後に呼ばれる、領域内にいるかどうか判定する
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        
        switch (state) {
            
        case .Inside: // すでに領域内にいる場合は（didEnterRegion）は呼ばれない
            print("Enter　↓")
            //測定を開始する
            self.manager.startRangingBeaconsInRegion(self.region)
            // →(didRangeBeacons)で測定をはじめる
            break;
            
        case .Outside:
            // 領域外→領域に入った場合はdidEnterRegionが呼ばれる
            break;
            
        case .Unknown:
            // 不明→領域に入った場合はdidEnterRegionが呼ばれる
            break;
        }
    }
    
    //領域に入った時
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Enter　↓")
        
        //測定を開始する
        self.manager.startRangingBeaconsInRegion(self.region)
        
        //ローカル通知
        //sendLocalNotificationWithMessage("領域に入りました")
        //AppDelegate().pushControll()
        //sendPush("AirMeet領域に入りました")
    }
    
    //領域から抜けた時
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exit　↑")
        
        //測定を停止する
        self.manager.stopRangingBeaconsInRegion(self.region)
        
        //sendLocalNotificationWithMessage("領域から出ました")
        //AppDelegate().pushControll()
        //sendPush("AirMeet領域から出ました")
    }
    
    //観測失敗
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        
        print("monitoringDidFailForRegion \(error)")
    }
    
    //通信失敗
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print("didFailWithError \(error)")
    }
    
    //領域内にいるので測定をする
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region:CLBeaconRegion) {
        
        //現在時刻取得
        let now = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        //Beaconを計測しない範囲のとき、停止
        if (appDelegate.isBeacon == false){
            print("\(dateFormatter.stringFromDate(now)) : Parent Made\n")
            
            //iBecon停止
            print("　∧\n　|\niBeacon Stop\n")
            self.manager.stopMonitoringForRegion(self.region)
            
        }else{
            print("\(dateFormatter.stringFromDate(now)) : Child Mode \(majorIDList)")
        
            majorIDList = []
            
            //ibeconがないとき
            if(beacons.count == 0) {
                
                //最後の1つだったとき
                if(majorIDList.count != majorIDListOld.count){
                    print("\n\(dateFormatter.stringFromDate(now))  : Left AirMeet")
                    print("left major -> [\(majorIDListOld[0])]\n")
                    sendPush("AirMeet領域から出たよ")
                    events = []
                    EventTableView.reloadData()
                }
                
                appDelegate.majorID = []
                majorIDListOld = majorIDList
                
                return
            }
            
            //ibeconがあるとき、配列にする
            for i in 0..<beacons.count{
                majorIDList.append(beacons[i].major)
            }
            
            //1つ前の観測から変更があったとき
            if(majorIDList.count != majorIDListOld.count){
                
                //増えたとき
                if(majorIDList.count > majorIDListOld.count){
                    print("\n\(dateFormatter.stringFromDate(now))  : Add AirMeet")
                    sendPush("AirMeet領域に入ったよ")
                    
                    // 通信用のConfigを生成.
                    let myConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
                    
                    // Sessionを生成.
                    let mySession:NSURLSession = NSURLSession(configuration: myConfig, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
                    
                    var task:NSURLSessionDataTask!
                    
                    //新しく入ったやつを抽出
                    for newMajor in majorIDList.except(majorIDListOld){
                        print("new major -> [\(newMajor)]\n")
                        
                        let url = NSURL(string: "http://airmeet.mybluemix.net/event_info?major=\(newMajor)")
                        
                        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url!)
                        request.HTTPMethod = "GET"
                        request.addValue("a", forHTTPHeaderField: "X-AccessToken")
                        
                        task = mySession.dataTaskWithRequest(request)
                        
                        //iBecon停止
                        print("　∧\n　|\niBeacon Stop\n")
                        self.manager.stopMonitoringForRegion(self.region)
                        
                        print("Resume Task ↓")
                        //くるくるスタート
                        self.view.addSubview(self.indicator)
                        self.indicator.startAnimation()
                        
                        task.resume()
                    }
                    
                //減った時（まだ他にもAirMeetがあるとき）
                }else{
                    print("\n\(dateFormatter.stringFromDate(now))  : Left AirMeet")
                    sendPush("AirMeet領域から出たよ")
                    for leftMajor in majorIDListOld.except(majorIDList){
                        print("left major -> [\(leftMajor)]\n")
                        for (index,event) in  events.enumerate(){
                            if event.eventID == leftMajor{
                                 events.removeAtIndex(index)
                                 EventTableView.reloadData()
                                
                            }
                        }
                        
                    }

                }
                

                appDelegate.majorID = majorIDList
                majorIDListOld = majorIDList
            }
            
            /*
            beaconから取得できるデータ
            proximityUUID   :   regionの識別子
            major           :   識別子１
            minor           :   識別子２
            proximity       :   相対距離
            accuracy        :   精度
            rssi            :   電波強度
            */
        }
    }
    
    //データ転送中の状況
    //func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        //print( bytesSent/totalBytesSent * 100 )
        
    //}
    
    //転送が完了したとき
    //func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
    //}
    
    //データを取得したとき
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        print("\nDidReceiveData Task ↑\n")
        // print(data)
        let json = JSON(data:data)
        
        //失敗
        if String(json["code"]) == "400" || String(json["code"]) == "500"{
            
            print("Server Connection Error : \(json["message"])")
            session.invalidateAndCancel()
            
            //iBeconStart
            self.manager.startMonitoringForRegion(self.region)
            //非同期
            dispatch_async(dispatch_get_main_queue(), {
                
                //くるくるストップ
                self.indicator.stopAnimation(true, completion: nil)
                self.indicator.removeFromSuperview()
                
            })
            
        //成功
        }else{
            
            print("\nServer Connection Sucsess\n EventName -> \(json["event_name"]) \n RoomName  -> \(json["room_name"])")
            
            let majorString:String = "\(json["major"])"
            let majorInt:Int = Int(majorString)!
            let majorNumber:NSNumber = majorInt as NSNumber
            
            let countInt:Int = Int("\(json["count"])")!
        
            var itemArray:[String] = []// = json["items"] as Array
            
            for item in json["items"]{
                //0:index 1:中身
                itemArray.append("\(item.1)")
                
            }

            print(" items     -> \(itemArray)\n")
            
            //eventもでるを生成してtableviewに追加
            let event = EventModel(eventName: "\(json["event_name"])", roomName: "\(json["room_name"])", childNumber: countInt, eventDescription: "\(json["description"])",eventTag:itemArray, eventID: majorNumber)
            self.events.append(event)
            
            //セッションを終える
            session.invalidateAndCancel()
            //iBeconをStartする
            print("iBeacon Start\n　|\n　∨")
            self.manager.startMonitoringForRegion(self.region)

            //非同期
            dispatch_async(dispatch_get_main_queue(), {
                
                //くるくるストップ
                self.indicator.stopAnimation(true, completion: nil)
                self.indicator.removeFromSuperview()
                self.EventTableView.reloadData()

            })
            
        }

    }
    
    //プッシュ通知(forground)
    func sendPush(message: String){
        
        let alert = UIAlertController(title:"\(message)",message:nil,preferredStyle:.Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default) {
            action in
        }
        alert.addAction(okAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //ローカル通知(現状機能してない)
    func sendLocalNotificationWithMessage(message: String!) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
        
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }

    //会場情報を入れるtableViewのcellセット
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        
        let cell: EventTableViewCell = tableView.dequeueReusableCellWithIdentifier("EventTableViewCell", forIndexPath: indexPath) as! EventTableViewCell
        cell.setCell(events[indexPath.row])
        
        return cell
    }
    
    //tableViewセクション数
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    //tableViewセクションの行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    //tableViewのcellが選択されたとき
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        print("Select Event : \(indexPath.row)")
        
        //選択したEvent情報を保持して
        appDelegate.selectEvent = events[indexPath.row]
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Child", bundle: NSBundle.mainBundle())
        let childViewController: ChildFirstSettingViewController = storyboard.instantiateInitialViewController() as! ChildFirstSettingViewController
        
        //子モードに遷移
        self.navigationController?.pushViewController(childViewController, animated: true)
        
    }
    
    //[親]AirMeet設定画面に遷移
    @IBAction func ParentButton(sender: AnyObject) {
        
        //appDelegate.isBeacon = false
        print("Parent Made\n")
        
        //測定を停止する
        print("Exit　↑")
        self.manager.stopRangingBeaconsInRegion(self.region)
        //iBecon停止
        print("　∧\n　|\niBeacon Stop\n")
        self.manager.stopMonitoringForRegion(self.region)
        
        //空にする
        events = []
        EventTableView.reloadData()
        majorIDList = []
        majorIDListOld = []
        appDelegate.majorID = []
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Parent", bundle: NSBundle.mainBundle())
        let parentViewController: ParentSettingViewController = storyboard.instantiateInitialViewController() as! ParentSettingViewController
        self.navigationController?.pushViewController(parentViewController, animated: true)
        
    }
    
    //子
    @IBAction func ChildButton(sender: AnyObject) {
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Child", bundle: NSBundle.mainBundle())
        let childViewController: ChildFirstSettingViewController = storyboard.instantiateInitialViewController() as! ChildFirstSettingViewController
        
        self.navigationController?.pushViewController(childViewController, animated: true)
        
    }
    
    //Meet
    @IBAction func MeetButton(sender: AnyObject) {
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Meet", bundle: NSBundle.mainBundle())
        let meetViewController: MeetListViewController = storyboard.instantiateInitialViewController() as! MeetListViewController
        
        self.navigationController?.pushViewController(meetViewController, animated: true)
    }
    
    //プロフィール
    @IBAction func ProfileButton(sender: AnyObject) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Profile", bundle: NSBundle.mainBundle())
        let profileViewController: ProfileViewController = storyboard.instantiateInitialViewController() as! ProfileViewController
        
        self.navigationController?.pushViewController(profileViewController, animated: true)
        
    }
    
    @IBAction func MenuButton(sender: AnyObject) {
        toggleSideMenuView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//arrayを拡張、要素の比較
extension Array {
    
    mutating func remove<T : Equatable>(obj : T) -> Array {
        self = self.filter({$0 as? T != obj})
        return self;
    }
    
    func contains<T : Equatable>(obj : T) -> Bool {
        return self.filter({$0 as? T == obj}).count > 0
    }
    
    func except<T : Equatable>(obj: [T]) -> [T] {
        var ret = [T]()
        
        for x in self {
            if !obj.contains(x as! T) {
                ret.append(x as! T)
            }
        }
        return ret
    }
    
}



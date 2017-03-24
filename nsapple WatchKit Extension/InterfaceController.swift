//
//  InterfaceController.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 7/9/15.
//  Copyright (c) 2015 Perceptus.org. All rights reserved.
//

import WatchKit
import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


//




public extension WKInterfaceImage {
    
    public func setImageWithUrl(_ url:String) -> WKInterfaceImage? {
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            if let url = URL(string: url) {
                if let data = try? Data(contentsOf: url) { // may return nil, too
                    // do something with data
                    var placeholder = UIImage(data: data)!
                    DispatchQueue.main.async {
                                        self.setImage(placeholder)
                                    }
                    
                }
            }
            
        }
        
        return self
    }
    
}

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var bgimage: WKInterfaceImage!
    @IBOutlet weak var primarybg: WKInterfaceLabel!
    @IBOutlet weak var bgdirection: WKInterfaceLabel!
    @IBOutlet weak var deltabg: WKInterfaceLabel!
    @IBOutlet weak var battery: WKInterfaceLabel!
    @IBOutlet weak var minago: WKInterfaceLabel!
   // @IBOutlet weak var secondarybg: WKInterfaceLabel!
    @IBOutlet weak var graphhours: WKInterfaceLabel!
    @IBOutlet weak var hourslider: WKInterfaceSlider!
    //@IBOutlet weak var chartraw: WKInterfaceSwitch!
   //@IBOutlet weak var primarybg: WKInterfaceLabel!
   //@IBOutlet weak var secondarybg: WKInterfaceLabel!

  
  
    @IBOutlet var loadingicon: WKInterfaceImage!
    @IBOutlet var pumpstatus3: WKInterfaceLabel!
    @IBOutlet var pumpstatus2: WKInterfaceLabel!
    @IBOutlet var pumpstatus: WKInterfaceLabel!
    @IBOutlet weak var plabel: WKInterfaceLabel!
    @IBOutlet weak var vlabel: WKInterfaceLabel!
    @IBOutlet weak var secondarybgname: WKInterfaceLabel!
    var graphlength:Int=3
    var bghistread=true as Bool
    var bghist=[] as?  [[String:AnyObject]]
    var responseDict=[:] as [String:AnyObject]
    var cals=[] as? [[String:AnyObject]]
    var craw=true as Bool
    //
    
    @IBAction func hourslidervalue(_ value: Float) {
        let slidermap:[Int:Int]=[1:24,2:12,3:6,4:3,5:1]
        let slidervalue=Int(round(value*1000)/1000)
        graphlength=slidermap[slidervalue]!
        willActivate()
        
    }

    
    @IBAction func chartraw(_ value: Bool) {
        craw=value
        willActivate()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
      //  let theImage = UIImage(named: "nsblue")
        //  var img: UIImage = UIImage(named: "nsblue")! // grabs the image from extension's bundle
        // WKInterfaceDevice().addCachedImage(img,"nsblue") // adds to the Watch cache
        
       // self.loadingicon.setImage(theImage)         // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
   
        super.willActivate()
        updatecore()
        updatepumpstats()
        //updatecore()
       
//        let google=bggraph(graphlength)!.addingPercentEscapes(using: String.Encoding.utf8)!
//        if (bghistread==true)&&(google != "NoData") {
//            graphhours.setTextColor(UIColor.white)
//            graphhours.setText("Last "+String(graphlength)+" Hours")
//            bgimage.setHidden(false)
//            chartraw.setHidden(false)
//            bgimage.setImageWithUrl(google)
//        }
//        else {
//            //need to create no data image
//            graphhours.setTextColor(UIColor.red)
//            graphhours.setText("No Chart Data")
//            bgimage.setHidden(true)
//            chartraw.setHidden(true)
//        }
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        var gray=UIColor.gray as UIColor
    
        self.primarybg.setTextColor(gray)
        self.bgdirection.setTextColor(gray)
        self.plabel.setTextColor(gray)
        self.vlabel.setTextColor(gray)
        self.minago.setTextColor(gray)
        self.deltabg.setTextColor(gray)
        self.pumpstatus.setTextColor(gray)
        self.pumpstatus2.setTextColor(gray)
        self.pumpstatus3.setTextColor(gray)
        super.didDeactivate()
    }
    
    func updatepumpstats() {
        
   // var key="J-UUWxWL8YLvtdaO2bNUvrqtv615YZe4"
   // var url3s="https://api.mongolab.com/api/1/databases/kenstackdb/collections/nodehawkdata?apiKey=J-UUWxWL8YLvtdaO2bNUvrqtv615YZe4" as String
        let urlPath2: String = "https://api.mongolab.com/api/1/databases/kenstackdb/collections/nodehawkdata?s={\"date\":-1}&l=1&apiKey=J-UUWxWL8YLvtdaO2bNUvrqtv615YZe4"
        var escapedAddress = urlPath2.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        //url3s=url3s.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        var url3 = URL(string: escapedAddress!)
        
        let task3 = URLSession.shared.dataTask(with: url3!) { data, response, error in
            //let task = URLSession.synchronousDataTaskWithURL(urlPath2) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
           // print (response)
            let json = try? JSONSerialization.jsonObject(with: data) as! [[String:AnyObject]]
            let keylist:[String]=["iob","predictedbgiob","pumpstate","bgstale","reslevel","bgreaderror"]
            //print(json?[0]["iob"] as! Double)
            let pumptime=json?[0]["date"] as! TimeInterval
            let ct=TimeInterval(Date().timeIntervalSince1970)
            let deltat=(ct-pumptime/1000)/60
            if deltat<10 {self.pumpstatus.setTextColor(UIColor.green);self.pumpstatus2.setTextColor(UIColor.green)} else
                if deltat<20 {self.pumpstatus.setTextColor(UIColor.yellow);self.pumpstatus2.setTextColor(UIColor.yellow)} else {self.pumpstatus.setTextColor(UIColor.red);self.pumpstatus2.setTextColor(UIColor.red)}
            var pstatus:String = "IOB "
            var pstatus2 : String = "BGI "
            if let iob=(json?[0]["iob"]) {if iob as! Double > -1.0
            {pstatus=pstatus + String(format:"%.1f", iob as! Double )
                pstatus2=pstatus2+String(format:"%.0f", json?[0]["predictedbgiob"] as! Double )
            }
            else
            {pstatus=pstatus+"N/A"
                pstatus2=pstatus2+"N/A"
                }
            } else {pstatus=pstatus+"N/A"
                pstatus2=pstatus2+"N/A"}
            
            
            if let pumpstate=json?[0]["pumpstate"] {
                if (json?[0]["pumpstate"] as! String)=="normal" {pstatus2=pstatus2+" : Normal : EBat "} else
                if (json?[0]["pumpstate"] as! String)=="zerobasal" {pstatus2=pstatus2+" : ZeroBas : Ebat "}
                else {pstatus2=pstatus2+" : BasError : Ebat "}
            }
            else {pstatus2=pstatus2+" : BasError : Ebat "}
            
            
            if let reslevel=json?[0]["reslevel"] {
            
                pstatus=pstatus+"  "+String(Int(deltat))+" min ago  Res "+String(format:"%.0f", json?[0]["reslevel"] as! Double )} else {
                
                pstatus=pstatus+"  "+String(Int(deltat))+" min ago  Res N/A"
            }
            
            if let batjson = json?[0]["edison_bat"] {pstatus2=pstatus2+String(format:"%.0f",(batjson as! [String:AnyObject])["percentage"] as! Double)+"%"}
            else
            {pstatus2=pstatus2+"N/A?"}
            
            
          //  let batjson = json?[0]["edison_bat"] as! [String:AnyObject]
            
            //pstatus2=pstatus2+String(format:"%.0f",batjson["percentage"] as! Double)+"%"
           
            var pstatus3:String="BG Status "
            if let bgstale=json?[0]["bgstale"] {if (json?[0]["bgstale"] as! Bool) == false && (json?[0]["bgreaderror"] as! Bool) == false
            {pstatus3=pstatus3+"OK";self.pumpstatus3.setTextColor(UIColor.green)}
            else
            {pstatus3=pstatus3+"Fail Check BG Data";self.pumpstatus3.setTextColor(UIColor.red)}} else {pstatus3=pstatus3+"Fail Check BG Data";self.pumpstatus3.setTextColor(UIColor.red)}
            
//            if (json?[0]["bgstale"] as! Bool) == false && (json?[0]["bgreaderror"] as! Bool) == false
//                {pstatus3=pstatus3+"OK";self.pumpstatus3.setTextColor(UIColor.green)}
//                else
//                {pstatus3=pstatus3+"Fail Check BG Data";self.pumpstatus3.setTextColor(UIColor.red)}
        
            self.pumpstatus.setText(pstatus)
            self.pumpstatus2.setText(pstatus2)
            self.pumpstatus3.setText(pstatus3)
            
            
        }
        task3.resume()
    }
    
    func updatecore() {
 
     //get pebble data
  //    var dexprimary=false as Bool
        //add retrieve urlfrom user storage
       // var defaults: UserDefaults = UserDefaults(suiteName: "group.perceptus.nsapple")!
        //var url=defaults.object(forKey: "pebbleurl") as! String
        var dexprimary=true as Bool
       // if defaults.object(forKey: "primarydisplay") as! String == "dex" {dexprimary=true} else {dexprimary=false}
      print("in updarte core")
        //set bg color to something old so we know if its not really updating
        var gray=UIColor.gray as UIColor
        var white=UIColor.white as UIColor
        self.primarybg.setTextColor(gray)
        self.bgdirection.setTextColor(gray)
        self.plabel.setTextColor(gray)
        self.vlabel.setTextColor(gray)
        self.minago.setTextColor(gray)
        self.deltabg.setTextColor(gray)
        //self.primarybg.setText("N/A")
        //self.bgdirection.setText("")
//        self.primarybg.setHidden(true)
//        self.bgdirection.setHidden(true)
//        self.deltabg.setHidden(true)
//        self.minago.setHidden(true);
//        self.plabel.setHidden(true);
//        self.vlabel.setHidden(true);
// grabs the image from the Watch cache
        //self.loadingicon.setHidden(false)
        
        //self.loadingicon.setImageNamed("nsblue")
           //hard code for now
        var url="t1daarshk.herokuapp.com"
        let urlPath: String = "https://"+url+"/pebble?count=576"
        print("in watchkit")
    
        print(urlPath)
        
        let url2 = URL(string: urlPath)
        
        let task = URLSession.shared.dataTask(with: url2!) { data, response, error in
            //let task = URLSession.synchronousDataTaskWithURL(urlPath2) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                print("Data is empty")
                return
            }
            
            
            DispatchQueue.main.async() {
            
            let responseDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
            print ("read resp")
            
            
            
            
            
 // new main
            
            print("before main")
            // print(responseDict["bgs"])
            //successfully received pebble end point data
            if let bgs=responseDict["bgs"] as? [[String:AnyObject]] {
                print("after main")
                print(bgs[0])
                // if let bgs=responseDict["bgs"] as? NSArray {
                self.bghistread=true
                var rawavailable=false as Bool
                var slope=0.0 as Double
                var intercept=0.0 as Double
                var scale=0.0 as Double
                let cbg=bgs[0]["sgv"] as! String
                let direction=bgs[0]["direction"] as! String
                // let unfilt=bgs[0]["unfiltered"] as! Double
                // let filt=bgs[0]["filtered"] as! Double
                // let bat=bgs[0]["battery"] as! String
                let dbg=bgs[0]["bgdelta"] as! Int
                let bgtime=bgs[0]["datetime"] as! TimeInterval
                var red=UIColor.red as UIColor
                var green=UIColor.green as UIColor
                var yellow=UIColor.yellow as UIColor
                var rawcolor="green" as String
                //save as global variables
                self.cals=responseDict["cals"] as? [[String:AnyObject]]
                self.bghist=bgs
                //calculate text colors for sgv,direction
                var lmh=2
                var rawv=0 as Int
                let sgvi=Int(cbg)
                let sgv=Double(sgvi!)
                // let sgvcolor=bgcolor(sgvi!) as String
              
                //check to see if cal data is available - if so we can calc raw
                
                
                //            if (cals?.count>0) {
                //                rawavailable=true
                //                slope=cals?[0]["slope"] as! Double
                //           scale=cals?[0]["scale"] as! Double
                //             intercept=cals?[0]["intercept"] as! Double
                //
                //           // rawv=calcraw(sgv,slope: slope,intercept: intercept,scale: scale)
                //
                //                }
                //        else
                //        {rawbg.setTextColor(rawcolor)
                //            rawbg.setText("N/A")
                //        }
                // display pebble data to watch
                
                //color for battery
                //        if Int(bat)<20 {battery.setTextColor(UIColor.red)} else
                //            if Int(bat)<40 {battery.setTextColor(UIColor.yellow)} else
                //            {battery.setTextColor(UIColor.green)}
                //         battery.setText(bat+"%")
                //set time
//                self.primarybg.setHidden(false)
//                self.bgdirection.setHidden(false)
//                self.deltabg.setHidden(false)
//                self.minago.setHidden(false);
//                self.plabel.setHidden(false);
//                self.vlabel.setHidden(false);
                self.plabel.setTextColor(white)
                self.vlabel.setTextColor(white)
                self.deltabg.setTextColor(white)
                let ct=TimeInterval(Date().timeIntervalSince1970)
                let deltat=(ct-bgtime/1000)/60
                if deltat<10 {self.minago.setTextColor(UIColor.green)} else
                    if deltat<20 {self.minago.setTextColor(UIColor.yellow)} else {self.minago.setTextColor(UIColor.red)}
                self.minago.setText(String(Int(deltat))+" min ago")
         //       self.secondarybgname.setText("Raw")
                if (sgvi<40) {
                    //display error code as primary and raw as secondary
                    // currentbg.setAttributedText(size)
                    self.primarybg.setTextColor(red)
                    self.primarybg.setText(self.errorcode(sgvi!))
                    self.bgdirection.setText("")
                    self.deltabg.setText("")
                    //                if (rawavailable==true) {
                    //                    secondarybg.setText(String(rawv))
                    //                    secondarybg.setTextColor(bgcolor(rawv))
                    //                }
                    //                else
                    //                {
                    //                    secondarybg.setText("N/A")
                    //                    secondarybg.setTextColor(red)
                    //                }
                }
                    //if raw doesnt exist or dex is primary.0
                else
                    if (dexprimary==true || rawavailable==false)
                    {
                        //display dex as primary
                       // self.loadingicon.setHidden(true)
                        self.primarybg.setText(cbg)
                        self.primarybg.setTextColor(self.bgcolor(Int(cbg)!))
                        self.bgdirection.setText(self.dirgraphics(direction))
                        self.bgdirection.setTextColor(self.bgcolor(Int(cbg)!))
                        let velocity=self.velocity_cf(bgs, slope: slope,intercept: intercept,scale: scale) as Double
                        let prediction=velocity*30.0+Double(cbg)!
                        print("vel")
                        print(velocity)
                        self.deltabg.setTextColor(UIColor.white)
                        //        if (dbg<0) {self.deltabg.setText(String(dbg)+" mg/dl : "+String(format:"%.1f", velocity)+" mg/dl.min")} else {self.deltabg.setText("+"+String(dbg)+" mg/dl : "+String(format:"%.1f", velocity)+" mg/dl.min")}
                        if (dbg<0) {self.deltabg.setText(String(dbg)+" mg/dl")} else {self.deltabg.setText("+"+String(dbg)+" mg/dl")}
                        
                        self.vlabel.setText(String(format:"%.1f", velocity))
                        self.plabel.setText(String(format:"%.0f", prediction))
                        
                        
                        
                        
                        //                if (rawavailable==true) {
                        //                    secondarybg.setText(String(rawv))
                        //                    secondarybg.setTextColor(bgcolor(rawv))
                        //                }
                        //                else
                        //                {
                        //                    secondarybg.setText("N/A")
                        //                    secondarybg.setTextColor(red)
                        //                }
                }
                //      else
                //raw must be primary and available
                
                //                {
                //                    primarybg.setText(String(rawv))
                //                    primarybg.setTextColor(bgcolor(rawv))
                //                //calculate raw delta
                //                    let cbgo=bgs[1]["sgv"] as! String
                //                    let unfilto=bgs[1]["unfiltered"] as! Double
                //                    let filto=bgs[1]["filtered"] as! Double
                //                    //let t2=test(filto,b:unfilto)
                //                    let rawvo=calcraw(Double(Int(cbgo)!),filt:filto,unfilt:unfilto,slope: slope,intercept: intercept,scale: scale) as Int
                //                    let dbg=(rawv-rawvo) as Int
                //                    deltabg.setTextColor(UIColor.white)
                //                    if (dbg<0) {deltabg.setText(String(dbg)+" mg/dl")} else {deltabg.setText("+"+String(dbg)+" mg/dl")}
                //                    //calculate raw direction
                //                   
                //                    //
                //                    
                //                    //
                //                    
                //                    let bgtimeo=bgs[1]["datetime"] as! TimeInterval
                //                    let dt=round((bgtime-bgtimeo)/60000.0) as Double
                //                    print(dt)
                //                    
                //                    
                //                    
                //                    
                //                  //  let velocity=Double(dbg)/dt
                //                   
                //                    
                //                    let velocity=velocity_cf(bgs, slope: slope,intercept: intercept,scale: scale) as Double
                //                    let prediction=velocity*20.0
                //                    print("vel")
                //                    print(velocity)
                //                    vlabel.setText(String(format:"%.1f", velocity))
                //                    plabel.setText(String(format:"%.1f", prediction))
                //                    
                //                    
                //                    
                //                    bgdirection.setTextColor(bgcolor(rawv))
                //                    bgdirection.setText(dirgraphics(rawdir(velocity,dt: dt)))
                //                    
                //
                //
                //                    //display raw direction and delta
                //                    secondarybg.setText(cbg)
                //                    secondarybg.setTextColor(bgcolor(sgvi!))
                //                    secondarybgname.setText("Dex")
                //                    
                //                    
                //            }
                
            } //end bgs !=nil
                
                //did not get pebble endpoint data
            else
            {
                self.bghistread=false
                self.noconnection()
            }
                  //add graph
                    let google=self.bggraph(self.graphlength,bghist: self.bghist!)!.addingPercentEscapes(using: String.Encoding.utf8)!
                    if (self.bghistread==true)&&(google != "NoData") {
                        self.graphhours.setTextColor(UIColor.white)
                        self.graphhours.setText("Last "+String(self.graphlength)+" Hours")
                        self.bgimage.setHidden(false)
//                        self.chartraw.setHidden(false)
                        var imgURL: URL = URL(string: google)! as URL
                        let task2 = URLSession.shared.dataTask(with: imgURL) { data, response, error in
                            //let task = URLSession.synchronousDataTaskWithURL(urlPath2) { data, response, error in
                            guard error == nil else {
                                print(error!)
                                return
                            }
                            guard let data = data else {
                                print("Data is empty")
                                return
                            }
                            
                           // let responseDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
                           // print ("read resp")
                      //  self.bgimage.setImageWithUrl(google)
                            print("setting image")
                            self.bgimage.setImageData(data)
                        }
                        task2.resume()
                    }
                    else {
                        //need to create no data image
                        self.graphhours.setTextColor(UIColor.red)
                        self.graphhours.setText("No Chart Data")
                        self.bgimage.setHidden(true)
     //                   self.chartraw.setHidden(true)
                    }
            
//            let bg=responseDict["bgs"] as! NSArray
//            print(bg[0])
            
        }//end dispatch
        } //end urlsession
        task.resume()
        
        
        
        
        
        
        //var responseDict:AnyObject="" as AnyObject
//        if let url = URL(string: urlPath) {
//            do {
//                var contents = try String(contentsOf: url)
//                contents=contents.replacingOccurrences(of:"+", with: "")
//                let data=contents.data(using: .utf8)!
//                responseDict = try! JSONSerialization.jsonObject(with: data,options: []) as! [String:AnyObject]
//                
//            } catch {
//                // contents could not be loaded
//            }
//        } else {
//            // the URL was bad!
//        }
//        
        
        //        if let url = URL(string: urlPath) {
//            let data = try String(contentsOf: url) {
//                print(data)
//                
//                //from Nightscouter - fix for apple json issues
//                var dataConvertedToString = NSString(data: data, encoding: String.Encoding.utf8)
//                // Apple's JSON Serializer has a problem with + notation for large numbers. I've observed this happening in intercepts.
//                dataConvertedToString = dataConvertedToString?.stringByReplacingOccurrencesOfString("+", withString: "")
//                
//                // Converting string back into data so it can be processed into JSON.
//                if let newData: Data = dataConvertedToString?.dataUsingEncoding(String.Encoding.utf8) {
//                    var jsonErrorOptional: NSError?
//                    responseDict = JSONSerialization.JSONObjectWithData(newData, options: JSONSerialization.ReadingOptions(0), error: &jsonErrorOptional)!
//                    
//                    // if there was an error parsing the JSON send it back
//             
//                
//                
//                
//                
//                
//                
//                }
//                
//            
//            
//                
//                
//             //  responseDict  = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)!
//            }
//        }
        
 
        
   
    }
    
    func velocity_cf(_ bgs:[[String:AnyObject]],slope:Double,intercept:Double,scale:Double)->Double {
    //linear fit to 3 data points get slope (ie velocity)
    var v=0 as Double
    var n=0 as Int
    var i=0 as Int
    let ONE_MINUTE=60000.0 as Double
    var bgsgv = [Double](repeating: 0.0, count: 4)
        var date = [Double](repeating: 0.0, count: 4)
        var bgsraw=[Double](repeating: 0.0, count: 4)
        
      
        i=0
        while i<4 {
         date[i]=(bgs[i]["datetime"] as? Double)!
         bgsgv[i]=(bgs[i]["sgv"] as? NSString)!.doubleValue
         
  //        bgsraw[i]=Double(calcraw(bgsgv[i],filt:filto,unfilt:unfilto,slope: slope,intercept: intercept,scale: scale) as Int)
     //       bgsgv[i]=bgsraw[i]
            i=i+1
          
        }
        
        
    if ((date[0]-date[3])/ONE_MINUTE < 15.1) {n=4}
        
        else
        
    if ((date[0]-date[2])/ONE_MINUTE < 10.1) {n=3}
    else
        
    if ((date[0]-date[1])/ONE_MINUTE<10.1) {n=2}
    else {n=0}
        
    var xm=0.0 as Double
    var ym=0.0 as Double
    var j=0 as Int
    if (n>0) {
        var j=0;
    while j<n {
				
				xm = xm + date[j]/ONE_MINUTE
				ym = ym + bgsgv[j]
                j=j+1
    }
    xm=xm/Double(n)
    ym=ym/Double(n)
    var c1=0.0 as Double
    var c2=0.0 as Double
    var t=0.0 as Double
    j=0
    while (j<n) {
				
				t=date[j]/ONE_MINUTE
				c1=c1+(t-xm)*(bgsgv[j]-ym)
				c2=c2+(t-xm)*(t-xm)
                j=j+1
    }
    v=c1/c2
        print(v)
    //	console.log(v)
    }
    //need to decide what to return if there isnt enough data
    
    else {v=0}
    
    return v
    }
    
    
    
    
    
    
    
    
    func noconnection() {
        deltabg.setTextColor(UIColor.red)
        deltabg.setText("No Data")
        
    }
    
    func bgcolor(_ value:Int)->UIColor
    {
        
        var red=UIColor.red as UIColor
        var green=UIColor.green as UIColor
        var yellow=UIColor.yellow as UIColor
        var sgvcolor=green as UIColor
        
        if (value<65) {sgvcolor=red}
        else
            if(value<80) {sgvcolor=yellow}
                
            else
                if (value<180) {sgvcolor=green}
                    
                else
                    if (value<250) {sgvcolor=yellow}
                    else
                    {sgvcolor=red}
        return sgvcolor
    }
    
    func errorcode(_ value:Int)->String {
        
       let errormap=["EC0 UNKNOWN","EC1 SENSOR NOT ACTIVE","EC2 MINIMAL DEVIATION","EC3 NO ANTENNA","EC4 UNKNOWN","EC5 SENSOR CALIBRATION","EC6 COUNT DEVIATION","EC7 UNKNOWN","EC8 UNKNWON","EC9 HOURGLASS DEVIATION","EC10 ??? POWER DEVIATION","EC11 UNKNOWN","EC12 BAD RF","EC13 MH"]

        return errormap[value]
    }
    
    func dirgraphics(_ value:String)->String {
         let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
        
        
        return graphics[value]!
    }
    
    func rawdir(_ velocity:Double,dt:Double) ->String {
        var direction="NONE" as String
        if (dt>10.1) {direction="NOT COMPUTABLE"} else
            if (velocity <= -3.0) {direction="DoubleDown"} else
                if (velocity > -3.0 && velocity <= -2.0) {direction="SingleDown"} else
                    if (velocity > -2.0 && velocity <= -1.0) {direction="FortyFiveDown"} else
        if (velocity > -1.0 && velocity <= 1.0) {direction="Flat"} else
        if (velocity > 1.0 && velocity <= 2.0) {direction="FortyFiveUp"} else
        if (velocity > 2.0 && velocity <= 3.0) {direction="SingleUp"} else
            if (velocity > 3.0) {direction="DoubleUp"} else
            {direction="RATE OUT OF RANGE"}
       
        
    return direction
    }
    
    func test(_ a:Double,b:Double) ->Int {
        return Int(a+b)
    }
    
    func calcraw(_ sgv:Double,filt:Double,unfilt:Double, slope:Double, intercept:Double, scale:Double) -> Int
    
    {
        var rawv=0 as Int
        if(sgv<40) {
            rawv = Int(scale*(unfilt-intercept)/slope)
        }
        else
        {
            rawv = Int((unfilt-intercept)/(filt-intercept)*Double(sgv))
            
        }
        return rawv
    }
    
    func bggraph(_ hours:Int,bghist:[[String:AnyObject]])-> String? {
        
        
        
        //get bghistory
        //grabbing double the data in case of gap sync issues
          var google="" as String
        var ct2=NSInteger(Date().timeIntervalSince1970)
                var xg="" as String
        var yg="" as String
        var rg="" as String
        var pc="&chco=" as String
        var maxy=0
        var maxx=0
        var miny=1000
        var bgoffset=40
        var bgth=180
        var bgtl=80
        let numbg=577 as Int
        var slope=0 as Double
        var scale=0 as Double
        var gpoints=0 as Int
        var intercept=0  as Double
        var bgtimes = [Int](repeating: 0, count: numbg+1)
        var rawv=[Int](repeating: 0, count: numbg+1)
        let minutes=hours*60
        var inc:Int=1
        if (hours==3||hours==1) {inc=1} else
            if hours==6 {inc=2} else
            if hours==12 {inc=3} else
                {inc=5}
        if cals?.count>0 && craw==true {
            slope=cals?[0]["slope"] as! Double
            scale=cals?[0]["scale"] as! Double
            intercept=cals?[0]["intercept"] as! Double
        }
        var descriptor: NSSortDescriptor = NSSortDescriptor(key: "datetime", ascending: false)
       // var sortedbgs: NSArray = (bghist.sortedArray(using: [descriptor]) as? NSArray)!
        var sortedbgs=bghist
        
        
//        var test=bghist.sort{
//            (($0 as! Dictionary<String, AnyObject>)["datetime"] as? Int) < (($1 as! Dictionary<String, AnyObject>)["datetime"] as? Int)
//        }
        
  
        //find max time, min and max bg
        var i=0 as Int;
      //  for var i=0; i<bghist.count; i=i+1 {
        while (i<bghist.count) {
            let curdate: Double = (bghist[i]["datetime"] as! Double)/1000
//            print (curdate)
//            print(Double(minutes))
//            print(Double(ct2))
            // bgtimes[i]=minutes-(((ct2*1000-(bghist[i]["datetime"] as! Int))/1000)/(60) as Int)

            bgtimes[i]=Int((Double(minutes)-(Double(ct2)-curdate)/(60.0)))
            print(bgtimes[i])
            if (bgtimes[i]>=0) {
                gpoints += 1
            if (bgtimes[i]>maxx) { maxx=bgtimes[i]}
            if (Int((bghist[i]["sgv"] as! String))>maxy) {maxy=Int(bghist[i]["sgv"] as! String)!}
            if (Int(bghist[i]["sgv"] as! String)<miny) {miny=Int(bghist[i]["sgv"] as! String)!}
                //calculate raw values, include in min max calc
                if cals?.count>0 && craw==true {
                    let sgvd=Double(Int(bghist[i]["sgv"] as! String)!)
                    let unfilt=bghist[i]["unfiltered"] as! Double
                    let filt=bghist[i]["filtered"] as! Double
                    rawv[i]=calcraw(sgvd,filt: filt,unfilt: unfilt,slope: slope,intercept: intercept,scale: scale)
                    if rawv[i]>maxy {maxy=rawv[i]}
                    if rawv[i]<miny {miny=rawv[i]}
                    
                }
            }
            i=i+1;}
        
       
        
        
        if gpoints < 2 {return "NoData"}
        
        //make sure there are 2 points minimum for prediction
               let velocity=velocity_cf(sortedbgs,slope: slope,intercept: intercept,scale: scale) as Double
        
        
         //insert prediction points into
        if maxy<bgth {maxy=bgth}
        if miny>bgtl {miny=bgtl}

        //create strings of data points xg (time) and yg (bg) and string of colors pc
         i=0;
        while i<bghist.count  {
            if (bgtimes[i]>=0) {
                //scale time values
                xg=xg+String(bgtimes[i]*100/minutes)+","
                var sgv:Int=(Int(bghist[i]["sgv"] as! String)!)
                if sgv<60 {pc=pc+"FF0000|"} else
                    if sgv<80 {pc=pc+"FFFF00|"} else
                        if sgv<180 {pc=pc+"00FF00|"} else
                            if sgv<260 {pc=pc+"FFFF00|"} else
                            {pc=pc+"FF0000|"}
                //scale bg data to 100 is the max
                sgv=(sgv-miny)*100/(maxy-miny)
                yg=yg+String(sgv)+","
                //add raw points on the fly if cal available
                if cals?.count>0 && craw==true {
                    let rawscaled=(rawv[i]-miny)*100/(maxy-miny)
                    xg=xg+String(bgtimes[i]*100/minutes)+".05,"
                    yg=yg+String(rawscaled)+","
                    pc=pc+"FFFFFF|"
                }
            }
        i=i+inc}
        
//        xg=(dropLast(xg))
//        yg=(dropLast(yg))
//        pc=(dropLast(pc))
        xg=String(xg.characters.dropLast())
        yg=String(yg.characters.dropLast())
        pc=String(pc.characters.dropLast())
        
        var low:Double=Double(bgtl-miny)/Double(maxy-miny)
        var high:Double=Double(bgth-miny)/Double(maxy-miny)
        //create string for google chart api
        //bands are at 80,180, vertical lines for hours
        var band1="&chm=r,FFFFFF,0,"+String(format:"%.2f",high-0.01)+","+String(format:"%.3f",high)
        var band2="|r,FFFFFF,0,"+String(format:"%.2f",(low))+","+String(format:"%.3f",low+0.01)
        let h:String=String(stringInterpolationSegment: 100.0/Double(hours))
        let hourlyverticals="&chg="+h+",0"
        google="https://chart.googleapis.com/chart?cht=s:nda&chxt=y&chxr=0,"+String(miny)+","+String(maxy)+"&chs=180x100"+"&chf=bg,s,000000&chls=3&chd=t:"+xg+"|"+yg+"|20"+pc+"&chxs=0,FFFFFF"+band1+band2+hourlyverticals
            return google
   
    
    }
    
    }



//
//  InterfaceController.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 7/9/15.
//  Copyright (c) 2015 Perceptus.org. All rights reserved.
//

import WatchKit
import Foundation


let defaults = UserDefaults(suiteName:"group.com.nsapple")
let mmol = defaults?.bool(forKey: "mmol")




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


public struct watch {
    
    public static var screenWidth: CGFloat {
        return WKInterfaceDevice.current().screenBounds.width
    }
    
    public static var is38: Bool {
        return screenWidth == 136
    }
    
    public static var is42: Bool {
        return screenWidth == 156
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
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        let gray=UIColor.gray as UIColor
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
        
       
        
        
        guard let urlUser = defaults?.string(forKey: "name_preference") else {
            print ("no url is set")
            pumpstatus.setText("")
            pumpstatus.setText("URL NOT SET")
            return}
        let mmol = defaults?.bool(forKey: "mmol")

        let urlPath2 = urlUser + "/api/v1/devicestatus.json?count=20"
        let escapedAddress = urlPath2.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
        guard let url2 = URL(string: escapedAddress!) else {
            print ("URL Parsing Error")
            pumpstatus.setText("")
            pumpstatus.setText("URL ERROR")
            return
        }
        
        let task3 = URLSession.shared.dataTask(with: url2) { data, response, error in
            guard error == nil else {
                print(error!)
                self.pumpstatus.setText(error?.localizedDescription)
                return
            }
            guard let data = data else {
                print("Data is empty")
                self.pumpstatus.setText("Data is Empty")
                return
            }
         
            let json = try? JSONSerialization.jsonObject(with: data) as! [[String:AnyObject]]
            if #available(watchOSApplicationExtension 3.0, *) {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate,
                                           .withTime,
                                           .withDashSeparatorInDate,
                                           .withColonSeparatorInTime]
           
           
            
            if json?.count == 0 {
                self.pumpstatus.setText("No Records")
                return}
            var pump = [[String : AnyObject]] ()
            var loop = [[String : AnyObject]] ()
            for item in json! {
                if item["pump"] != nil {pump.append(item)} else
                            if item["loop"] != nil {loop.append(item)}
            }
            
            //find the index of the most recent items
            var cdatepump = [Date]()
            for item in pump {
                cdatepump.append(formatter.date(from: (item["created_at"] as! String))!)
            }
                if cdatepump.count == 0 {
                    self.pumpstatus.setText("No Pump Records")
                    return
                }
                
            let lastpump = pump[cdatepump.index(of:cdatepump.max()!) as! Int]
            var cdateloop = [Date]()
            for item in loop {
                cdateloop.append(formatter.date(from: (item["created_at"] as! String))!)
            }
                
                if cdateloop.count == 0 {
                    self.pumpstatus2.setText("No Loop Records")
                    return
                }
            let lastloop = loop[cdateloop.index(of:cdateloop.max()!) as! Int]

                if let pumpdata = lastpump["pump"] as? [String:AnyObject] {
                    if let pumptime = formatter.date(from: (pumpdata["clock"] as! String))?.timeIntervalSince1970  {
                        let ct=TimeInterval(Date().timeIntervalSince1970)
                        let deltat=(ct-pumptime)/60
                        ///////////////////////////
                        /// TO DO NEED TO FIX COLORS AND DATES BY EACH TYPE
                        ///////////////////////////
                        
                        if deltat<10 {self.pumpstatus.setTextColor(UIColor.green);self.pumpstatus2.setTextColor(UIColor.green)} else
                            if deltat<20 {self.pumpstatus.setTextColor(UIColor.yellow);self.pumpstatus2.setTextColor(UIColor.yellow)} else {self.pumpstatus.setTextColor(UIColor.red);self.pumpstatus2.setTextColor(UIColor.red)}
                        
                        
                        var pstatus:String = "Res "
                        let res = pumpdata["reservoir"] as! Double
                        pstatus = pstatus + String(format:"%.0f", res)
                        if let uploader = lastpump["uploader"] as? [String:AnyObject] {
                            let upbat = uploader["battery"] as! Double
                            pstatus = pstatus + "  PBat " + String(format:"%.0f", upbat)
                        }
                        if let riley = lastpump["radioAdapter"] as? [String:AnyObject] {
                            if let rrssi = riley["RSSI"] as? Int {
                                pstatus = pstatus + "%  RdB " + String(rrssi)
                            }
                        }
                        self.pumpstatus.setText(pstatus)
                                       }
                    
                    
                }
                
                
                if let loopdata = lastloop["loop"] as? [String:AnyObject] {
                    if let looptime = formatter.date(from: (loopdata["timestamp"] as! String))?.timeIntervalSince1970  {
                        let ct=TimeInterval(Date().timeIntervalSince1970)
                        let deltat=(ct-looptime)/60
                        if deltat<10 {self.pumpstatus2.setTextColor(UIColor.green)} else
                            if deltat<20 {self.pumpstatus2.setTextColor(UIColor.yellow)} else {self.pumpstatus2.setTextColor(UIColor.red)}
                         var pstatus2:String = " IOB "
                        if let failure = loopdata["failureReason"] {
                            pstatus2 = failure as! String
                        }
                        else
                        {
                       
                        let iobdata = loopdata["iob"] as? [String:AnyObject]
                        let iob = iobdata!["iob"] as! Double
                        pstatus2 = pstatus2 + String(format:"%.1f", iob)
                        if let cobdata = loopdata["cob"] as? [String:AnyObject] {
                            let cob = cobdata["cob"] as! Double
                            pstatus2 = pstatus2 + "  COB " + String(format:"%.0f", cob)
                        }
                        if let predictdata = loopdata["predicted"] as? [String:AnyObject] {
                            let prediction = predictdata["values"] as! [Int]
                            let plast = prediction.last as! Int
                            if mmol == false {
                            pstatus2 = pstatus2 + "  EBG " + String(plast)
                            }
                            else
                            {
                                pstatus2 = pstatus2 + "  EBG " + String(format:"%.1f", Double(plast)/18.0)
                            }
                            
                        }
                        }
                        
                        self.pumpstatus2.setText(pstatus2)
                    }
                    
                    
                }
                
                

            } else {
                // Fallback on earlier versions watch
            }
            
        }
        task3.resume()
    }
    
    func updatecore() {
 

      
      print("in update core")
        //set bg color to something old so we know if its not really updating
        let gray=UIColor.gray as UIColor
        let white=UIColor.white as UIColor
        self.primarybg.setTextColor(gray)
        self.bgdirection.setTextColor(gray)
        self.plabel.setTextColor(gray)
        self.vlabel.setTextColor(gray)
        self.minago.setTextColor(gray)
        self.deltabg.setTextColor(gray)
 
        guard let urlUser = defaults?.string(forKey: "name_preference") else {
            print ("no url is set")
            pumpstatus.setText("")
            pumpstatus.setText("URL NOT SET")
            return}
        let mmol = defaults?.bool(forKey: "mmol")
        let urlPath: String = urlUser + "/api/v1/entries/sgv.json?count=576"
        print("in watchkit")
    
        guard let url2 = URL(string: urlPath) else {
            print ("URL Parsing Error")
            self.primarybg.setText("")
            self.vlabel.setText("URL ERROR")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url2) { data, response, error in
            guard error == nil else {
                print(error!)
                self.primarybg.setText("")
                self.vlabel.setText(error?.localizedDescription)
                return
            }
            guard let data = data else {
                print("Data is empty")
                self.primarybg.setText("")
                self.vlabel.setText("No Data")
                return
            }
            
            
            DispatchQueue.main.async() {
            
                let entries = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String:AnyObject]]
            print ("read resp")
            
            
            
            
            
 // new main
            
           // print("before main")
           
            //successfully received pebble end point data
            //if let bgs=responseDict["bgs"] as? [[String:AnyObject]] {
                if entries.count > 0 {
                print("after main")
                self.bghistread=true
                let rawavailable=false as Bool
                let slope=0.0 as Double
               let intercept=0.0 as Double
                let scale=0.0 as Double
                let cbg=entries[0]["sgv"] as! Int
                let priorbg = entries[1]["sgv"] as! Int
                let direction=entries[0]["direction"] as! String
                let dbg = cbg - priorbg as Int
                let bgtime=entries[0]["date"] as! TimeInterval
                let red=UIColor.red as UIColor
                let green=UIColor.green as UIColor
                let yellow=UIColor.yellow as UIColor
                let rawcolor="green" as String
                //save as global variables
                self.bghist=entries
                   let bgs = entries as? [[String:AnyObject]]

              
    
                self.plabel.setTextColor(white)
                self.vlabel.setTextColor(white)
                self.deltabg.setTextColor(white)
                let ct=TimeInterval(Date().timeIntervalSince1970)
                let deltat=(ct-bgtime/1000)/60
                if deltat<10 {self.minago.setTextColor(UIColor.green)} else
                    if deltat<20 {self.minago.setTextColor(UIColor.yellow)} else {self.minago.setTextColor(UIColor.red)}
                self.minago.setText(String(Int(deltat))+" min ago")
 
                if (cbg<40) {
                    self.primarybg.setTextColor(red)
                    self.primarybg.setText(self.errorcode(cbg))
                    self.bgdirection.setText("")
                    self.deltabg.setText("")
                }
                    
                else
                    
                    {
                        
                        self.primarybg.setTextColor(self.bgcolor(cbg))
                        self.bgdirection.setText(self.dirgraphics(direction))
                        self.bgdirection.setTextColor(self.bgcolor(cbg))
                        let velocity=self.velocity_cf(bgs!, slope: slope,intercept: intercept,scale: scale) as Double
                        let prediction=velocity*30.0+Double(cbg)

                        self.deltabg.setTextColor(UIColor.white)
                        
                        if (mmol == false) {
                            self.primarybg.setText(String(cbg))
                            if (dbg<0) {self.deltabg.setText(String(dbg)+" mg/dl")} else {self.deltabg.setText("+"+String(dbg)+" mg/dl")}
                            self.vlabel.setText(String(format:"%.1f", velocity))
                            self.plabel.setText(String(format:"%.0f", prediction))
                        }
                        
                        else
                        
                        {   let conv = 18.0 as Double
                            let mmolbg = Double(cbg) / conv
                            let mmoltext = String(format:"%.1f", mmolbg)
                             self.primarybg.setText(mmoltext)
                            let deltammol = Double(dbg) / conv
                            let delmmoltext = String(format:"%.1f", deltammol)
                            if (dbg<0) {self.deltabg.setText(delmmoltext + " mmol/L")} else {self.deltabg.setText("+" + delmmoltext + " mmol/L")}
                            self.vlabel.setText(String(format:"%.1f", velocity/conv))
                            self.plabel.setText(String(format:"%.1f", prediction/conv))
                        }

                }

                
            } //end bgs !=nil
                
                //did not get pebble endpoint data
            else
            {
                self.bghistread=false
                self.noconnection()
                return
            }
                  //add graph
                let google=self.bggraph(self.graphlength,bghist: self.bghist!)!.addingPercentEscapes(using: String.Encoding.utf8)!
                    if (self.bghistread==true)&&(google != "NoData") {
                        self.graphhours.setTextColor(UIColor.white)
                        self.graphhours.setText("Last "+String(self.graphlength)+" Hours")
                        self.bgimage.setHidden(false)
                        let imgURL: URL = URL(string: google)! as URL
                        let task2 = URLSession.shared.dataTask(with: imgURL) { data, response, error in

                            guard error == nil else {
                                print(error!)
                                self.primarybg.setText("")
                                self.vlabel.setText(error?.localizedDescription)
                                return
                            }
                            guard let data = data else {
                                print("Data is empty")
                                self.primarybg.setText("")
                                self.vlabel.setText("Google API Error")
                                return
                            }
                            
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
                    }
            
            
        }//end dispatch
        } //end urlsession
        task.resume()
        
        
        
        
        
        
 
        
 
        
   
    }
    
    func velocity_cf(_ bgs:[[String:AnyObject]],slope:Double,intercept:Double,scale:Double)->Double {
    //linear fit to 3 data points get slope (ie velocity)
    var v=0 as Double
    var n=0 as Int
    var i=0 as Int
    let ONE_MINUTE=60000.0 as Double
    var bgsgv = [Double](repeating: 0.0, count: 4)
        var date = [Double](repeating: 0.0, count: 4)
        
      
        i=0
        while i<4 {
         date[i]=(bgs[i]["date"] as? Double)!
         bgsgv[i]=(bgs[i]["sgv"])!.doubleValue
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
    
//    func calcraw(_ sgv:Double,filt:Double,unfilt:Double, slope:Double, intercept:Double, scale:Double) -> Int
//
//    {
//        var rawv=0 as Int
//        if(sgv<40) {
//            rawv = Int(scale*(unfilt-intercept)/slope)
//        }
//        else
//        {
//            rawv = Int((unfilt-intercept)/(filt-intercept)*Double(sgv))
//
//        }
//        return rawv
//    }
    
    func bggraph(_ hours:Int,bghist:[[String:AnyObject]])-> String? {
        
        
        
        //get bghistory
        //grabbing double the data in case of gap sync issues
        let mmol = defaults?.bool(forKey: "mmol")
        var google="" as String
        let ct2=NSInteger(Date().timeIntervalSince1970)
                var xg="" as String
        var yg="" as String
        var rg="" as String
        var pc="&chco=" as String
        var maxy=0
        var maxx=0
        var miny=1000
        let bgoffset=40
        let bgth=180
        let bgtl=80
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

        
  
        //find max time, min and max bg
        var i=0 as Int;
      //  for var i=0; i<bghist.count; i=i+1 {
        while (i<bghist.count) {
            let curdate: Double = (bghist[i]["date"] as! Double)/1000
            bgtimes[i]=Int((Double(minutes)-(Double(ct2)-curdate)/(60.0)))
            print(bgtimes[i])
            if (bgtimes[i]>=0) {
                gpoints += 1
            if (bgtimes[i]>maxx) { maxx=bgtimes[i]}
            let bgi = bghist[i]["sgv"] as! Int
            if (bghist[i]["sgv"] as! Int > maxy) {maxy = bghist[i]["sgv"] as! Int}
            if (bgi < miny) {miny = bgi}
                
            }
            i=i+1;}
  
        if gpoints < 2 {return "NoData"}
        

         //insert prediction points into
        if maxy<bgth {maxy=bgth}
        if miny>bgtl {miny=bgtl}

        //create strings of data points xg (time) and yg (bg) and string of colors pc
         i=0;
        while i<bghist.count  {
            if (bgtimes[i]>=0) {
                //scale time values
                xg=xg+String(bgtimes[i]*100/minutes)+","
                var sgv:Int = bghist[i]["sgv"] as! Int
                if sgv<60 {pc=pc+"FF0000|"} else
                    if sgv<80 {pc=pc+"FFFF00|"} else
                        if sgv<180 {pc=pc+"00FF00|"} else
                            if sgv<260 {pc=pc+"FFFF00|"} else
                            {pc=pc+"FF0000|"}
                //scale bg data to 100 is the max

                sgv=(sgv-miny)*100/(maxy-miny)
                yg=yg+String(sgv)+","
                
                
           
                //add raw points on the fly if cal available
//                if cals?.count>0 && craw==true {
//                    let rawscaled=(rawv[i]-miny)*100/(maxy-miny)
//                    xg=xg+String(bgtimes[i]*100/minutes)+".05,"
//                    yg=yg+String(rawscaled)+","
//                    pc=pc+"FFFFFF|"
//                }
            }
        i=i+inc}
        
//        xg=(dropLast(xg))
//        yg=(dropLast(yg))
//        pc=(dropLast(pc))
        xg=String(xg.characters.dropLast())
        yg=String(yg.characters.dropLast())
        pc=String(pc.characters.dropLast())
        
        let low:Double=Double(bgtl-miny)/Double(maxy-miny)
        let high:Double=Double(bgth-miny)/Double(maxy-miny)
        //create string for google chart api
        //bands are at 80,180, vertical lines for hours
        let band1="&chm=r,FFFFFF,0,"+String(format:"%.2f",high-0.01)+","+String(format:"%.3f",high)
        let band2="|r,FFFFFF,0,"+String(format:"%.2f",(low))+","+String(format:"%.3f",low+0.01)
        let h:String=String(stringInterpolationSegment: 100.0/Double(hours))
        let hourlyverticals="&chg="+h+",0"
        if (mmol == false) {
                    google="https://chart.googleapis.com/chart?cht=s:nda&chxt=y&chxr=0,"+String(miny)+","+String(maxy)+"&chs=180x100"+"&chf=bg,s,000000&chls=3&chd=t:"+xg+"|"+yg+"|20"+pc+"&chxs=0,FFFFFF"+band1+band2+hourlyverticals
        }
        
        else {
            let mmolminy = Double(miny) / 18.0
            let mmolmaxy = Double(maxy) / 18.0
            google="https://chart.googleapis.com/chart?cht=s:nda&chxt=y&chxr=0,"+String(format:"%.1f",mmolminy)+","+String(format:"%.1f",mmolmaxy)+"&chs=180x100"+"&chf=bg,s,000000&chls=3&chd=t:"+xg+"|"+yg+"|20"+pc+"&chxs=0,FFFFFF"+band1+band2+hourlyverticals
            
        }
        

            return google
   
    
    }
    
    }



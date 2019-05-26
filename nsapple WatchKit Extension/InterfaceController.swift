//
//  InterfaceController.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 7/9/15.
//  Copyright (c) 2015 Perceptus.org. All rights reserved.
//

import WatchKit
import Foundation






class InterfaceController: WKInterfaceController {
   
    @IBOutlet weak var bgGraph: WKInterfaceImage!
    @IBOutlet weak var primaryBG: WKInterfaceLabel!
    @IBOutlet weak var bgDirection: WKInterfaceLabel!
    @IBOutlet weak var deltaBG: WKInterfaceLabel!
    @IBOutlet weak var minAgo: WKInterfaceLabel!
    @IBOutlet weak var graphHours: WKInterfaceLabel!
    @IBOutlet weak var hourSlider: WKInterfaceSlider!
    @IBOutlet var statusOverride: WKInterfaceLabel!
    @IBOutlet var loopStatus2: WKInterfaceLabel!
    @IBOutlet var pumpStatus: WKInterfaceLabel!
    @IBOutlet weak var prediction: WKInterfaceLabel!
    @IBOutlet weak var velocity: WKInterfaceLabel!
    @IBOutlet var errorDisplay: WKInterfaceLabel!
    @IBOutlet var basalDisplay: WKInterfaceLabel!
    var graphLength:Int=3
    var mmol = false as Bool
    var urlUser = "No User URL" as String
    var token = "" as String
    var defaults : UserDefaults?
    let consoleLogging = true
    var lastBGUpdate = 0 as TimeInterval


   
    @IBAction func hourslidervalue(_ value: Float) {
        let sliderMap:[Int:Int]=[1:24,2:12,3:6,4:3,5:1]
        let sliderValue=Int(round(value*1000)/1000)
        graphLength=sliderMap[sliderValue]!
        loadData(urlUser:urlUser, mmol: mmol)
        
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if consoleLogging == true {print("in awake")}
        

        
        let bundle = infoBundle("CFBundleIdentifier")
        if let bundle = bundle {
            let unique_id = bundle.components(separatedBy: ".")
            let name : String = "group.com." + unique_id[0] + ".nsapple"
            defaults = UserDefaults(suiteName: name)
        }
       
        else
        {
            self.errorDisplay.setTextColor(UIColor.red)
            self.errorDisplay.setText("Could Not Read Bundle Idenifier")
        }
        
            
        }
        
    
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        
        super.willActivate()
        
        if consoleLogging == true {print("in will")}
        //reread defaults
        mmol = defaults?.bool(forKey: "mmol") ?? false
        urlUser = defaults?.string(forKey: "name_preference") ?? "No User URL"
        token = defaults?.string(forKey: "token") ?? ""
        
        //polling frequency
        let deltaTime = (TimeInterval(Date().timeIntervalSince1970) - lastBGUpdate) / 60
        
        //if data very old grey it out on wakeup
        if deltaTime > 16 {
             DispatchQueue.main.async {
            self.colorBGStatus(color: UIColor.gray)
            self.colorLoopStatus(color: UIColor.gray)
            self.bgGraph.setTintColor(UIColor.gray)
            self.primaryBG.setTextColor(UIColor.gray)
            }
        }
        
        if deltaTime > 5 {
            if consoleLogging == true {print("inside load")}
            if consoleLogging == true {print(deltaTime)}
            self.errorDisplay.setHidden(true)
            loadData(urlUser: urlUser, mmol: mmol)
        }
        else
        {
            self.minAgo.setText(String(Int(deltaTime))+" min ago")
            labelColor(label: self.minAgo, timeSince: lastBGUpdate)
        }
  
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
//        colorBGStatus(color: UIColor.gray)
//        colorLoopStatus(color: UIColor.gray)
//        minAgo.setTextColor(UIColor.gray)
        if consoleLogging == true {print("in deactivate")}
        //to do add blank image and set on sleep
        super.didDeactivate()
    }
    
///////////////////////////////////////
// - Mark
    
 
    
    func loadData (urlUser: String, mmol:Bool) {
        if consoleLogging == true {print("in load BG")}
        
        if urlUser == "No User URL" {
            colorLoopStatus(color: UIColor.red)
            colorBGStatus(color: UIColor.red)
            self.pumpStatus.setText("")
            self.loopStatus2.setText("")
            errorMessage(message: "Cannot Read User NS URL.  Check Setup Of Defaults in iOS Watch App")
            return
        }
        
        let points = String(self.graphLength * 12 + 1)
        
        var urlPath: String = urlUser + "/pebble?"
        if token == "" {
            urlPath = urlPath + "count=" + points
        }
        
        else
        
        {
            urlPath = urlPath + "token=" + token + "&count=" + points
        }
        
        guard let url2 = URL(string: urlPath) else {
            colorBGStatus(color: UIColor.red)
            self.primaryBG.setText("")
            errorMessage(message: "NS URL Not Valid")
            return
        }
        var request = URLRequest(url: url2)
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        let getBGTask = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if self.consoleLogging == true {print("start bg url")}
            guard error == nil else {
                self.colorBGStatus(color: UIColor.red)
                self.primaryBG.setText("")
                self.errorMessage(message: error?.localizedDescription ?? "Server Error")
                return
            }
            guard let data = data else {
                self.colorBGStatus(color: UIColor.red)
                self.primaryBG.setText("")
                self.errorMessage(message: "No Data")
                return
            }
            let decoder = JSONDecoder()
            let pebbleResponse = try? decoder.decode(dataPebble.self, from: data)
            if let pebbleResponse = pebbleResponse {
                 DispatchQueue.main.async {
                self.updateBG(pebbleResponse: pebbleResponse, mmol:mmol)
                }
            }
            else
            {
                self.primaryBG.setText("")
                self.colorBGStatus(color: UIColor.red)
                self.errorMessage(message: "BG Decoding Error.  Check NightScout URL. ")
                return
            }
        }
        getBGTask.resume()
        
     
        var urlPath2 = urlUser + "/api/v1/devicestatus.json?count=1"
        if token != "" {
            urlPath2 = urlUser + "/api/v1/devicestatus.json?token=" + token + "&count=1"
        }
        
        let escapedAddress = urlPath2.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
        guard let urlLoop = URL(string: escapedAddress!) else {
            self.colorLoopStatus(color: UIColor.red)
            pumpStatus.setText("")
            self.errorMessage(message: "Loop URL ERROR")
            return
        }
        
        if consoleLogging == true {print("entered 2nd task")}
        var requestLoop = URLRequest(url: urlLoop)
        requestLoop.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        let loopTask = URLSession.shared.dataTask(with: requestLoop) { data, response, error in
            if self.consoleLogging == true {print("in update loop")}
            guard error == nil else {
                self.colorLoopStatus(color: UIColor.red)
                self.pumpStatus.setText("")
                self.errorMessage(message: error?.localizedDescription ?? "Server Error")
                return
            }
            guard let data = data else {
                self.colorLoopStatus(color: UIColor.red)
                self.errorMessage(message: "Loop Data is Empty")
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data) as! [[String:AnyObject]]
            
            if let json = json {
                
                DispatchQueue.main.async {
                    self.updateLoopStatus(json: json, mmol: mmol)
                }
                
            }
                
            else
                
            {
                self.colorLoopStatus(color: UIColor.red)
                self.pumpStatus.setText("")
                self.errorMessage(message: "Device Status Decoding Error.  Check Nightscout URL.")
                return
            }
            if self.consoleLogging == true {print("finish pump update")}
            
        }
        loopTask.resume()
        
        
        
    }
    
    func updateLoopStatus(json: [[String:AnyObject]], mmol: Bool) {
        
        if consoleLogging == true {print("in updatePump")}
       
        if json.count == 0 {
            self.errorMessage(message: "No Records")
            colorLoopStatus(color: UIColor.red)
            return
            
        }
        //only grabbing one record since ns sorts by {created_at : -1}
        let lastData = json[0] as [String : AnyObject]?
  
            //pump and uploader
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate,
                                   .withTime,
                                   .withDashSeparatorInDate,
                                   .withColonSeparatorInTime]
            var pstatus:String = "Res "
            let lastPump = lastData?["pump"] as! [String : AnyObject]?
            if lastPump != nil {
                if let pumpTime = formatter.date(from: (lastPump?["clock"] as! String))?.timeIntervalSince1970  {
                    labelColor(label: self.pumpStatus, timeSince: pumpTime)
                    if let res = lastPump?["reservoir"] as? Double
                    {
                        pstatus = pstatus + String(format:"%.0f", res)
                    }
                        
                    else
                        
                    {
                        pstatus = pstatus + "N/A"
                    }
                    
                    if let uploader = lastData?["uploader"] as? [String:AnyObject] {
                        let upbat = uploader["battery"] as! Double
                        pstatus = pstatus + " UpBat " + String(format:"%.0f", upbat)
                    }
                    self.pumpStatus.setText(pstatus)
                    //add back if loop ever uploads again
                    //                        if let riley = lastpump["radioAdapter"] as? [String:AnyObject] {
                    //                            if let rrssi = riley["RSSI"] as? Int {
                    //                                pstatus = pstatus + "%  RdB " + String(rrssi)
                    //                            }
                    //                        }
                    
                }
                
            } //finish pump data
                
            else
                
            {
                pstatus = "Pump Record Error"
                colorLoopStatus(color: UIColor.red)
            }

            //loop
            let lastLoop = lastData?["loop"] as! [String : AnyObject]?
            var pstatus2:String = " IOB "
            if lastLoop != nil {
                if let looptime = formatter.date(from: (lastLoop?["timestamp"] as! String))?.timeIntervalSince1970  {
                    labelColor(label: self.loopStatus2, timeSince: looptime)
                    if let failure = lastLoop?["failureReason"] {
                        self.pumpStatus.setText(pstatus)
                        //colorLoopStatus(color: UIColor.red)
                      self.loopStatus2.setTextColor(UIColor.red)
                        pstatus2 = "Loop Failure "
                        self.loopStatus2.setText(pstatus2)
                        self.errorMessage(message: failure as? String ?? "Unknown Failure")

                    }
                    else
                    {
                        //self.errorDisplay.setText("")
                     //  colorLoopStatus(color: UIColor.green)
                        if let enacted = lastLoop?["enacted"] as? [String:AnyObject] {
                            if let tempbasal = enacted["rate"] as? Double {
                                let basalStatus = " Basal " + String(format:"%.1f", tempbasal)
                                self.basalDisplay.setText(basalStatus)
                                labelColor(label: self.basalDisplay, timeSince: looptime)
                            }
                        }
                        if let iobdata = lastLoop?["iob"] as? [String:AnyObject] {
                            pstatus2 = pstatus2 + String(format:"%.1f", (iobdata["iob"] as! Double))
                        }
                        if let cobdata = lastLoop?["cob"] as? [String:AnyObject] {
                            pstatus2 = pstatus2 + "  COB " + String(format:"%.0f", cobdata["cob"] as! Double)
                        }
                        if let predictdata = lastLoop?["predicted"] as? [String:AnyObject] {
                            let prediction = predictdata["values"] as! [Double]
                            pstatus2 = pstatus2 +  " EBG " + bgOutput(bg: prediction.last!, mmol: mmol)
                        }
                        self.loopStatus2.setText(pstatus2)
                        labelColor(label: self.loopStatus2, timeSince: looptime)
                        
                    }
                }
                
                
            } //finish loop
                
            else
                
            {
                pstatus2 = "Loop Record Error"
                colorLoopStatus(color: UIColor.red)
                self.loopStatus2.setText(pstatus2)
            }
            

            
            //overrides
            var pstatus3 = "" as String
            self.statusOverride.setHidden(true)
            if let lastOverride = lastData?["override"] as! [String : AnyObject]? {
                if let overridetime = formatter.date(from: (lastOverride["timestamp"] as! String))?.timeIntervalSince1970  {
                   labelColor(label: self.statusOverride, timeSince: overridetime)
                } //finish color
                if lastOverride["active"] as! Bool {
                     self.statusOverride.setHidden(false)
                    let currentCorrection  = lastOverride["currentCorrectionRange"] as! [String: AnyObject]
                    pstatus3 = "BGTargets("
                    let minValue = currentCorrection["minValue"] as! Double
                    let maxValue = currentCorrection["maxValue"] as! Double
                    pstatus3 = pstatus3 + bgOutput(bg: minValue, mmol: mmol) + ":" + bgOutput(bg: maxValue, mmol: mmol) + ") M:"
                    let multiplier = lastOverride["multiplier"] as! Double
                    pstatus3 = pstatus3 + String(format:"%.1f", multiplier)
                }
                
                
            } //if let for override - older versions dont have an overide field
            
            self.statusOverride.setText(pstatus3)
 
        if consoleLogging == true {print("end updatePump")}
    }
    
    func updateBG (pebbleResponse: dataPebble, mmol: Bool) {
        if consoleLogging == true {print("in update BG")}

            var entries = [entriesData]()
            var j: Int = 0
            //cast string sgvs to int
            //to do there must be a simpler way ......
            while j < pebbleResponse.bgs.count {
                entries.append(entriesData(sgv: Int(pebbleResponse.bgs[j].sgv) ?? 0, date: pebbleResponse.bgs[j].datetime, direction: pebbleResponse.bgs[j].direction ))
                j=j+1
            }
            //successfully received pebble end point data
            if entries.count > 0 {
                let currentBG=entries[0].sgv
                let priorBG = entries[1].sgv
                let direction=entries[0].direction
                let deltaBG = currentBG - priorBG as Int
                let lastBGTime=entries[0].date / 1000 //NS has different units
                let red=UIColor.red as UIColor
                let deltaTime=(TimeInterval(Date().timeIntervalSince1970)-lastBGTime)/60
                self.minAgo.setText(String(Int(deltaTime))+" min ago")
                lastBGUpdate = lastBGTime
               
                
                if (currentBG<40) {
                    self.primaryBG.setTextColor(red)
                    self.primaryBG.setText(bgErrorCode(currentBG))
                    self.bgDirection.setText("")
                    self.deltaBG.setText("")
                }
                    
                else
                    
                {
             
                   labelColor(label: self.minAgo, timeSince: lastBGTime)
                    self.primaryBG.setTextColor(bgcolor(currentBG))
                    self.primaryBG.setText(bgOutput(bg: Double(currentBG), mmol: mmol))
                    self.bgDirection.setText(bgDirectionGraphic(direction))
                    self.bgDirection.setTextColor(bgcolor(currentBG))
                    let velocity=velocity_cf(entries) as Double
                    let prediction=velocity*30.0+Double(currentBG)
                    self.deltaBG.setTextColor(UIColor.white)
                    if deltaBG < 0 {
                        self.deltaBG.setText(bgOutput(bg: Double(deltaBG), mmol: mmol) + " mg/dl")
                    }
                    else
                    {
                        self.deltaBG.setText("+"+bgOutput(bg: Double(deltaBG), mmol: mmol)+" mg/dl")
                    }
                    
                    self.velocity.setText(velocityOutput(v: velocity, mmol: mmol))
                    self.prediction.setText(bgOutput(bg: prediction, mmol: mmol))
                    
                }
                
                
            } //end bgs !=nil
                
                //did not get pebble endpoint data
            else
            {
               
               self.errorMessage(message: "Didnt Receive BG Data")
                colorLoopStatus(color: UIColor.red)
                //to do add output to error window?
                return
            }
        
        createGraph(hours: self.graphLength, bghist: entries, mmol: mmol)
        self.graphHours.setText(String(self.graphLength) + " Hour Graph")
   
            if consoleLogging == true {print("end update bg")}
    }

    
    func createGraph(hours:Int, bghist:[entriesData], mmol: Bool) {
        // create graph
        
        // Create a graphics context
        let height : CGFloat = 101
        let width = self.contentFrame.size.width
        let size = CGSize(width:width, height:height)

        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(1.0)
        
        var xdata = [Double]()
        var ydata = [Double]()
        var colorData = [UIColor]()
        var miny : Double
        var maxy: Double
        
        //ydata is scaled to 100
        //xdata is scaled to width
        //creatre stand alone scatter plot package that takes generic data of this form
        //3 arrays - xdata, ydata, color, y min and max, x min and max
        //get the scaled data
        (xdata, ydata, colorData, miny, maxy) = self.bgScaling(hours, bgHist: bghist, width: width)
        
        //create data points
        var i: Int = 0
        let leftbuffer : Double = 20
        let widthD : Double = Double(width)
        while i < xdata.count {
            //reverse y data, rescale x for leftbuffer
            ydata[i] = 100.0 - ydata[i]
            xdata[i] = (widthD - leftbuffer) / widthD * xdata[i] + leftbuffer
            context!.setStrokeColor(colorData[i].cgColor)
            let rect = CGRect(x: CGFloat(xdata[i]), y: CGFloat(ydata[i]), width: width/2/100, height: 50/100)
            context?.addEllipse(in: rect)
            context?.drawPath(using: .fillStroke)
            i=i+1
        }
        
        //draw horizontal lines at 80 and 180 for xcontext
        //to do make user configurable
        
        //draw high and low bound bars
        let lowLimit : CGFloat = 80
        let highLimit : CGFloat = 180
        let topBound : CGFloat = 100 - (highLimit - CGFloat(miny))/(CGFloat(maxy) - CGFloat(miny)) * 100
        let bottomBound : CGFloat = 100 - (lowLimit - CGFloat(miny))/(CGFloat(maxy) - CGFloat(miny)) * 100
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(2)
        context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: topBound+1))
        context?.addLine(to: CGPoint(x: width, y: topBound+1))
        context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: bottomBound-1))
        context?.addLine(to: CGPoint(x: width, y: bottomBound-1))
        //draw outline if outline isnt set by low or high limit bars
        context?.setLineWidth(1)
        if (abs(miny - Double(lowLimit)) > 5 ) {
            context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: height))
            context?.addLine(to: CGPoint(x: width, y: height))
        }
        
        if (abs(maxy - Double(highLimit)) > 5 ) {
            context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: 0))
            context?.addLine(to: CGPoint(x: width, y: 0))
        }
        context!.strokePath();
        //draw vertical dashedlines on hour marks
        context?.setStrokeColor(UIColor.gray.cgColor)
        context?.setLineDash(phase: 4, lengths: [4])
        context?.move(to:CGPoint(x: CGFloat(leftbuffer), y: 0))
        context?.addLine(to: CGPoint(x: CGFloat(leftbuffer), y: height))
        context?.move(to:CGPoint(x: width-1, y: 0))
        context?.addLine(to: CGPoint(x: width-1, y: height))
        
        i=1
        while i < hours {
            let ratio : CGFloat = CGFloat(Double(i)/Double(hours))
            let xvert : CGFloat = width*ratio
            context?.move(to:CGPoint(x: (width - CGFloat(leftbuffer))*xvert/width + CGFloat(leftbuffer), y: 0))
            context?.addLine(to: CGPoint(x: (width - CGFloat(leftbuffer))*xvert/width + CGFloat(leftbuffer), y: height))
            i=i+1
        }
        context!.strokePath();
        
        
        //labels
        let ybuffer : CGFloat = 5
        let xbuffer : CGFloat = 9
        //round to 5's or mgdl, 0.2 for mmol/L
        var rounder : Double = 5
        if mmol {rounder = 0.2}
        self.drawText(context: context, text: bgOutput(bg: round(miny/rounder) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: height - ybuffer)
        self.drawText(context: context, text: bgOutput(bg: round(maxy/rounder) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: ybuffer + 1 )
        self.drawText(context: context, text: bgOutput(bg: round((maxy + miny) / (2.0 * rounder)) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: height/2)
        
        
        
        // Draw and Convert to UIImage
        
        let cgimage = context!.makeImage();
        let uiimage = UIImage(cgImage: cgimage!)
        
        // End the graphics context
        UIGraphicsEndImageContext()
     DispatchQueue.main.async() {
        self.bgGraph.setImage(uiimage)
        }
    }
    
    
    
    func drawText( context : CGContext?, text : NSString, centreX : CGFloat, centreY : CGFloat )
    {
        let attributes = [
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin),
            NSAttributedStringKey.foregroundColor : UIColor.white
        ]
        
        let textSize = text.size( withAttributes: attributes )
        
        text.draw(
            in: CGRect( x: centreX - textSize.width / 2.0,
                        y: centreY - textSize.height / 2.0,
                        width: textSize.width,
                        height: textSize.height + 2),
            withAttributes : attributes )
    }
    
    
  
    func noBGConnection() {
        deltaBG.setText("No BG Connection")
        deltaBG.setTextColor(UIColor.red)
        
    }
    
    func bgcolor(_ value:Int)->UIColor
    {
        
        let red=UIColor.red as UIColor
        let green=UIColor.green as UIColor
        let yellow=UIColor.yellow as UIColor
        var sgvColor=green as UIColor
        
        if (value<65) {sgvColor=red}
        else
            if(value<80) {sgvColor=yellow}
                
            else
                if (value<180) {sgvColor=green}
                    
                else
                    if (value<250) {sgvColor=yellow}
                    else
                    {sgvColor=red}
        return sgvColor
    }
    
    
    
    
    
    func bgScaling(_ hours:Int,bgHist:[entriesData], width: CGFloat)-> ([Double], [Double], [UIColor], Double, Double) {


        let ct2=NSInteger(Date().timeIntervalSince1970)

        var maxy=0
        var maxx=0
        var miny=1000
        var minx=1000000
        let bgHighLine=180
        let bgLowLine=80
        var bgTimes = [Int]()
        let minutes=hours*60
        var inc:Int=1
        if (hours==3||hours==1) {inc=1} else
            if hours==6 {inc=2} else
                if hours==12 {inc=3} else
                {inc=5}
       
        //find max and min time, min and max bg
        var i=0 as Int;

        while (i<bgHist.count) {
            let curDate: Double = (bgHist[i].date)/1000
            bgTimes.append(Int((Double(minutes)-(Double(ct2)-curDate)/(60.0))))

            if (bgTimes[i]>=0) {
                if (bgTimes[i]>maxx) {maxx=bgTimes[i]}
                if (bgTimes[i]<minx) {minx=bgTimes[i]}
                if (bgHist[i].sgv > maxy) {maxy = bgHist[i].sgv}
                if (bgHist[i].sgv < miny) {miny = bgHist[i].sgv}
            }
            i=i+1;}
        if maxy<bgHighLine {maxy=bgHighLine}
        if miny>bgLowLine {miny=bgLowLine}
        
        //create strings of data points xg (time) and yg (bg) and string of colors pc
        i=0;
        
        var xdata = [Double] ()
        var ydata = [Double] ()
        var dataColor = [UIColor] ()
        
        while i<bgHist.count  {
            //only work on values that are not beyond time window
            if (bgTimes[i]>=0) {
                //scale time values
                xdata.append(Double(bgTimes[i])*Double(width)/Double(minutes))
                let sgv:Int = bgHist[i].sgv
                if sgv<60 {dataColor.append(UIColor.red)} else
                    if sgv<80 {dataColor.append(UIColor.yellow)} else
                        if sgv<180 {dataColor.append(UIColor.green)} else
                            if sgv<260 {dataColor.append(UIColor.yellow)} else
                            {dataColor.append(UIColor.red)}
                //scale bg data to 100 is the max
                
                ydata.append(Double((sgv-miny)*100/(maxy-miny)))
 
            }
            i=i+inc}
        
        return (xdata, ydata, dataColor, Double(miny), Double(maxy))
        
        
    }
    
    
    
    func colorBGStatus (color: UIColor) {
        self.primaryBG.setTextColor(color)
        self.bgDirection.setTextColor(color)
        self.deltaBG.setTextColor(color)
    }
    
    func colorLoopStatus (color: UIColor) {
        self.pumpStatus.setTextColor(color)
        self.loopStatus2.setTextColor(color)
        self.statusOverride.setTextColor(color)
        self.basalDisplay.setTextColor(color)
    }
    
    func errorMessage(message: String) {
        self.errorDisplay.setHidden(false)
        self.errorDisplay.setTextColor(UIColor.red)
        self.errorDisplay.setText(message)
    }
    
    
    
    
    
    
  
    
    
    }



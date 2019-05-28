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
    
    @IBOutlet weak var bgGraphDisplay: WKInterfaceImage!
    @IBOutlet weak var primaryBGDisplay: WKInterfaceLabel!
    @IBOutlet weak var bgDirectionDisplay: WKInterfaceLabel!
    @IBOutlet weak var deltaBGDisplay: WKInterfaceLabel!
    @IBOutlet weak var minAgoBGDisplay: WKInterfaceLabel!
    @IBOutlet weak var graphHoursDisplay: WKInterfaceLabel!
    @IBOutlet weak var hourSlider: WKInterfaceSlider!
    @IBOutlet var statusOverrideDisplay: WKInterfaceLabel!
    @IBOutlet var loopStatusDisplay: WKInterfaceLabel!
    @IBOutlet var pumpDataDisplay: WKInterfaceLabel!
    @IBOutlet weak var predictionDisplay: WKInterfaceLabel!
    @IBOutlet weak var velocityDisplay: WKInterfaceLabel!
    @IBOutlet var errorDisplay: WKInterfaceLabel!
    @IBOutlet var basalDisplay: WKInterfaceLabel!
    var graphHours:Int=3
    var mmol = false as Bool
    var urlUser = "No User URL" as String
    var token = "" as String
    var defaults : UserDefaults?
    let consoleLogging = true
    var timeofLastBGUpdate = 0 as TimeInterval
    
    
    @IBAction func hourslidervalue(_ value: Float) {
        let sliderMap:[Int:Int]=[1:24,2:12,3:6,4:3,5:1]
        let sliderValue=Int(round(value*1000)/1000)
        graphHours=sliderMap[sliderValue]!
        loadBGandDeviceStatus(urlUser:urlUser)
        
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        //TODO change console logginh to true ios logging
        if consoleLogging == true {print("in awake")}
        self.errorDisplay.setTextColor(UIColor.red)
        setupUserDefaults()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if consoleLogging == true {print("in will")}
        //TODO setup reload user defaults on a notification from a change not every time
        readUserDefaults()
        pollForNewData()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        if consoleLogging == true {print("in deactivate")}
        super.didDeactivate()
    }
    
    //////////////////////////
    // Mark
    
    func setupUserDefaults() {
        let bundle = infoBundle("CFBundleIdentifier")
        if let bundle = bundle {
            let unique_id = bundle.components(separatedBy: ".")
            let appGroup : String = "group.com." + unique_id[0] + ".nsapple"
            defaults = UserDefaults(suiteName: appGroup)
        }
        else
        {
            self.errorDisplay.setText("Could Not Read Bundle Idenifier.")
        }
    }
    
    func readUserDefaults() {
        //reread defaults
        mmol = defaults?.bool(forKey: "mmol") ?? false
        urlUser = defaults?.string(forKey: "name_preference") ?? "No User URL"
        token = defaults?.string(forKey: "token") ?? ""
    }
    
    func pollForNewData() {
        let deltaTimeFromLastBG = (TimeInterval(Date().timeIntervalSince1970) - timeofLastBGUpdate) / 60
        if deltaTimeFromLastBG > 16 {
            DispatchQueue.main.async {
                self.primaryBGDisplay.setTextColor(UIColor.gray)
                self.colorBGStatus(color: UIColor.gray)
                self.colorLoopStatus(color: UIColor.gray)
                self.bgGraphDisplay.setTintColor(UIColor.gray)
                self.primaryBGDisplay.setTextColor(UIColor.gray)
            }
        }
        if deltaTimeFromLastBG > 5 {
            if consoleLogging == true {print("inside load")}
            if consoleLogging == true {print(deltaTimeFromLastBG)}
            self.errorDisplay.setHidden(true)
            loadBGandDeviceStatus(urlUser: urlUser)
        }
        else
        {
            self.minAgoBGDisplay.setText(String(Int(deltaTimeFromLastBG))+" min ago")
            labelColor(label: self.minAgoBGDisplay, timeSince: timeofLastBGUpdate)
        }
    }
    
    
    
    func loadBGandDeviceStatus (urlUser: String) {
        if consoleLogging == true {print("in load BG")}
        self.errorDisplay.setText("")
        
        if urlUser == "No User URL" {
            self.clearBGDisplay()
            self.clearLoopDisplay()
            errorMessage(message: "Cannot Read User NS URL.  Check Setup Of Defaults in iOS Watch App")
            return
        }
        
        loadBGData(urlUser: urlUser)
        loadDeviceStatus(urlUser: urlUser)
    }
    
    func loadBGData(urlUser: String) {
        let points = String(self.graphHours * 12 + 1)
        var urlBGDataPath: String = urlUser + "/api/v1/entries.json?"
        if token == "" {
            urlBGDataPath = urlBGDataPath + "count=" + points
        }
        else
        {
            urlBGDataPath = urlBGDataPath + "token=" + token + "&count=" + points
        }
        guard let urlBGData = URL(string: urlBGDataPath) else {
            clearBGDisplay()
            errorMessage(message: "NS URL Not Valid")
            return
        }
        var request = URLRequest(url: urlBGData)
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        
        let getBGTask = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if self.consoleLogging == true {print("start bg url")}
            guard error == nil else {
                self.clearBGDisplay()
                self.errorMessage(message: error?.localizedDescription ?? "Server Error")
                return
            }
            guard let data = data else {
                self.clearBGDisplay()
                self.errorMessage(message: "No Data")
                return
            }
            
            let decoder = JSONDecoder()
            let entriesResponse = try? decoder.decode([sgvData].self, from: data)
            if let entriesResponse = entriesResponse {
                DispatchQueue.main.async {
                    self.updateBG(entries: entriesResponse)
                }
            }
            else
            {
                self.clearBGDisplay()
                self.errorMessage(message: "BG Decoding Error.  Check NightScout URL. ")
                return
            }
        }
        getBGTask.resume()
        
    }
    
    func loadDeviceStatus(urlUser: String) {
        var urlStringDeviceStatus = urlUser + "/api/v1/devicestatus.json?count=1"
        if token != "" {
            urlStringDeviceStatus = urlUser + "/api/v1/devicestatus.json?token=" + token + "&count=1"
        }
        
        let escapedAddress = urlStringDeviceStatus.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
        guard let urlDeviceStatus = URL(string: escapedAddress!) else {
            self.clearLoopDisplay()
            self.clearPumpDisplay()
            self.errorMessage(message: "Loop URL ERROR.")
            return
        }
        
        if consoleLogging == true {print("entered 2nd task.")}
        var requestDeviceStatus = URLRequest(url: urlDeviceStatus)
        requestDeviceStatus.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        let deviceStatusTask = URLSession.shared.dataTask(with: requestDeviceStatus) { data, response, error in
            if self.consoleLogging == true {print("in update loop.")}
            guard error == nil else {
                self.clearLoopDisplay()
                self.clearPumpDisplay()
                self.errorMessage(message: error?.localizedDescription ?? "Server Error.")
                return
            }
            guard let data = data else {
                self.clearLoopDisplay()
                self.clearPumpDisplay()
                self.errorMessage(message: "Device Status Data is Empty.")
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data) as! [[String:AnyObject]]
            
            if let json = json {
                DispatchQueue.main.async {
                    self.updateDeviceStatusDisplay(jsonDeviceStatus: json)
                }
            }
            else
            {
                self.clearLoopDisplay()
                self.clearPumpDisplay()
                self.errorMessage(message: "Device Status Decoding Error.  Check Nightscout URL.")
                return
            }
            if self.consoleLogging == true {print("finish pump update")}
        }
        deviceStatusTask.resume()
    }
    
    func updateDeviceStatusDisplay(jsonDeviceStatus: [[String:AnyObject]]) {
        
        if consoleLogging == true {print("in updatePump")}
        
        if jsonDeviceStatus.count == 0 {
            self.errorMessage(message: "No Device Status Records.")
            clearPumpDisplay()
            clearLoopDisplay()
            return
            
        }
        //only grabbing one record since ns sorts by {created_at : -1}
        let lastDeviceStatus = jsonDeviceStatus[0] as [String : AnyObject]?
        
        //pump and uploader
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate,
                                   .withTime,
                                   .withDashSeparatorInDate,
                                   .withColonSeparatorInTime]
        var pumpStatusString:String = "Res "
        let lastPumpRecord = lastDeviceStatus?["pump"] as! [String : AnyObject]?
        if lastPumpRecord != nil {
            if let lastPumpTime = formatter.date(from: (lastPumpRecord?["clock"] as! String))?.timeIntervalSince1970  {
                labelColor(label: self.pumpDataDisplay, timeSince: lastPumpTime)
                if let reservoirData = lastPumpRecord?["reservoir"] as? Double
                {
                    pumpStatusString += String(format:"%.0f", reservoirData)
                }
                    
                else
                    
                {
                    pumpStatusString += "N/A"
                }
                
                if let uploader = lastDeviceStatus?["uploader"] as? [String:AnyObject] {
                    let upbat = uploader["battery"] as! Double
                    pumpStatusString += " UpBat " + String(format:"%.0f", upbat)
                }
                self.pumpDataDisplay.setText(pumpStatusString)
            }
            
        } //finish pump data
            
        else
            
        {
            clearPumpDisplay()
            self.errorMessage(message: "Device Status Error - No Pump Field.")
            //TODO have errormessages add, end all with period versus always reset
        }
        
        //loop
        let lastLoopRecord = lastDeviceStatus?["loop"] as! [String : AnyObject]?
        var loopStatusText:String = " IOB "
        if lastLoopRecord != nil {
            if let lastLoopTime = formatter.date(from: (lastLoopRecord?["timestamp"] as! String))?.timeIntervalSince1970  {
                labelColor(label: self.loopStatusDisplay, timeSince: lastLoopTime)
                if let failure = lastLoopRecord?["failureReason"] {
                    clearLoopDisplay()
                    //TODO WHY was this here???      self.pumpDataDisplay.setText(pstatus)
                    self.loopStatusDisplay.setTextColor(UIColor.red)
                    loopStatusText = "Loop Failure "
                    self.loopStatusDisplay.setText(loopStatusText)
                    self.errorMessage(message: failure as? String ?? "Unknown Failure")
                }
                else
                {
                    if let enacted = lastLoopRecord?["enacted"] as? [String:AnyObject] {
                        if let lastTempBasal = enacted["rate"] as? Double {
                            let lateBasalStatus = " Basal " + String(format:"%.1f", lastTempBasal)
                            self.basalDisplay.setText(lateBasalStatus)
                            labelColor(label: self.basalDisplay, timeSince: lastLoopTime)
                        }
                    }
                    if let iobdata = lastLoopRecord?["iob"] as? [String:AnyObject] {
                        loopStatusText +=  String(format:"%.1f", (iobdata["iob"] as! Double))
                    }
                    if let cobdata = lastLoopRecord?["cob"] as? [String:AnyObject] {
                        loopStatusText += "  COB " + String(format:"%.0f", cobdata["cob"] as! Double)
                    }
                    if let predictdata = lastLoopRecord?["predicted"] as? [String:AnyObject] {
                        let prediction = predictdata["values"] as! [Double]
                        loopStatusText += " EBG " + bgOutput(bg: prediction.last!, mmol: mmol)
                    }
                    self.loopStatusDisplay.setText(loopStatusText)
                    labelColor(label: self.loopStatusDisplay, timeSince: lastLoopTime)
                    
                }
            }
            
        }
        else
        {
            clearLoopDisplay()
            self.errorMessage(message: "Loop Record Error.")
        }
        
        var overrideText = "" as String
        self.statusOverrideDisplay.setHidden(true)
        if let lastOverride = lastDeviceStatus?["override"] as! [String : AnyObject]? {
            if let lastOverrideTime = formatter.date(from: (lastOverride["timestamp"] as! String))?.timeIntervalSince1970  {
                labelColor(label: self.statusOverrideDisplay, timeSince: lastOverrideTime)
            }
            if lastOverride["active"] as! Bool {
                self.statusOverrideDisplay.setHidden(false)
                let lastCorrection  = lastOverride["currentCorrectionRange"] as! [String: AnyObject]
                overrideText = "BGTargets("
                let minValue = lastCorrection["minValue"] as! Double
                let maxValue = lastCorrection["maxValue"] as! Double
                overrideText += bgOutput(bg: minValue, mmol: mmol) + ":" + bgOutput(bg: maxValue, mmol: mmol) + ") M:"
                let multiplier = lastOverride["multiplier"] as! Double
                overrideText = overrideText + String(format:"%.1f", multiplier)
                self.statusOverrideDisplay.setText(overrideText)
            }
        }
        
        if consoleLogging == true {print("end updatePump")}
    }
    
    func updateBG (entries: [sgvData]) {
        if consoleLogging == true {print("in update BG")}
        
        if entries.count > 0 {
            let latestBG = entries[0].sgv
            let priorBG = entries[1].sgv
            let directionBG = entries[0].direction
            let deltaBG = latestBG - priorBG as Int
            let lastBGTime = entries[0].date / 1000 //NS has different units
            let red = UIColor.red as UIColor
            let deltaTime = (TimeInterval(Date().timeIntervalSince1970)-lastBGTime)/60
            self.minAgoBGDisplay.setText(String(Int(deltaTime))+" min ago")
            timeofLastBGUpdate = lastBGTime
            if (latestBG<40) {
                self.primaryBGDisplay.setTextColor(red)
                self.primaryBGDisplay.setText(bgErrorCode(latestBG))
                self.bgDirectionDisplay.setText("")
                self.deltaBGDisplay.setText("")
            }
            else
            {
                labelColor(label: self.minAgoBGDisplay, timeSince: lastBGTime)
                self.primaryBGDisplay.setTextColor(bgcolor(latestBG))
                self.primaryBGDisplay.setText(bgOutput(bg: Double(latestBG), mmol: mmol))
                self.bgDirectionDisplay.setText(bgDirectionGraphic(directionBG))
                self.bgDirectionDisplay.setTextColor(bgcolor(latestBG))
                let velocity=velocity_cf(entries) as Double
                let prediction=velocity*30.0+Double(latestBG)
                self.deltaBGDisplay.setTextColor(UIColor.white)
                
                if deltaBG < 0 {
                    self.deltaBGDisplay.setText(bgOutput(bg: Double(deltaBG), mmol: mmol) + " mg/dl")
                }
                else
                {
                    self.deltaBGDisplay.setText("+"+bgOutput(bg: Double(deltaBG), mmol: mmol)+" mg/dl")
                }
                self.velocityDisplay.setText(velocityOutput(v: velocity, mmol: mmol))
                self.predictionDisplay.setText(bgOutput(bg: prediction, mmol: mmol))
            }
            
        } //end bgs !=nil
        else
        {
            self.errorMessage(message: "Didnt Receive BG Data.")
            clearBGDisplay()
            return
        }
        
        createGraph(hours: self.graphHours, bghist: entries)
        self.graphHoursDisplay.setText(String(self.graphHours) + " Hour Graph")
        
        if consoleLogging == true {print("end update bg")}
    }
    
    
       
}



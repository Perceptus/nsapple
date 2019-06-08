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
        loadBGandProperties(urlUser:urlUser)
        
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        //TODO change console logginh to true ios logging
        if consoleLogging == true {print("in awake")}
        self.errorDisplay.setTextColor(UIColor.red)
        setupUserDefaults()
        readUserDefaults()
        
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
            let appGroup = "group.com." + unique_id[0] + ".nsapple"
            defaults = UserDefaults(suiteName: appGroup)
        }
        else
        {
                self.errorDisplay.setText("Could Not Read Bundle Idenifier.")
        }
    }
    
    @objc func readUserDefaults() {
        print("in read user defaults")
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
            loadBGandProperties(urlUser: urlUser)
        }
        else
        {
            DispatchQueue.main.async {
                self.minAgoBGDisplay.setText(String(Int(deltaTimeFromLastBG))+" min ago")
                self.labelColor(label: self.minAgoBGDisplay, timeSince: self.timeofLastBGUpdate)
            }
        }
    }
    
    
    
    func loadBGandProperties (urlUser: String) {
        if consoleLogging == true {print("in load BG")}
        self.errorDisplay.setText("")        
        if urlUser == "No User URL" {
            self.clearEntireDisplay()
            errorMessage(message: "Cannot Read User NS URL.  Check Setup Of Defaults in iOS Watch App")
            return
        }
        
        loadBGData(urlUser: urlUser)
        loadProperties(urlUser: urlUser)
    }
    
    func loadBGData(urlUser: String) {
        let points = String(self.graphHours * 12 + 1)
        var urlBGDataPath: String = urlUser + "/api/v1/entries/sgv.json?"
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
                self.errorMessage(message: "No BG Data")
                return
            }
            
            let decoder = JSONDecoder()
            let entriesResponse = try? decoder.decode([sgvData].self, from: data)
            if let entriesResponse = entriesResponse {
  //              DispatchQueue.main.async {
                    self.updateBG(entries: entriesResponse)
  //              }
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
    
    func loadProperties(urlUser: String) {
        var urlStringDeviceStatus = urlUser + "/api/v2/properties"
        if token != "" {
            urlStringDeviceStatus = urlUser + "/api/v2/properties?token=" + token
        }
        
        let escapedAddress = urlStringDeviceStatus.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
        guard let urlDeviceStatus = URL(string: escapedAddress!) else {
            self.clearPumpLoopDisplay()
            self.errorMessage(message: "URL Syntax Error.")
            return
        }
        
        if consoleLogging == true {print("entered 2nd task.")}
        var requestDeviceStatus = URLRequest(url: urlDeviceStatus)
        requestDeviceStatus.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        let deviceStatusTask = URLSession.shared.dataTask(with: requestDeviceStatus) { data, response, error in
            if self.consoleLogging == true {print("in update loop.")}
            guard error == nil else {
                self.clearPumpLoopDisplay()
                self.errorMessage(message: error?.localizedDescription ?? "Server Error.")
                return
            }
            guard let data = data else {
                self.clearPumpLoopDisplay()
                self.errorMessage(message: "Properties Data is Empty.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(Properties.self, from: data)
//                DispatchQueue.main.async {
                    self.updatePropertiesDisplay(properties: json)
//                }
            }
                
            catch let jsonError {
                self.clearPumpLoopDisplay()
                self.errorMessage(message: "Error Decoding Properties. " + jsonError.localizedDescription)
                return
                
            }
            if self.consoleLogging == true {print("finish pump update")}
        }
        deviceStatusTask.resume()
    }
    
    
    
    func updatePropertiesDisplay(properties: Properties) {
        
        if consoleLogging == true {print("in updatePump")}
        //pump and uploader
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate,
                                   .withTime,
                                   .withDashSeparatorInDate,
                                   .withColonSeparatorInTime]
        var pumpStatusString:String = "Res "
        
        if let lastReservoir = properties.pump?.pump.reservoir, let lastPumpCreatedAt = properties.pump?.createdAt {
            if let lastPumpTime = formatter.date(from: lastPumpCreatedAt)?.timeIntervalSince1970 {
                DispatchQueue.main.async {
                    self.labelColor(label: self.pumpDataDisplay, timeSince: lastPumpTime)
                }
                pumpStatusString += String(format:"%.0f", lastReservoir)
            }
            else
            {
                pumpStatusString += "N/A"
            }
        }
        
        if let uploaderString = properties.upbat?.display {
            pumpStatusString += " UpBat " + uploaderString
        }
        else
        {
            pumpStatusString += " UpBat N/A"
        }
        DispatchQueue.main.async {
            self.pumpDataDisplay.setText(pumpStatusString)
        }
        //loop
        
        if let lastLoop = properties.loop?.lastLoop {
            if let lastLoopTime = formatter.date(from: lastLoop.timestamp)?.timeIntervalSince1970  {
                DispatchQueue.main.async {
                    self.labelColor(label: self.loopStatusDisplay, timeSince: lastLoopTime)
                }
                if let failure = lastLoop.failureReason {
                    clearLoopDisplay()
                    self.errorMessage(message: failure)
                }
                else
                {
                    if let lastBasalRate = determineBasal(properties: properties) {
                        let lastBasalStatus = " Basal " + String(format:"%.1f", lastBasalRate)
                        DispatchQueue.main.async {
                            self.basalDisplay.setText(lastBasalStatus)
                            self.labelColor(label: self.basalDisplay, timeSince: lastLoopTime)
                        }
                    }
                    else
                    {
                        DispatchQueue.main.async {
                            self.basalDisplay.setText("")
                        }
                    }
                    var loopStatusText:String = " IOB "
                    if let lastIOB = properties.iob?.iob {
                        loopStatusText +=  String(format:"%.1f", lastIOB)
                    }
                    if let lastCOB = properties.cob?.cob {
                        loopStatusText += " COB " + String(format:"%.0f", lastCOB)
                    }
                    if let lastEBG = properties.loop?.lastPredicted?.values.last {
                        loopStatusText += " EBG " + bgOutputFormat(bg: Double(lastEBG), mmol: mmol)
                    }
                    DispatchQueue.main.async {
                        self.loopStatusDisplay.setText(loopStatusText)
                        self.labelColor(label: self.loopStatusDisplay, timeSince: lastLoopTime)
                    }
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
        if let lastOverride = properties.loop?.lastOverride {
            if let lastOverrideTime = formatter.date(from: lastOverride.timestamp)?.timeIntervalSince1970  {
                DispatchQueue.main.async {
                    self.labelColor(label: self.statusOverrideDisplay, timeSince: lastOverrideTime)
                }
            }
            if lastOverride.active {
                let lastCorrectionRange  = lastOverride.currentCorrectionRange
                overrideText = "BGTargets("
                let minValue = Double(lastCorrectionRange?.minValue ?? 0)
                let maxValue = Double(lastCorrectionRange?.maxValue ?? 0)
                overrideText += bgOutputFormat(bg: minValue, mmol: mmol) + ":" + bgOutputFormat(bg: maxValue, mmol: mmol) + ") M:"
                if let multiplier = lastOverride.multiplier {
                    overrideText += String(format:"%.1f", multiplier)
                }
                else
                {
                    overrideText += String(format:"%.1f", 1.0)
                }
                DispatchQueue.main.async {
                    self.statusOverrideDisplay.setHidden(false)
                    self.statusOverrideDisplay.setText(overrideText)
                }
            }
        }
        
        if consoleLogging == true {print("end updatePump")}
    }
    
    func updateBG (entries: [sgvData]) {
        if consoleLogging == true {print("in update BG")}
        
        if entries.count > 0 {
            let latestBG = entries[0].sgv
            let priorBG = entries[1].sgv
            let deltaBG = latestBG - priorBG as Int
            let lastBGTime = entries[0].date / 1000 //NS has different units
            let red = UIColor.red as UIColor
            let deltaTime = (TimeInterval(Date().timeIntervalSince1970)-lastBGTime) / 60
            var userUnit = " mg/dL"
            if mmol {
                userUnit = " mmol/L"
            }
            timeofLastBGUpdate = lastBGTime
            
            DispatchQueue.main.async{
                self.minAgoBGDisplay.setText(String(Int(deltaTime))+" min ago")
            }

            if (latestBG<40) {
                DispatchQueue.main.async {
                    self.primaryBGDisplay.setTextColor(red)
                    self.primaryBGDisplay.setText(bgErrorCode(latestBG))
                    self.bgDirectionDisplay.setText("")
                    self.deltaBGDisplay.setText("")
                }
            }
            else
            {
                DispatchQueue.main.async {
                    self.labelColor(label: self.minAgoBGDisplay, timeSince: lastBGTime)
                    self.primaryBGDisplay.setTextColor(self.bgcolor(latestBG))
                    self.primaryBGDisplay.setText(self.bgOutputFormat(bg: Double(latestBG), mmol: self.mmol))
                    if let directionBG = entries[0].direction {
                        self.bgDirectionDisplay.setText(bgDirectionGraphic(directionBG))
                        self.bgDirectionDisplay.setTextColor(self.bgcolor(latestBG))
                    }
                    else
                    {
                        self.bgDirectionDisplay.setText("")
                    }
                    let velocity=velocity_cf(entries) as Double
                    let prediction=velocity*30.0+Double(latestBG)
                    self.deltaBGDisplay.setTextColor(UIColor.white)
                    
                    
                    if deltaBG < 0 {
                        self.deltaBGDisplay.setText(self.bgOutputFormat(bg: Double(deltaBG), mmol: self.mmol) + userUnit)
                    }
                    else
                    {
                        self.deltaBGDisplay.setText("+" + self.bgOutputFormat(bg: Double(deltaBG), mmol: self.mmol) + userUnit)
                    }
                    self.velocityDisplay.setText(self.velocityOutputFormat(v: velocity, mmol: self.mmol))
                    self.predictionDisplay.setText(self.bgOutputFormat(bg: prediction, mmol: self.mmol))
                }

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





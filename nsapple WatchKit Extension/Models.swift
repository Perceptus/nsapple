//
//  Models.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 5/23/19.
//  Copyright © 2019 Perceptus.org. All rights reserved.
//

import Foundation
import WatchKit

struct Properties: Codable {
    let upbat: UpBattery?
    let iob: IOBLevel2?
    let cob: COBLevel2?
    let pump: PumpLevel2?
    let loop: PropertiesLoop?
    let basal: Basal?
}

struct PumpLevel2: Codable {
    let createdAt: String
    let pump: PumpLevel3
    enum CodingKeys: String, CodingKey {
        case pump
        case createdAt = "created_at"
    }
}

struct PumpLevel3: Codable {
    let bolusing: Bool?
    let reservoir: Double?
}

struct UpBattery: Codable {
    let display: String?
}

struct Basal: Codable {
    let current: Current
}

struct Current: Codable {
    let basal: Double
}

struct COBLevel2: Codable {
    let cob: Double
}

struct IOBLevel2: Codable {
    let iob: Double
}

struct PropertiesLoop: Codable {
    let lastLoop: LastLoopClass?
    let lastEnacted: Enacted?
    let lastPredicted: LastPredictedClass?
    let lastOverride: Override?
}

struct Enacted: Codable {
    let duration: Int
    let received: Bool
    let rate: Double
    let timestamp: String
}

struct LastLoopClass: Codable {
    let timestamp: String
    let predicted: LastPredictedClass?
    let failureReason: String?
}

struct LastPredictedClass: Codable {
    let values: [Int]
    let startDate: String
}

struct Override: Codable {
    let active: Bool
    let timestamp: String
    let moment: String
    let currentCorrectionRange: CurrentCorrectionRange?
    let multiplier: Double?
    let duration: Int?
}

struct CurrentCorrectionRange: Codable {
    let minValue: Int
    let maxValue: Int
}

struct PropertiesPump: Codable {
    let pump: PumpLevel2
    let createdAt: String
    enum CodingKeys: String, CodingKey {
        case pump
        case createdAt = "created_at"
    }
}

struct PumpBattery: Codable {
    let percent: Int
}

struct ScaledBGData {
    var xdata: Double
    var ydata: Double
    var dataColor: UIColor
}
struct sgvData: Codable {
    var sgv: Int
    var date: TimeInterval
    var direction: String?
}


func bgErrorCode(_ value:Int)->String {
    
    let errormap=["EC0 UNKNOWN","EC1 SENSOR NOT ACTIVE","EC2 MINIMAL DEVIATION","EC3 NO ANTENNA","EC4 UNKNOWN","EC5 SENSOR CALIBRATION","EC6 COUNT DEVIATION","EC7 UNKNOWN","EC8 UNKNWON","EC9 HOURGLASS DEVIATION","EC10 ??? POWER DEVIATION","EC11 UNKNOWN","EC12 BAD RF","EC13 MH"]
    
    return errormap[value]
}

func bgDirectionGraphic(_ value:String)->String {
    let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
    
    
    return graphics[value]!
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

func velocity_cf(_ bgs:[sgvData])->Double {
    //linear fit to 3 data points get slope (ie velocity)
    var v=0 as Double
    var n=0 as Int
    var i=0 as Int
    let ONE_MINUTE=60000.0 as Double
    var bgsgv = [Double](repeating: 0.0, count: 4)
    var date = [Double](repeating: 0.0, count: 4)
    
    
    i=0
    while i<4 {
        date[i] = bgs[i].date
        bgsgv[i] = Double(bgs[i].sgv)
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
        
    }
        //need to decide what to return if there isnt enough data
        
    else {v=0}
    
    return v
}

func infoBundle(_ key: String) -> String? {
    return (Bundle.main.infoDictionary?[key] as? String)?
        .replacingOccurrences(of: "\\", with: "")
}

func determineBasal (properties: Properties) -> Double? {
    //TODO fix lagging basal display in cgm-remote-monitor /api/v2/properties to remove determineBasal use properties.basal.display
    //if last enacted doesnt exist, we dont know the basal rate so return nil
    //if last enacted was a duration zero, then profile basal applies because loop canceled a temp basal
    //if enacted exists and has ended, then basal has reverted to profile basal
    //if enacted exists and hasnt ended, last enacted is the current rate
    
    guard let profileBasalRate = properties.basal?.current.basal, let lastEnacted = properties.loop?.lastEnacted
        else
    {
        return nil
    }
    
    if lastEnacted.duration == 0 {
        return profileBasalRate
    }
    
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate,
                               .withTime,
                               .withDashSeparatorInDate,
                               .withColonSeparatorInTime]
    
    guard let lastEnactedDate = formatter.date(from: lastEnacted.timestamp)?.timeIntervalSince1970
        else
    {
        return nil
    }
    
    let currentDate = Date()
    
    if (lastEnactedDate + Double(lastEnacted.duration)) > currentDate.timeIntervalSince1970 {
        return profileBasalRate
    }
        
    else
        
    {
        return lastEnacted.rate
    }
    
}


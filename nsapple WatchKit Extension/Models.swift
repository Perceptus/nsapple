//
//  Models.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 5/23/19.
//  Copyright © 2019 Perceptus.org. All rights reserved.
//

import Foundation
import WatchKit

struct ScaledBGData {
    var xdata: Double
    var ydata: Double
    var dataColor: UIColor
}
struct sgvData: Codable {
    var sgv: Int
    var date: TimeInterval
    var direction: String
}

func bgOutput(bg: Double, mmol: Bool) -> String {
    if !mmol {
        return String(format:"%.0f", bg)
    }
    else
    {
        return String(format:"%.1f", bg / 18.6)
    }
}

func velocityOutput(v: Double, mmol: Bool) -> String {
    if !mmol {
        return String(format:"%.1f", v)
    }
    else
    {
        return String(format:"%.1f", v / 18.6)
    }
}

func bgErrorCode(_ value:Int)->String {
    
    let errormap=["EC0 UNKNOWN","EC1 SENSOR NOT ACTIVE","EC2 MINIMAL DEVIATION","EC3 NO ANTENNA","EC4 UNKNOWN","EC5 SENSOR CALIBRATION","EC6 COUNT DEVIATION","EC7 UNKNOWN","EC8 UNKNWON","EC9 HOURGLASS DEVIATION","EC10 ??? POWER DEVIATION","EC11 UNKNOWN","EC12 BAD RF","EC13 MH"]
    
    return errormap[value]
}

func bgDirectionGraphic(_ value:String)->String {
    let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
    
    
    return graphics[value]!
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

func labelColor(label: WKInterfaceLabel, timeSince: TimeInterval) {
    let currentTime=TimeInterval(Date().timeIntervalSince1970)
    let deltaTime=(currentTime-timeSince)/60
    
    if deltaTime<7
    {label.setTextColor(UIColor.green)}
    else
        if deltaTime<14
        {label.setTextColor(UIColor.yellow)}
        else
        {label.setTextColor(UIColor.red)}
    
    
    
    return
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



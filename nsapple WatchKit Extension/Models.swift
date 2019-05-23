//
//  Models.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 5/23/19.
//  Copyright © 2019 Perceptus.org. All rights reserved.
//

import Foundation
import WatchKit


struct sgvData: Codable {
    var sgv: String
    var datetime: TimeInterval
    var direction: String
}
struct dataPebble: Codable{
    var bgs: [sgvData]
    
}
struct entriesData: Codable {
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

func errorcode(_ value:Int)->String {
    
    let errormap=["EC0 UNKNOWN","EC1 SENSOR NOT ACTIVE","EC2 MINIMAL DEVIATION","EC3 NO ANTENNA","EC4 UNKNOWN","EC5 SENSOR CALIBRATION","EC6 COUNT DEVIATION","EC7 UNKNOWN","EC8 UNKNWON","EC9 HOURGLASS DEVIATION","EC10 ??? POWER DEVIATION","EC11 UNKNOWN","EC12 BAD RF","EC13 MH"]
    
    return errormap[value]
}

func dirgraphics(_ value:String)->String {
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
    let ct=TimeInterval(Date().timeIntervalSince1970)
    let deltat=(ct-timeSince)/60
    
    if deltat<6
    {label.setTextColor(UIColor.green)}
    else
        if deltat<14
        {label.setTextColor(UIColor.yellow)}
        else
        {label.setTextColor(UIColor.red)}
    
    
    
    return
}


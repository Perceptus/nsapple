//
//  nsappleUI.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 5/28/19.
//  Copyright © 2019 Perceptus.org. All rights reserved.
//

import Foundation
import WatchKit

extension InterfaceController {
    func bgOutputFormat(bg: Double, mmol: Bool) -> String {
        if !mmol {
            return String(format:"%.0f", bg)
        }
        else
        {
            return String(format:"%.1f", bg / 18.0)
        }
    }
    
    func velocityOutputFormat(v: Double, mmol: Bool) -> String {
        if !mmol {
            return String(format:"%.1f", v)
        }
        else
        {
            return String(format:"%.1f", v / 18.0)
        }
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
        DispatchQueue.main.async {
            if deltaTime<7 {
                label.setTextColor(UIColor.green)
            }
            else
                if deltaTime<14 {
                    label.setTextColor(UIColor.yellow)
                }
                else
                {
                    label.setTextColor(UIColor.red)
            }
        }
        
        return
    }

    
    func colorBGStatus (color: UIColor) {
        self.primaryBGDisplay.setTextColor(color)
        self.bgDirectionDisplay.setTextColor(color)
        self.deltaBGDisplay.setTextColor(color)
    }
    
    func colorLoopStatus (color: UIColor) {
        self.pumpDataDisplay.setTextColor(color)
        self.loopStatusDisplay.setTextColor(color)
        self.statusOverrideDisplay.setTextColor(color)
        self.basalDisplay.setTextColor(color)
    }
    
    
    func errorMessage(message: String) {
        DispatchQueue.main.async {
            self.errorDisplay.setHidden(false)
            self.errorDisplay.setText(message)
        }
    }
    
    func clearEntireDisplay() {
        clearBGDisplay()
        clearLoopDisplay()
        clearPumpDisplay()
    }
    
    func clearPumpLoopDisplay() {
        clearPumpDisplay()
        clearLoopDisplay()
    }
    
    func clearBGDisplay() {
        DispatchQueue.main.async {
            self.primaryBGDisplay.setText("")
            self.bgDirectionDisplay.setText("")
            self.velocityDisplay.setText("")
            self.predictionDisplay.setText("")
            self.deltaBGDisplay.setText("")
        }
    }
    
    func clearLoopDisplay() {
        DispatchQueue.main.async {
            self.basalDisplay.setText("")
            self.loopStatusDisplay.setText("")
        }
    }
    
    func clearPumpDisplay() {
        DispatchQueue.main.async {
            self.pumpDataDisplay.setText("")
        }
    }
    
}

//
//  ScatterGraph.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 5/28/19.
//  Copyright © 2019 Perceptus.org. All rights reserved.
//

import Foundation
import WatchKit

extension InterfaceController {
    
    func createGraph(hours:Int, bghist:[sgvData]) {
        // create graph
        // Create a graphics context
        let height : CGFloat = 101
        let width = self.contentFrame.size.width
        let size = CGSize(width:width, height:height)
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(1.0)
        
        var miny : Double
        var maxy: Double
        var scaledBGData = [ScaledBGData]()
        
        //ydata is scaled to 100
        //xdata is scaled to width
        (scaledBGData, miny, maxy) = self.bgScaling(hours, bgHistory: bghist, graphWidthPixels: width)
        
        //create data points
        var i: Int = 0
        let leftbuffer : Double = 20
        let widthD : Double = Double(width)
        while i < scaledBGData.count {
            //reverse y data, rescale x for leftbuffer
            scaledBGData[i].ydata = 100.0 - scaledBGData[i].ydata
            scaledBGData[i].xdata = (widthD - leftbuffer) / widthD * scaledBGData[i].xdata + leftbuffer
            context!.setStrokeColor(scaledBGData[i].dataColor.cgColor)
            let rect = CGRect(x: CGFloat(scaledBGData[i].xdata), y: CGFloat(scaledBGData[i].ydata), width: width/2/100, height: 50/100)
            context?.addEllipse(in: rect)
            context?.drawPath(using: .fillStroke)
            i=i+1
        }
        
        //draw horizontal lines at 80 and 180 for xcontext
        //TODO make user configurable
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
        self.drawGraphLabels(context: context, text: bgOutputFormat(bg: round(miny/rounder) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: height - ybuffer)
        self.drawGraphLabels(context: context, text: bgOutputFormat(bg: round(maxy/rounder) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: ybuffer + 1 )
        self.drawGraphLabels(context: context, text: bgOutputFormat(bg: round((maxy + miny) / (2.0 * rounder)) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: height/2)
    
        let cgimage = context!.makeImage();
        let uiimage = UIImage(cgImage: cgimage!)
        
        UIGraphicsEndImageContext()
        DispatchQueue.main.async() {
            self.bgGraphDisplay.setImage(uiimage)
        }
    }
    
    
    
    func drawGraphLabels( context : CGContext?, text : NSString, centreX : CGFloat, centreY : CGFloat )
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
    
    func bgScaling(_ graphHours:Int,bgHistory:[sgvData], graphWidthPixels: CGFloat)-> ([ScaledBGData], Double, Double) {
        var scaledBGData = [ScaledBGData]()
        let currentTime=NSInteger(Date().timeIntervalSince1970)
        var maxY=0
        var maxX=0
        var minY=1000
        var minX=1000000
        let bgHighLine=180
        let bgLowLine=80
        var bgrelativeTimes = [Int]()
        let graphMinutes = graphHours*60
        var bgPointIncrement:Int=1
        var dataColor: UIColor
        if (graphHours==3||graphHours==1) {
            bgPointIncrement=1
            
        } else
            if graphHours==6 {
                bgPointIncrement=2
            } else
                if graphHours==12 {
                    bgPointIncrement=3
                    
                } else {
                    bgPointIncrement=5
                    
        }
        
        //find max and min time, min and max bg
        var i=0 as Int;
        while (i<bgHistory.count) {
            let bgDate: Double = (bgHistory[i].date)/1000
            bgrelativeTimes.append(Int((Double(graphMinutes)-(Double(currentTime)-bgDate)/(60.0))))
            if (bgrelativeTimes[i]>=0) {
                if (bgrelativeTimes[i] > maxX) {maxX = bgrelativeTimes[i]}
                if (bgrelativeTimes[i] < minX) {minX = bgrelativeTimes[i]}
                if (bgHistory[i].sgv > maxY) {maxY = bgHistory[i].sgv}
                if (bgHistory[i].sgv < minY) {minY = bgHistory[i].sgv}
            }
            i += 1}
        if maxY < bgHighLine {maxY = bgHighLine}
        if minY > bgLowLine {minY = bgLowLine}
        
        //create strings of data points xg (time) and yg (bg) and string of colors pc
        i=0;
        while i<bgHistory.count  {
            //only work on values that are not beyond time window
            if (bgrelativeTimes[i]>=0) {
                //scale time values
                let xdata = (Double(bgrelativeTimes[i])*Double(graphWidthPixels)/Double(graphMinutes))
                let sgv:Int = bgHistory[i].sgv
                if sgv<60 {dataColor = (UIColor.red)} else
                    if sgv<80 {dataColor = (UIColor.yellow)} else
                        if sgv<180 {dataColor = (UIColor.green)} else
                            if sgv<260 {dataColor = (UIColor.yellow)} else
                            {dataColor = UIColor.red}
                //scale bg data to 100 is the max
                let ydata = (Double((sgv-minY)*100/(maxY-minY)))
                scaledBGData.append(ScaledBGData(
                    xdata: xdata, ydata: ydata, dataColor: dataColor))
            }
            i += bgPointIncrement}
        
        return (scaledBGData, Double(minY), Double(maxY))
    }
    
    
}

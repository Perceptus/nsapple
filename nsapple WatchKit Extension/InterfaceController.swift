//
//  InterfaceController.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 7/9/15.
//  Copyright (c) 2015 Perceptus.org. All rights reserved.
//

import WatchKit
import Foundation

//

public extension WKInterfaceImage {
    
    public func setImageWithUrl(url:String) -> WKInterfaceImage? {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let url = NSURL(string: url) {
                if let data = NSData(contentsOfURL: url) { // may return nil, too
                    // do something with data
                    var placeholder = UIImage(data: data)!
                    dispatch_async(dispatch_get_main_queue()) {
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
    @IBOutlet weak var currentbg: WKInterfaceLabel!
    @IBOutlet weak var bgdirection: WKInterfaceLabel!
    @IBOutlet weak var deltabg: WKInterfaceLabel!
    @IBOutlet weak var battery: WKInterfaceLabel!
    @IBOutlet weak var minago: WKInterfaceLabel!
    @IBOutlet weak var rawbg: WKInterfaceLabel!
    @IBOutlet weak var graphhours: WKInterfaceLabel!
    @IBOutlet weak var hourslider: WKInterfaceSlider!
    @IBOutlet weak var chartraw: WKInterfaceSwitch!
    
    var graphlength:Int=3
    var bghistread=true as Bool
    var bghist=[] as NSArray
    var cals=[] as NSArray
    var craw=true as Bool
    //
    
    @IBAction func hourslidervalue(value: Float) {
        let slidermap:[Int:Int]=[1:24,2:12,3:6,4:3,5:1]
        let slidervalue=Int(round(value*1000)/1000)
        graphlength=slidermap[slidervalue]!
        willActivate()
        
    }

    
    @IBAction func chartraw(value: Bool) {
        craw=value
        willActivate()
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updatecore()
        let google=bggraph(graphlength)!.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        if (bghistread==true)&&(google != "NoData") {
            graphhours.setTextColor(UIColor.whiteColor())
            graphhours.setText("Last "+String(graphlength)+" Hours")
            bgimage.setHidden(false)
            chartraw.setHidden(false)
            bgimage.setImageWithUrl(google)
        }
        else {
            //need to create no data image
            graphhours.setTextColor(UIColor.redColor())
            graphhours.setText("No Chart Data")
            bgimage.setHidden(true)
            chartraw.setHidden(true)
        }
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    

    
    func updatecore() {
 
     //get pebble data
      
        //add retrieve urlfrom user storage
        var defaults: NSUserDefaults = NSUserDefaults(suiteName: "group.perceptus.nsapple")!
        let url=defaults.objectForKey("pebbleurl") as! String
        let urlPath: String = "https://"+url+"/pebble?count=576"
        println("in watchkit")
        println(urlPath)
        var responseDict:AnyObject=""
        if let url = NSURL(string: urlPath) {
            if let data = NSData(contentsOfURL: url, options: .allZeros, error: nil) {
                
               responseDict  = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)!
            }
        }
        
 
        
       
  //successfully received pebble end point data
        if let bgs=responseDict["bgs"] as? NSArray {
        bghistread=true
        let cbg=bgs[0]["sgv"] as! String
        let direction=bgs[0]["direction"] as! String
        let unfilt=bgs[0]["unfiltered"] as! Double
        let filt=bgs[0]["filtered"] as! Double
        let bat=bgs[0]["battery"] as! String
        let dbg=bgs[0]["bgdelta"] as! Int
        let bgtime=bgs[0]["datetime"] as! NSTimeInterval
        //save as global variables
         cals=responseDict["cals"] as! NSArray
            bghist=bgs
        //calculate text colors for sgv,direction
        var lmh=2
        let sgvi=cbg.toInt()
        let sgv=Double(sgvi!)
            
            if (sgv<65) {
                currentbg.setTextColor(UIColor.redColor())
                bgdirection.setTextColor(UIColor.redColor())}
            else
                if(sgv<80) {
                    currentbg.setTextColor(UIColor.yellowColor())
                    bgdirection.setTextColor(UIColor.yellowColor())
                }
                else
                    if (sgv<180) {
                        currentbg.setTextColor(UIColor.greenColor())
                        bgdirection.setTextColor(UIColor.greenColor())
                    }
                    else
                        if (sgv<250) {
                            currentbg.setTextColor(UIColor.yellowColor())
                            bgdirection.setTextColor(UIColor.yellowColor())}
                        else
                        {
                            currentbg.setTextColor(UIColor.redColor())
                            bgdirection.setTextColor(UIColor.redColor())}

//check to see if cal data is available - if so we can calc raw
        if cals.count>0 {
        
         let slope=cals[0]["slope"] as! Double
           let scale=cals[0]["scale"] as! Double
            let intercept=cals[0]["intercept"] as! Double
            
            var rawv=calcraw(sgv,filt: filt,unfilt: unfilt,slope: slope,intercept: intercept,scale: scale)
        
        // calculate color for raw
        lmh=2
        if (rawv<65) { rawbg.setTextColor(UIColor.redColor())}
        else
            if(rawv<80) {rawbg.setTextColor(UIColor.yellowColor())}
            else
                if (rawv<180) {rawbg.setTextColor(UIColor.greenColor())}
                else
                    if (rawv<250) {rawbg.setTextColor(UIColor.yellowColor())}
                    else
                    {rawbg.setTextColor(UIColor.redColor())}
                rawbg.setText(String( rawv))
        }
        else
        {rawbg.setTextColor(UIColor.redColor())
            rawbg.setText("N/A")
        }
        
        //color for battery
        if bat.toInt()<20 {battery.setTextColor(UIColor.redColor())} else
            if bat.toInt()<40 {battery.setTextColor(UIColor.yellowColor())} else
            {battery.setTextColor(UIColor.greenColor())}
        
        // display pebble data to watch
            
            if (sgvi<40) {
               // currentbg.setAttributedText(size)
                currentbg.setTextColor(UIColor.redColor())
                currentbg.setText(errorcode(sgvi!))
                bgdirection.setText("")
                deltabg.setText("")
            }
            
            else
            {
        currentbg.setText(cbg)
            deltabg.setTextColor(UIColor.whiteColor())
        if (dbg<0) {deltabg.setText(String(dbg)+" mg/dl")} else {deltabg.setText("+"+String(dbg)+" mg/dl")}
        bgdirection.setText(dirgraphics(direction))
            }
        battery.setText(bat+"%")
        let ct=NSTimeInterval(NSDate().timeIntervalSince1970)
        let deltat=(ct-bgtime/1000)/60
        if deltat<10 {minago.setTextColor(UIColor.greenColor())} else
            if deltat<20 {minago.setTextColor(UIColor.yellowColor())} else {minago.setTextColor(UIColor.redColor())}
        minago.setText(String(Int(deltat))+" min ago")
        } //end bgs !=nil
            
        //did not get pebble endpoint data
        else
        {
            bghistread=false
            noconnection()
        }

    }
    
    func noconnection() {
        deltabg.setTextColor(UIColor.redColor())
        deltabg.setText("No Connection")
        
    }
    
    func errorcode(value:Int)->String {
        
       let errormap=["EC0 UNKNOWN","EC1 SENSOR NOT ACTIVE","EC2 MINIMAL DEVIATION","EC3 NO ANTENNA","EC4 UNKNOWN","EC5 SENSOR CALIBRATION","EC6 COUNT DEVIATION","EC7 UNKNOWN","EC8 UNKNWON","EC9 HOURGLASS DEVIATION","EC10 ??? POWER DEVIATION","EC11 UNKNOWN","EC12 BAD RF","EC13 MH"]

        return errormap[value]
    }
    
    func dirgraphics(value:String)->String {
         let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
        
        
        return graphics[value]!
    }
    
    func calcraw(sgv:Double,filt:Double,unfilt:Double, slope:Double, intercept:Double, scale:Double) -> Int
    
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
    
    func bggraph(hours:Int)-> String? {
        
        
        //get bghistory
        //grabbing double the data in case of gap sync issues
          var google="" as String
        var ct2=NSInteger(NSDate().timeIntervalSince1970)
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
        var bgtimes = [Int](count: numbg+1, repeatedValue: 0)
        var rawv=[Int](count:numbg+1, repeatedValue: 0)
        let minutes=hours*60
        var inc:Int=1
        if (hours==3||hours==1) {inc=1} else
            if hours==6 {inc=2} else
            if hours==12 {inc=3} else
                {inc=5}
        if cals.count>0 && craw==true {
            slope=cals[0]["slope"] as! Double
            scale=cals[0]["scale"] as! Double
            intercept=cals[0]["intercept"] as! Double
        }
        
  
        //find max time, min and max bg
        for var i=0; i<bghist.count; i=i+1 {
            bgtimes[i]=minutes-(((ct2*1000-(bghist[i]["datetime"] as! Int))/1000)/(60) as Int)
            println(bgtimes[i])
            if (bgtimes[i]>=0) {
                gpoints++
            if (bgtimes[i]>maxx) { maxx=bgtimes[i]}
            if ((bghist[i]["sgv"] as! String).toInt()>maxy) {maxy=(bghist[i]["sgv"] as! String).toInt()!}
            if ((bghist[i]["sgv"] as! String).toInt()<miny) {miny=(bghist[i]["sgv"] as! String).toInt()!}
                //calculate raw values, include in min max calc
                if cals.count>0 && craw==true {
                    let sgvd=Double((bghist[i]["sgv"] as! String).toInt()!)
                    let unfilt=bghist[i]["unfiltered"] as! Double
                    let filt=bghist[i]["filtered"] as! Double
                    rawv[i]=calcraw(sgvd,filt: filt,unfilt: unfilt,slope: slope,intercept: intercept,scale: scale)
                    if rawv[i]>maxy {maxy=rawv[i]}
                    if rawv[i]<miny {miny=rawv[i]}
                    
                }
            }
        }
        if gpoints < 1 {return "NoData"}
        if maxy<bgth {maxy=bgth}
        if miny>bgtl {miny=bgtl}

        //create strings of data points xg (time) and yg (bg) and string of colors pc
        for var i=0; i<bghist.count; i=i+inc {
            if (bgtimes[i]>=0) {
                //scale time values
                xg=xg+String(bgtimes[i]*100/minutes)+","
                var sgv:Int=((bghist[i]["sgv"] as! String).toInt()!)
                if sgv<60 {pc=pc+"FF0000|"} else
                    if sgv<80 {pc=pc+"FFFF00|"} else
                        if sgv<180 {pc=pc+"00FF00|"} else
                            if sgv<260 {pc=pc+"FFFF00|"} else
                            {pc=pc+"FF0000|"}
                //scale bg data to 100 is the max
                sgv=(sgv-miny)*100/(maxy-miny)
                yg=yg+String(sgv)+","
                //add raw points on the fly if cal available
                if cals.count>0 && craw==true {
                    let rawscaled=(rawv[i]-miny)*100/(maxy-miny)
                    xg=xg+String(bgtimes[i]*100/minutes)+".05,"
                    yg=yg+String(rawscaled)+","
                    pc=pc+"FFFFFF|"
                }
            }
        }
        
        xg=(dropLast(xg))
        yg=(dropLast(yg))
        pc=(dropLast(pc))
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



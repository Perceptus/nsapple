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
    @IBOutlet weak var primarybg: WKInterfaceLabel!
    @IBOutlet weak var bgdirection: WKInterfaceLabel!
    @IBOutlet weak var deltabg: WKInterfaceLabel!
    @IBOutlet weak var battery: WKInterfaceLabel!
    @IBOutlet weak var minago: WKInterfaceLabel!
    @IBOutlet weak var secondarybg: WKInterfaceLabel!
    @IBOutlet weak var graphhours: WKInterfaceLabel!
    @IBOutlet weak var hourslider: WKInterfaceSlider!
    @IBOutlet weak var chartraw: WKInterfaceSwitch!
   //@IBOutlet weak var primarybg: WKInterfaceLabel!
   //@IBOutlet weak var secondarybg: WKInterfaceLabel!

    @IBOutlet weak var plabel: WKInterfaceLabel!
    @IBOutlet weak var vlabel: WKInterfaceLabel!
    @IBOutlet weak var secondarybgname: WKInterfaceLabel!
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
  //    var dexprimary=false as Bool
        //add retrieve urlfrom user storage
        var defaults: NSUserDefaults = NSUserDefaults(suiteName: "group.perceptus.nsapple")!
        let url=defaults.objectForKey("pebbleurl") as! String
        var dexprimary=true as Bool
        if defaults.objectForKey("primarydisplay") as! String == "dex" {dexprimary=true} else {dexprimary=false}
      
       
        
        let urlPath: String = "https://"+url+"/pebble?count=576"
        println("in watchkit")
        println(urlPath)
        var responseDict:AnyObject=""
        if let url = NSURL(string: urlPath) {
            if let data = NSData(contentsOfURL: url, options: .allZeros, error: nil) {
                println(data)
                
                //from Nightscouter - fix for apple json issues
                var dataConvertedToString = NSString(data: data, encoding: NSUTF8StringEncoding)
                // Apple's JSON Serializer has a problem with + notation for large numbers. I've observed this happening in intercepts.
                dataConvertedToString = dataConvertedToString?.stringByReplacingOccurrencesOfString("+", withString: "")
                
                // Converting string back into data so it can be processed into JSON.
                if let newData: NSData = dataConvertedToString?.dataUsingEncoding(NSUTF8StringEncoding) {
                    var jsonErrorOptional: NSError?
                    responseDict = NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)!
                    
                    // if there was an error parsing the JSON send it back
             
                
                
                
                
                
                
                }
                
            
            
                
                
             //  responseDict  = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)!
            }
        }
        
 
        
       
  //successfully received pebble end point data
        if let bgs=responseDict["bgs"] as? NSArray {
        bghistread=true
        var rawavailable=false as Bool
        var slope=0.0 as Double
        var intercept=0.0 as Double
        var scale=0.0 as Double
        let cbg=bgs[0]["sgv"] as! String
        let direction=bgs[0]["direction"] as! String
        let unfilt=bgs[0]["unfiltered"] as! Double
        let filt=bgs[0]["filtered"] as! Double
        let bat=bgs[0]["battery"] as! String
        let dbg=bgs[0]["bgdelta"] as! Int
        let bgtime=bgs[0]["datetime"] as! NSTimeInterval
        var red=UIColor.redColor() as UIColor
        var green=UIColor.greenColor() as UIColor
        var yellow=UIColor.yellowColor() as UIColor
        var rawcolor="green" as String
        //save as global variables
         cals=responseDict["cals"] as! NSArray
            bghist=bgs
        //calculate text colors for sgv,direction
        var lmh=2
        var rawv=0 as Int
        let sgvi=cbg.toInt()
        let sgv=Double(sgvi!)
       // let sgvcolor=bgcolor(sgvi!) as String
            

//check to see if cal data is available - if so we can calc raw

        
            if (cals.count>0) {
                rawavailable=true
                slope=cals[0]["slope"] as! Double
           scale=cals[0]["scale"] as! Double
             intercept=cals[0]["intercept"] as! Double
            
            rawv=calcraw(sgv,filt: filt,unfilt: unfilt,slope: slope,intercept: intercept,scale: scale)
            
                }
//        else
//        {rawbg.setTextColor(rawcolor)
//            rawbg.setText("N/A")
//        }
        // display pebble data to watch
            
        //color for battery
        if bat.toInt()<20 {battery.setTextColor(UIColor.redColor())} else
            if bat.toInt()<40 {battery.setTextColor(UIColor.yellowColor())} else
            {battery.setTextColor(UIColor.greenColor())}
         battery.setText(bat+"%")
        //set time
            let ct=NSTimeInterval(NSDate().timeIntervalSince1970)
            let deltat=(ct-bgtime/1000)/60
            if deltat<10 {minago.setTextColor(UIColor.greenColor())} else
                if deltat<20 {minago.setTextColor(UIColor.yellowColor())} else {minago.setTextColor(UIColor.redColor())}
            minago.setText(String(Int(deltat))+" min ago")
            secondarybgname.setText("Raw")
            if (sgvi<40) {
//display error code as primary and raw as secondary
               // currentbg.setAttributedText(size)
                primarybg.setTextColor(red)
                primarybg.setText(errorcode(sgvi!))
                bgdirection.setText("")
                deltabg.setText("")
                if (rawavailable==true) {
                    secondarybg.setText(String(rawv))
                    secondarybg.setTextColor(bgcolor(rawv))
                }
                else
                {
                    secondarybg.setText("N/A")
                    secondarybg.setTextColor(red)
                }
            }
 //if raw doesnt exist or dex is primary
            else
                if (dexprimary==true || rawavailable==false)
            {
        //display dex as primary
        primarybg.setText(cbg)
        primarybg.setTextColor(bgcolor(cbg.toInt()!))
        deltabg.setTextColor(UIColor.whiteColor())
        if (dbg<0) {deltabg.setText(String(dbg)+" mg/dl")} else {deltabg.setText("+"+String(dbg)+" mg/dl")}
        bgdirection.setText(dirgraphics(direction))
                bgdirection.setTextColor(bgcolor(cbg.toInt()!))
                if (rawavailable==true) {
                    secondarybg.setText(String(rawv))
                    secondarybg.setTextColor(bgcolor(rawv))
                }
                else
                {
                    secondarybg.setText("N/A")
                    secondarybg.setTextColor(red)
                }
            }
            else
    //raw must be primary and available
                    
                {
                    primarybg.setText(String(rawv))
                    primarybg.setTextColor(bgcolor(rawv))
                //calculate raw delta
                    let cbgo=bgs[1]["sgv"] as! String
                    let unfilto=bgs[1]["unfiltered"] as! Double
                    let filto=bgs[1]["filtered"] as! Double
                    //let t2=test(filto,b:unfilto)
                    let rawvo=calcraw(Double(cbgo.toInt()!),filt:filto,unfilt:unfilto,slope: slope,intercept: intercept,scale: scale) as Int
                    let dbg=(rawv-rawvo) as Int
                    deltabg.setTextColor(UIColor.whiteColor())
                    if (dbg<0) {deltabg.setText(String(dbg)+" mg/dl")} else {deltabg.setText("+"+String(dbg)+" mg/dl")}
                    //calculate raw direction
                   
                    //
                    
                    //
                    
                    let bgtimeo=bgs[1]["datetime"] as! NSTimeInterval
                    let dt=round((bgtime-bgtimeo)/60000.0) as Double
                    println(dt)
                    
                    
                    
                    
                  //  let velocity=Double(dbg)/dt
                   
                    
                    let velocity=velocity_cf(bgs,filto: filto,unfilto: unfilto,slope: slope,intercept: intercept,scale: scale) as Double
                    let prediction=velocity*20.0
                    println("vel")
                    println(velocity)
                    vlabel.setText(String(format:"%.1f", velocity))
                    plabel.setText(String(format:"%.1f", prediction))
                    
                    
                    
                    bgdirection.setTextColor(bgcolor(rawv))
                    bgdirection.setText(dirgraphics(rawdir(velocity,dt: dt)))
                    


                    //display raw direction and delta
                    secondarybg.setText(cbg)
                    secondarybg.setTextColor(bgcolor(sgvi!))
                    secondarybgname.setText("Dex")
                    
                    
            }

         } //end bgs !=nil
            
        //did not get pebble endpoint data
        else
        {
            bghistread=false
            noconnection()
        }

    }
    
    func velocity_cf(bgs:NSArray,filto:Double,unfilto:Double,slope:Double,intercept:Double,scale:Double)->Double {
    //linear fit to 3 data points get slope (ie velocity)
    var v=0 as Double
    var n=0 as Int
    var i=0 as Int
    let ONE_MINUTE=60000.0 as Double
    var bgsgv = [Double](count: 4, repeatedValue: 0.0)
        var date = [Double](count: 4, repeatedValue: 0.0)
        var bgsraw=[Double](count: 4, repeatedValue: 0.0)
        
      
        
        for (i=0;i<4;i++) {
         date[i]=(bgs[i]["datetime"] as? Double)!
         bgsgv[i]=(bgs[i]["sgv"] as? NSString)!.doubleValue
         
          bgsraw[i]=Double(calcraw(bgsgv[i],filt:filto,unfilt:unfilto,slope: slope,intercept: intercept,scale: scale) as Int)
            bgsgv[i]=bgsraw[i]
          
        }
        
        
    if ((date[0]-date[3])/ONE_MINUTE < 15.1) {n=4}
        
        else
        
    if ((date[0]-date[2])/ONE_MINUTE < 10.1) {n=3}
    else
        
    if ((date[0]-date[1])/ONE_MINUTE<10.1) {n=2}
    else {n=0}
        
    var xm=0.0 as Double
    var ym=0.0 as Double
    var j=0 as Int
    if (n>0) {
 
    for (j=0;j<n;j++) {
				
				xm = xm + date[j]/ONE_MINUTE
				ym = ym + bgsgv[j]
    }
    xm=xm/Double(n)
    ym=ym/Double(n)
    var c1=0.0 as Double
    var c2=0.0 as Double
    var t=0.0 as Double
        
    for (j=0;j<n;j++) {
				
				t=date[j]/ONE_MINUTE
				c1=c1+(t-xm)*(bgsgv[j]-ym)
				c2=c2+(t-xm)*(t-xm)

    }
    v=c1/c2
        println(v)
    //	console.log(v)
    }
    //need to decide what to return if there isnt enough data
    
    else {v=0}
    
    return v
    }
    
    
    
    
    
    
    
    
    func noconnection() {
        deltabg.setTextColor(UIColor.redColor())
        deltabg.setText("No Data")
        
    }
    
    func bgcolor(value:Int)->UIColor
    {
        
        var red=UIColor.redColor() as UIColor
        var green=UIColor.greenColor() as UIColor
        var yellow=UIColor.yellowColor() as UIColor
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
    
    func errorcode(value:Int)->String {
        
       let errormap=["EC0 UNKNOWN","EC1 SENSOR NOT ACTIVE","EC2 MINIMAL DEVIATION","EC3 NO ANTENNA","EC4 UNKNOWN","EC5 SENSOR CALIBRATION","EC6 COUNT DEVIATION","EC7 UNKNOWN","EC8 UNKNWON","EC9 HOURGLASS DEVIATION","EC10 ??? POWER DEVIATION","EC11 UNKNOWN","EC12 BAD RF","EC13 MH"]

        return errormap[value]
    }
    
    func dirgraphics(value:String)->String {
         let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
        
        
        return graphics[value]!
    }
    
    func rawdir(velocity:Double,dt:Double) ->String {
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
    
    func test(a:Double,b:Double) ->Int {
        return Int(a+b)
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



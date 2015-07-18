//
//  InterfaceController.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 7/9/15.
//  Copyright (c) 2015 Perceptus.org. All rights reserved.
//

import WatchKit
import Foundation



public extension WKInterfaceImage {
    
    public func setImageWithUrl(url:String) -> WKInterfaceImage? {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            println("top set image")
            if let url = NSURL(string: url) {
                if let data = NSData(contentsOfURL: url) { // may return nil, too
                    // do something with data
                    var placeholder = UIImage(data: data)!
                    dispatch_async(dispatch_get_main_queue()) {
                        println("in setimage")
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
    
    var graphlength:Int=3
    
    @IBAction func hourslidervalue(value: Float) {
        let slidermap:[Int:Int]=[1:24,2:12,3:6,4:3]
        let slidervalue=Int(round(value*1000)/1000)
        graphlength=slidermap[slidervalue]!
        graphhours.setText("Last "+String(graphlength)+" Hours")
        bgimage.setImageWithUrl(bggraph(graphlength)!.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
        
    }

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updatecore()
       
         graphhours.setText("Last "+String(graphlength)+" Hours")
      
     //   bgimage.setImageWithUrl(bggraph(graphlength)!.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    

    
    func updatecore() {
 
     //get pebble data
      
            //add retrieve from user storage
 
//        var url: NSURL = NSURL(string: urlPath)!
//        var request1: NSURLRequest = NSURLRequest(URL: url)
//        println(request1)
//        var response: AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
//        var dataVal: NSData =  NSURLConnection.sendSynchronousRequest(request1, returningResponse: response, error:nil)!
//        var err: NSError?
//      let responseDict : AnyObject! = NSJSONSerialization.JSONObjectWithData(dataVal, options: nil, error: nil)
       // var responseDict:NSArray
        let urlPath: String = "https://t1daarsaws.azurewebsites.net/pebble"
        var responseDict:AnyObject=""
        if let url = NSURL(string: urlPath) {
            if let data = NSData(contentsOfURL: url, options: .allZeros, error: nil) {
                
               responseDict  = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)!
                
            
            }
        }
        
        println("past nsdata")
        
       
  //successfully received pebble end point data
        if let bgs=responseDict["bgs"] as? NSArray {
          //  if (responseDict["bgs"] !=nil) {
      
        let cbg=bgs[0]["sgv"] as! String
        let direction=bgs[0]["direction"] as! String
        let unfilt=bgs[0]["unfiltered"] as! Double
        let filt=bgs[0]["filtered"] as! Double
        let bat=bgs[0]["battery"] as! String
        let dbg=bgs[0]["bgdelta"] as! Int
        let bgtime=bgs[0]["datetime"] as! NSTimeInterval
        let cals=responseDict["cals"] as! NSArray
        
        
        //calculate text colors for sgv,direction
        var lmh=2
        let sgv=cbg.toInt()
        println(sgv)
        if (sgv<65) {lmh=3}
        else
            if(sgv<80) {lmh=2}
            else
                if (sgv<180) {lmh=1}
                else
                    if (sgv<250) {lmh=2}
                    else
                    {lmh=3}
        if (lmh==1) {
            currentbg.setTextColor(UIColor.greenColor())
            bgdirection.setTextColor(UIColor.greenColor())
        }
        else
            if(lmh==2) {
                currentbg.setTextColor(UIColor.yellowColor())
                bgdirection.setTextColor(UIColor.yellowColor())
            }
            else
            {
                currentbg.setTextColor(UIColor.redColor())
                bgdirection.setTextColor(UIColor.redColor())
        }
//check to see if cal data is available - if so we can calc raw
        if cals.count>0 {
        
         let slope=cals[0]["slope"] as! Double
           let scale=cals[0]["scale"] as! Double
            let intercept=cals[0]["intercept"] as! Double
        
        
              //calculate raw bg
        
        var rawv=0.0 as Double
        if(sgv<40) {
            rawv = scale*(filt-intercept)/slope
        }
        else
        {
            rawv = (unfilt-intercept)/(filt-intercept)*Double(sgv!)
            
        }

        // calculate color for raw
        lmh=2
        if (rawv<65) {lmh=3}
        else
            if(rawv<80) {lmh=2}
            else
                if (rawv<180) {lmh=1}
                else
                    if (rawv<250) {lmh=2}
                    else
                    {lmh=3}
        if (lmh==1) {
            rawbg.setTextColor(UIColor.greenColor())
        }
        else
            if(lmh==2) {
                rawbg.setTextColor(UIColor.yellowColor())
            }
            else
            {
                rawbg.setTextColor(UIColor.redColor())
        }
                rawbg.setText(String(format:"%.0f", rawv))
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
        let dirgraphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
        currentbg.setText(cbg)
        if (dbg<0) {deltabg.setText(String(dbg)+" mg/dl")} else {deltabg.setText("+"+String(dbg)+" mg/dl")}
        bgdirection.setText(dirgraphics[direction])

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
            nopebble()
        }

    }
    
    func nopebble() {
        deltabg.setTextColor(UIColor.redColor())
        deltabg.setText("No Connection")
        
    }
    
    func bggraph(hours:Int)-> String? {
        
        
        //get bghistory
        //grabbing double the data in case of gap sync issues
        let numbg=2*hours*60/5+1
        let urlPath2: String = "https://t1daarsaws.azurewebsites.net/api/v1/entries.json?count="+String(numbg)
        println(numbg)
        var url2: NSURL = NSURL(string: urlPath2)!
        var request2: NSURLRequest = NSURLRequest(URL: url2)
        var response2: AutoreleasingUnsafeMutablePointer<NSURLResponse?
        >=nil
        var dataVal2: NSData =  NSURLConnection.sendSynchronousRequest(request2, returningResponse: response2, error:nil)!
        var err2: NSError?
        let responseDict2 : AnyObject! = NSJSONSerialization.JSONObjectWithData(dataVal2, options: nil, error: nil)
        let bghist:NSArray=responseDict2 as! NSArray
        var ct2=NSInteger(NSDate().timeIntervalSince1970)
        var google="" as String
        var xg="" as String
        var yg="" as String
        var pc="&chco=" as String
        var maxy=0
        var maxx=0
        var miny=1000
        var bgoffset=40
        var bgth=180
        var bgtl=80
        var bgtimes = [Int](count: numbg+1, repeatedValue: 0)
        let minutes=hours*60
        var inc:Int=1
        if hours<7 {inc=1} else
            if hours<13 {inc=2} else
                {inc=4}
        println(bghist.count)
        println(numbg)
        //find max time, min and max bg
        for var i=0; i<bghist.count; i=i+1 {
        //for i in 0...bghist.count-1 {
            bgtimes[i]=minutes-(((ct2*1000-(bghist[i]["date"] as! Int))/1000)/(60) as Int)
            if (bgtimes[i]>=0) {
            if (bgtimes[i]>maxx) { maxx=bgtimes[i]}
            if ((bghist[i]["sgv"] as! String).toInt()>maxy) {maxy=(bghist[i]["sgv"] as! String).toInt()!}
            if ((bghist[i]["sgv"] as! String).toInt()<miny) {miny=(bghist[i]["sgv"] as! String).toInt()!}
            }
        }
        if maxy<bgth {maxy=bgth}
        if miny>bgtl {miny=bgtl}
        println("maxx")
        println(maxx)
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
            }
        }
        xg=(dropLast(xg))
        yg=(dropLast(yg))
        pc=(dropLast(pc))
        var low:Double=Double(bgtl-miny)/Double(maxy-miny)
        var high:Double=Double(bgth-miny)/Double(maxy-miny)
        
        //    var band="&chm=r,66FF66,0,"+String(format:"%.3f",(high))+","+String(format:"%.3f",(low))
        //    google="https://chart.googleapis.com/chart?cht=lxy:nda&chxt=y&chxr=0,0,"+String(maxy)+"&chs=200x100"+band+"|o,0066FF,0,-1,3"+"&chf=bg,s,FFFFFF|bg,ls,0,FFFFFF,0.13,CCCCCC,0.29,FFFFFF,0.29,CCCCCC,0.29&chls=3&chd=t:"+xg+"|"+yg
        
        //bands are at 80,180, vertical lines for hours
        var band1="&chm=r,FFFFFF,0,"+String(format:"%.2f",high-0.01)+","+String(format:"%.3f",high)
        var band2="|r,FFFFFF,0,"+String(format:"%.2f",(low))+","+String(format:"%.3f",low+0.01)
        //var hourlyverticals="|bg,ls,0,FFFFFF,0.13,CCCCCC,0.29,FFFFFF,0.29,CCCCCC,0.29"
        //"|o,0066FF,0,-1,3"
        //let hourlyverticals="&chg="+String(format:"%.3f",Double(100/hours))+",0"
        let h:String=String(stringInterpolationSegment: 100.0/Double(hours))
        
        let hourlyverticals="&chg="+h+",0"
        
        
       // google="https://chart.googleapis.com/chart?cht=s:nda&chxt=y&chxr=0,"+String(miny)+","+String(maxy)+"&chs=180x100"+"&chf=bg,s,000000&chls=3&chd=t:"+xg+"|"+yg+"|20"+pc+"&chxs=0,FFFFFF"+band1+band2+"&chg=33.3,0"
        google="https://chart.googleapis.com/chart?cht=s:nda&chxt=y&chxr=0,"+String(miny)+","+String(maxy)+"&chs=180x100"+"&chf=bg,s,000000&chls=3&chd=t:"+xg+"|"+yg+"|20"+pc+"&chxs=0,FFFFFF"+band1+band2+hourlyverticals
        
        println(google)

       // graphhours.setText("Last "+String(slidervalue)+" Hours")
            return google
        
        
        

      
  //      }
        
    
    }
    


    }



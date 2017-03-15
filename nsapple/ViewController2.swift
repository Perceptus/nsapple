//
//  ViewController2.swift
//  nsapple
//
//  Created by Kenneth Stack on 7/21/15.
//  Copyright (c) 2015 Perceptus.org. All rights reserved.
//

import UIKit

class ViewController2: UIViewController {

    @IBOutlet weak var urlbutton: UIButton!
    @IBOutlet weak var pebbleurl: UITextField!
    
    @IBOutlet weak var primarydisplay: UISegmentedControl!
    
    @IBAction func primarydisplay(_ sender: AnyObject) {
          var defaults: UserDefaults = UserDefaults(suiteName: "group.perceptus.nsapple")!
        if primarydisplay.selectedSegmentIndex==0 {defaults.set("dex", forKey: "primarydisplay")} else
        {defaults.set("raw", forKey: "primarydisplay")}
        
        defaults.synchronize()
    }
    @IBAction func urlbuttontouch(_ sender: AnyObject) {
        var defaults: UserDefaults = UserDefaults(suiteName: "group.perceptus.nsapple")!
        let url=pebbleurl.text
        defaults.set(url, forKey: "pebbleurl")
        defaults.synchronize()
        let alertController = UIAlertController(title: "URL Has Been Saved", message: "If WatchApp Says No Connection Please Check URL", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            print(action)
        }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true) {
            // ...
        }
        
    }
    @IBAction func urlchanged(_ sender: AnyObject) {
     
    }
    override func viewDidLoad() {
        super.viewDidLoad()
         var defaults: UserDefaults = UserDefaults(suiteName: "group.perceptus.nsapple")!
        if let url=defaults.object(forKey: "pebbleurl") as? String {
            pebbleurl.text=url}
        //will write dex to defaults first time thru
        if let primarydisplay=defaults.object(forKey: "primarydisplay") as? String {
            if primarydisplay=="dex" {self.primarydisplay.selectedSegmentIndex=0} else {self.primarydisplay.selectedSegmentIndex=1}
        }
        if primarydisplay.selectedSegmentIndex==0 {defaults.set("dex", forKey: "primarydisplay")} else
        {defaults.set("raw", forKey: "primarydisplay")}
        defaults.synchronize()


        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

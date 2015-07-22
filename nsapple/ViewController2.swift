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
    
    @IBAction func urlbuttontouch(sender: AnyObject) {
        var defaults: NSUserDefaults = NSUserDefaults(suiteName: "group.perceptus.nsapple")!
        let url=pebbleurl.text
        defaults.setObject(url, forKey: "pebbleurl")
        defaults.synchronize()
    }
    @IBAction func urlchanged(sender: AnyObject) {
     
    }
    override func viewDidLoad() {
        super.viewDidLoad()

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

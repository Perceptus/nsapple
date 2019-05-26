# nsapple 2.0
apple watch app for Nightscout / Loop followers

![image](https://user-images.githubusercontent.com/8536751/58384240-8b05e580-7fad-11e9-9899-509e9a073ee7.png)

# Goal
nsapple was originally written to follow BG data from Nightscout.  It has morphed (mostly thru quick hacks) to add data from Loop. nsapple 2.0 is a first attempt to clean up the code base and make it more useable, reliable, less resource intenstive and more responsive. The code base needs a lot of work, but this was a first step.  

# Requirements
* ios 11+
* watchos 4+ (supports series 1-4 watches)

# Release Notes
* Faster Performance - graphs are now built in Core Graphics directly on the watch versus using an offline graph creater (required by Watch os1).  
* Data Polling - data is only pulled from Nightscout when the time since the last BG reading is greater then 6 minutes.  Each time the watch is engaged, if the time is over 6 minutes all data is reloaded.  This leads to lower consumption of battery and data, and the UI looks a lot smoother.
* Error Messages - vastly improved error messaging, including the details of Loop failures.
![image](https://user-images.githubusercontent.com/8536751/58384357-e8e6fd00-7fae-11e9-8579-801c6a81361b.png)
* User Data Setup in ios Watch App 
![image](https://user-images.githubusercontent.com/8536751/58384377-26e42100-7faf-11e9-8b69-c7b6d5f58177.png)
* Support for mmol and for Nightscout Tokens
* Support for Overrides in the "JoJo" Loop Branch
* Code - Some Rebasing, Improved Variable Naming, Better Error Handling.  This was a first step and it needs a lot more work.
* Vastly Improved App Setup in Xcode - See Details Below

# Future Work
This really depends on how many people find nsapple useful.  
* Rebase code to MVC versus prior hacks.  This code was my first attempt at a watchos/ios app in 2015, and its been suffering from a poor start :)
* Language support
* Care portal support
* UI improvements - the UI is quite spartan.  Clean up look and feel, use icons instead of text, etc. 
* OpenAPS support



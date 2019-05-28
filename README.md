# nsapple 2.0
apple watch app for Nightscout / Loop followers

![image](https://user-images.githubusercontent.com/8536751/58384240-8b05e580-7fad-11e9-9899-509e9a073ee7.png)

# Goal
nsapple was originally written to follow BG data from Nightscout.  It has morphed (mostly thru quick hacks) to add data from Loop. nsapple 2.0 is a first attempt to clean up the code base and make it more useable, reliable, less resource intensive and more responsive. 

# Requirements
* ios 11+
* watchos 4+ (supports series 1-4 watches)

# Release Notes
* Faster Performance - graphs are now built in Core Graphics directly on the watch versus using an offline graph creater (required by Watch os1).  
* Data Polling - data is only pulled from Nightscout when the time since the last BG reading is greater then 6 minutes.  Each time the watch is engaged, if the time is over 6 minutes all data is reloaded.  This leads to lower consumption of battery and data, and the UI looks a lot smoother.
* Error Messages - vastly improved error messaging, including the details of Loop failures.
![image](https://user-images.githubusercontent.com/8536751/58513147-d4e8fa00-816c-11e9-92ab-718d94dc64cd.png)
* User Data Setup in ios Watch App 
* Support for mmol and for Nightscout Tokens
* Support for Overrides in the "JoJo" Loop Branch
* Code - Some Rebasing, Improved Variable Naming, Better Error Handling.  This was a first step but needs more work.
* Vastly Improved App Install in Xcode - No More Editing !

# Setup
* Simply click on the blue nsapple project file in the top left corner to show the general tab (see below).
* Then for each of the four targets, click on the team dialog and choose your development team.  Everthing else is auto generated now, just like Loop.  
* Then, atfer choosing your phone and watch combination to build too, click the play button and install.  
* After the software installs on the phone and watch, go to the Watch App on your phone and input your site name, unit preference, and tokens (if needed).
* Now nsapple can run independently from the phone on newer watches!  
* Note - the ios App called nsapple is required but it doesn't actually do anything. 

![image](https://user-images.githubusercontent.com/8536751/58512523-4b84f800-816b-11e9-8a87-fbe3842e1e3a.png)
![image](https://user-images.githubusercontent.com/8536751/58384377-26e42100-7faf-11e9-8b69-c7b6d5f58177.png)

# Future Work
This really depends on how many people find nsapple useful.  
* Rebase code to MVC versus prior hacks.  This code was my first attempt at a watchos/ios app in 2015, and its been suffering from a poor start :)
* Language support
* Care portal support
* UI improvements - the UI is quite spartan.  Clean up look and feel, use icons instead of text, etc. 
* OpenAPS support



# Gazer
Gaze-assisted apps. Gazer your on-screen eye position and accepts voice commands only when you’re looking in a certain area.

## Getting started
These instructions will get you a copy of the project up and running on your local machine.

### Prerequisites
You'll need to following pieces of software and hardware in order to properly run the project
* iPad Pro iOS 13+ (FaceID needed for ARKit eye tracking)
* A mac to run [XCode](https://developer.apple.com/xcode/)

### Installing
Clone the repo
```
https://github.com/CowboyLynk/Gazer
```
Open the file 'GazeAR.xcworkspace' in XCode.

Next connect your iPad to the computer with a usb cable.

Finally select your iPad from the upper-left-hand corner of the screen and click the play icon to run the app.

## Description of Files
There many files created when writing iOS apps. I'll summarize the important ones and leave out the unimportant ones.

### Main.storyboard
A storyboard is a visual representation of the user interface of an iOS application, showing screens of content and the connections between those screens (Source [Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/Storyboard.html)). 'Main.storyboard' is the only storyboard I use and so it contains all of the possible connections between each of the screens. 

### Utilities.swift
Contains commonly used functions that are available accross all views of the app. It includes things like addition/distance of two points.

### View Controller Folder
This folder contains all the view controllers of the app. A view controller manages a single root view, which may itself contain any number of subviews. User interactions with that view hierarchy are handled by your view controller, which coordinates with other objects of your app as needed (Source [Apple](https://developer.apple.com/documentation/uikit/view_controllers))
#### CustomNavController.swift
Contains the logic for the navigation bar at the top of all views
#### CalibrationController.swift
Contains the logic for the calibration view of the app. Responsible for setting up the grid of calibration points, estimating a homography matrix, and sending the computed matrix to the next view controllers. To change the destination of the done button modify the 'segueIdentifier' variable to be one of 'doneCalibratingSegueVideo', 'doneCalibratingSegueWeb', or 'doneCalibratingSegueCall'. Each sends the app to a new use case.
#### WebController.swift
Contains the logic for the web navigation use case. 
#### VideoController.swift
Contains the logic for the YouTube use case. 
#### VideoCallController.swift
Contains the logic for the video chat use case. 

### Extensions Folder
This folder contains all of the extensions of the app. Extensions are nothing more than organization of view controllers. When A view controller file gets too bloated with functions, one can use an extension to separate the code into differnet files.
#### handleWebCommands.swift
Extension of WebController.swift that handles the processing of voice commands specific to the web use case.
#### handleVideoCommands.swift
Extension of VideoController.swift that handles the processing of voice commands specific to the YouTube use case.
#### handleCallCommands.swift
Extension of VideoCallController.swift that handles the processing of voice commands specific to the video chat use case.
#### Calibration.swift
Extension of CalibrationController.swift that keeps track of the user's gaze as they go through the calibration process. It also is responsile for the homography matrix estimation logic.

### Objects Folder
This folder contains various objects used through out the app. Their purpose and scope are broad.
#### VideoViewCollection.swift
This is a custom grid UI element for the video chat app that dynamically resizes depending on the number of people currently logged into the app.
#### SpeechCommandView.swift
This is a custom UIView element that is responsible for the bulk of of the command recongition and processing. It utilizes the apple Speech framework and only records audio when the user it looking at this UI element. It also handles the animation logic such as expanding when being viewed and collapsing when no longer needed.
#### CircleView.swift
This is a small class that is used by SpeechCommandView.swift. It is a circle UI element that has a progress variable that can be set from 0 to 100. Depending on the value of the progress variable, the circle will fill a percentage of its stroke. 
#### GazeTracker.swift
This class abstracts some of the logic for keeping track of gaze positions and adjusting them according to the specified homography. It is a 3D element that can be added to an AR scene and draws cylinder over the eyes of the user. Since all views use eye tracking, this class is reused often.

### OpenCV Folder
The OpenCV framework is not availble for Swift. Luckily, however, it is possible to bridge between languages in Swift and use the OpenCV library (written in C++). In order to convert between the two languages, the following files are needed to convert the data types.
#### GazeAR-Bridging-Header
Contains all the bridging files for the whole app. The only thing it does it import OpenCVWrapper.h
#### OpenCVWrapper.h
Contains the header files for OpenCVWrapper.mm. Defines the data structure needed to convert from Swift to C++
#### OpenCVWrapper.mm
Contains all the logic for making calls the the OpenCV library and the converting the returned data into objects readable by Swift.


//
//  handleGazePosition.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/11/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import UIKit

let allowedOffScreenDistSquared = CGFloat(2500)
let nearingSpeechViewDist = CGFloat(200)
let speechIconSizeDisabled : CGFloat = 50
let speechIconSizeEnabled : CGFloat = 400

extension VideoController {
    
    func handleGaze(boundedAdjustedGaze : CGPoint, rawGaze : CGPoint, boudnedRawGaze : CGPoint) {
        
        // Check if the gaze is off the screen
        let squaredScreenDist = CGPointDistanceSquared(from: rawGaze, to: boudnedRawGaze)
        if squaredScreenDist <= allowedOffScreenDistSquared && !isGazeOnScreen {
            handleOnScreenGaze()
        } else if squaredScreenDist > allowedOffScreenDistSquared && isGazeOnScreen {
            handleOffScreenGaze()
        }
        
        // Check if the gaze is near the speech icon
        let voiceCommandRect = voiceCommandView.frame
        let boundingRect = CGRect(x: voiceCommandRect.origin.x - nearingSpeechViewDist/2,
                                  y: voiceCommandRect.origin.y - nearingSpeechViewDist/2,
                                  width: voiceCommandRect.width + nearingSpeechViewDist,
                                  height: voiceCommandRect.height + nearingSpeechViewDist)
        let touchedSpeechView = boundingRect.contains(boundedAdjustedGaze)
        if touchedSpeechView && !isSpeechEnabled {
            handleStartSpeech()
        } else if !touchedSpeechView && isSpeechEnabled  {
            handleEndSpeech()
        }
    }
    
    func handleOnScreenGaze() {
        print("user looked on screen")
        isGazeOnScreen = true
    }
    
    func handleOffScreenGaze() {
        print("user looked off screen")
        isGazeOnScreen = false
    }
    
    func handleStartSpeech() {
        print("user looked at speech icon")
        isSpeechEnabled = true
        animateSpeechCommandView(toWidth: speechIconSizeEnabled)
    }
    
    func handleEndSpeech() {
        print("user looked away from speech icon")
        isSpeechEnabled = false
        animateSpeechCommandView(toWidth: speechIconSizeDisabled)
    }
    
    func animateSpeechCommandView(toWidth width : CGFloat) {
        UIView.animate(withDuration: 1.0, animations: {
            self.voiceCommandWidthConstraint.constant = width // Some value
            self.view.layoutIfNeeded()
        })
    }
}

//
//  handleGazePosition.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/11/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import UIKit
import Speech

let allowedOffScreenDistSquared = CGFloat(2500)
let nearingSpeechViewDist = CGFloat(150)
let speechIconSizeDisabled : CGFloat = 50
let speechIconSizeEnabled : CGFloat = 400
let gazeTimeout: Double = 0.7

extension VideoController {
    
    func handleGaze(boundedAdjustedGaze : CGPoint, rawGaze : CGPoint, boundedRawGaze : CGPoint) {
        
        // Check if the gaze is off the screen
        let squaredScreenDist = CGPointDistanceSquared(from: rawGaze, to: boundedRawGaze)
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
        let wasTouchingSpeechView = boundingRect.contains(gaze.coords)
        let sameAction = wasTouchingSpeechView == touchedSpeechView
        let timeDelta = Date().timeIntervalSince(gaze.time)
        let timeoutPassed = timeDelta > gazeTimeout
        if !sameAction && timeoutPassed {
            if touchedSpeechView {
                handleStartSpeech()
            } else {
                handleEndSpeech()
            }
        }
        
        // Update gaze
        if sameAction || timeoutPassed {
            gaze.setCoords(newCoords: boundedAdjustedGaze)
        }
        
        var progress = 1.0
        if !sameAction {
            progress = timeDelta / gazeTimeout
            if !touchedSpeechView {
                progress = 1 - progress
            }
        } else {
            if !touchedSpeechView {
                progress = 0.0
            }
        }
        circleProgressIndicator.updateCircle(progress: CGFloat(progress))
        
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
        videoPlayer.pause()
        voiceRecognitionField.text = ""
        recordAndRecognizeSpeech()
        animateSpeechCommandView(toWidth: speechIconSizeEnabled)
    }
    
    func handleEndSpeech() {
        cancelRecording()
        animateSpeechCommandView(toWidth: speechIconSizeDisabled)
    }
    
    func animateSpeechCommandView(toWidth width : CGFloat) {
        UIView.animate(withDuration: 1.0, animations: {
            self.voiceCommandWidthConstraint.constant = width // Some value
            self.view.layoutIfNeeded()
        })
    }
}

extension VideoController: SFSpeechRecognizerDelegate {
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(title: "Speech Recognizer Error", message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else { return }
        if !myRecognizer.isAvailable {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = String(bestString[indexTo...])
                }
                self.voiceRecognitionField.text = bestString
                self.checkForCommands(fullString: bestString, lastString: lastString)
            } else if let error = error {
                print(error)
            }
        })
    }
    
    func cancelRecording() {
        recognitionTask?.finish()
        recognitionTask = nil
        
        // stop audio
        request.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    func checkForCommands(fullString: String, lastString: String) {
        let lowercaseLastString = lastString.lowercased()
        switch lowercaseLastString {
        case "start", "play", "resume":
            videoPlayer.play()
        case "stop", "pause", "end":
            videoPlayer.pause()
        default: break
        }
    }
    
    func sendAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

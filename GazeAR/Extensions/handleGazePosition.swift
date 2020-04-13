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
let speechTimeout: Double = 3

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
        
        // Update last relevant gaze
        if sameAction || timeoutPassed {
            gaze.setCoords(newCoords: boundedAdjustedGaze)
        }
        
        // Update the progress timeout bar
        var progress = 1.0
        if !sameAction {
            progress = timeDelta / gazeTimeout
            if !touchedSpeechView {
                progress = 1 - progress
            }
        } else if !touchedSpeechView {
            progress = 0.0
        }
        circleProgressIndicator.updateCircle(progress: CGFloat(progress))
    }
    
    func handleOnScreenGaze() {
        isGazeOnScreen = true
    }
    
    func handleOffScreenGaze() {
        isGazeOnScreen = false
    }
    
    func handleStartSpeech() {
        speechTimer?.invalidate()
        videoPlayer.pause()
        voiceRecognitionField.text = ""
        recordAndRecognizeSpeech()
        animateSpeechCommandView(toWidth: speechIconSizeEnabled)
    }
    
    @objc func handleEndSpeech() {
        if recognitionTask != nil {
            speechTimer?.invalidate()
            cancelRecording()
            animateSpeechCommandView(toWidth: speechIconSizeDisabled)
        }
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
                self.voiceRecognitionField.text = bestString
                if result.isFinal {
                    self.checkForCommands(transcript: bestString)
                } else {
                    // reset the timer
                    self.speechTimer?.invalidate()
                    self.speechTimer = Timer.scheduledTimer(timeInterval: speechTimeout, target: self, selector: #selector(self.handleEndSpeech), userInfo: nil, repeats: false)
                }
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
    
    func checkForCommands(transcript: String) {
        
        // Check for seek command
        let skipToRegex = try? NSRegularExpression(pattern: "(skip|go|seek) to (?<timecode>[0-9]+)", options: .caseInsensitive)
        if let match = skipToRegex?.firstMatch(in: transcript, options: [], range: NSRange(location: 0, length: transcript.utf16.count)) {
            let timecodeRange = Range(match.range(withName: "timecode"), in: transcript)!
            if let timecode = processMinutesAndSeconds(timecode: Int(transcript[timecodeRange])!) {
                videoPlayer.play()
                videoPlayer.seekTo(Float(timecode), seekAhead: true)
                return
            }
        }
        
        // Check for alt seek command
        let skipToAltRegex = try? NSRegularExpression(pattern: "(skip|go|seek) to (?<minutes>\\w+) minutes?(( and)? (?<seconds>\\w+) seconds?)?", options: .caseInsensitive)
        if let match = skipToAltRegex?.firstMatch(in: transcript, options: [], range: NSRange(location: 0, length: transcript.utf16.count)) {
            let minutesRange = Range(match.range(withName: "minutes"), in: transcript)!
            let minutesString = String(transcript[minutesRange])
            let minutes = Int(minutesString) ?? convertWrittenNumToInt(numString: minutesString)
            var seconds = 0
            if let secondsRange = Range(match.range(withName: "seconds"), in: transcript) {
                let secondsString = String(transcript[secondsRange])
                seconds = Int(secondsString) ?? convertWrittenNumToInt(numString: secondsString) ?? 0
            }
            
            if minutes != nil {
                let timecode = 60 * minutes! + seconds
                videoPlayer.play()
                videoPlayer.seekTo(Float(timecode), seekAhead: true)
                return
            }
        }

        
        let lowercaseTranscript = transcript.lowercased()
        for word in lowercaseTranscript.split(separator: " ") {
            switch word {
            case "start", "play", "resume":
                videoPlayer.play()
            case "stop", "pause", "end":
                videoPlayer.pause()
            default: break
            }
        }
    }
    
    func processMinutesAndSeconds(timecode: Int) -> Int? {
        if timecode <= 10 {
            return timecode
        }
        
        let secondsOnes = timecode % 10
        let reducedTimecode = timecode / 10
        let secondsTens = reducedTimecode % 10
        let seconds = secondsTens * 10 + secondsOnes
        let minutes = reducedTimecode / 10
        if seconds > 59 {
            return nil
        }
        return minutes * 60 + seconds
    }
    
    func sendAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

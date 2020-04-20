//
//  handleVideoCommands.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/19/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation

extension VideoController: SpeechCommandViewDelegate {
    
    func processCommand(command: String) -> Bool {
        
        // Check for seek command
        if processSeekCommand(command: command) {
            return true
        }

        
        let lowercaseTranscript = command.lowercased()
        for word in lowercaseTranscript.split(separator: " ") {
            switch word {
            case "start", "play", "resume":
                videoPlayer.play()
                return true
            case "stop", "pause", "end":
                videoPlayer.pause()
                return true
            default: break
            }
        }
        
        return false
    }
    
    func processSeekCommand(command: String) -> Bool {
        // Check for seek command
        let skipToRegex = try? NSRegularExpression(pattern: "(skip|go|seek) to (?<timecode>[0-9]+)", options: .caseInsensitive)
        if let match = skipToRegex?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)) {
            let timecodeRange = Range(match.range(withName: "timecode"), in: command)!
            if let timecode = processMinutesAndSeconds(timecode: Int(command[timecodeRange])!) {
                videoPlayer.play()
                videoPlayer.seekTo(Float(timecode), seekAhead: true)
                return true
            }
        }
        
        // Check for alt seek command
        let skipToAltRegex = try? NSRegularExpression(pattern: "(skip|go|seek) to (?<minutes>\\w+) minutes?(( and)? (?<seconds>\\w+) seconds?)?", options: .caseInsensitive)
        if let match = skipToAltRegex?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)) {
            let minutesRange = Range(match.range(withName: "minutes"), in: command)!
            let minutesString = String(command[minutesRange])
            let minutes = Int(minutesString) ?? convertWrittenNumToInt(numString: minutesString)
            var seconds = 0
            if let secondsRange = Range(match.range(withName: "seconds"), in: command) {
                let secondsString = String(command[secondsRange])
                seconds = Int(secondsString) ?? convertWrittenNumToInt(numString: secondsString) ?? 0
            }
            
            if minutes != nil {
                let timecode = 60 * minutes! + seconds
                videoPlayer.play()
                videoPlayer.seekTo(Float(timecode), seekAhead: true)
                return true
            }
        }
        
        return false
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
}

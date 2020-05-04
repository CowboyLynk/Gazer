//
//  handleCallCommands.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/27/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation

extension VideoCallController: SpeechCommandViewDelegate {
    func processCommand(command: String) -> Bool {
        let focusRegex = try? NSRegularExpression(pattern: "(?<scrollCommand>start|stop|enable|disable) ([a-z]+ )*focus(ing)?", options: .caseInsensitive)
        if let match = focusRegex?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)) {
            let focusCommandRange = Range(match.range(withName: "scrollCommand"), in: command)!
            let focusCommand = command[focusCommandRange].lowercased()
            changeFocus(value: focusCommand == "enable" || focusCommand == "start")
            return true
        }
        
        let hangUpRegex = try? NSRegularExpression(pattern: "hang( )?up|((end|stop) ([a-z]+ )*call)", options: .caseInsensitive)
        if let _ = hangUpRegex?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)) {
            leaveChannel()
            return true
        }
        
        return false
    }
    
    func changeFocus(value: Bool) {
        unfocusedSlider.isEnabled = value
        isFocusEnabled = value
        if !isFocusEnabled {
            for case let cell as VideoCell in collectionView.visibleCells {
                agoraKit.adjustUserPlaybackSignalVolume(cell.uid, volume: 100)
            }
        }
    }
    
}

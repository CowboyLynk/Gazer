//
//  handleWebCommands.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/19/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import UIKit

extension WebController: SpeechCommandViewDelegate {
    
    func processCommand(command: String) -> Bool {
        let lockScrollRegex = try? NSRegularExpression(pattern: "(?<scrollCommand>enable|disable) ([a-z]+ )*scroll(ing)?", options: .caseInsensitive)
        if let match = lockScrollRegex?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)) {
            let scrollCommandRange = Range(match.range(withName: "scrollCommand"), in: command)!
            let scrollCommand = command[scrollCommandRange].lowercased()
            if scrollCommand == "enable" {
                enableScroll()
            } else {
                disableScroll()
            }
        }
        return false
    }
    
    func enableScroll() {
        scrollEnabled = true
        visualFeedbackView.layer.borderWidth = 0
    }
    
    func disableScroll() {
        scrollEnabled = false
        visualFeedbackView.layer.borderWidth = 10
        visualFeedbackView.layer.borderColor = UIColor.systemRed.cgColor
    }
}

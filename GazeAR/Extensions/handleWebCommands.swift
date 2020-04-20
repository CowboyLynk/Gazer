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
        let lockScrollRegex = try? NSRegularExpression(pattern: "(?<scrollCommand>enable|disable|lock|unlock) ([a-z]+ )*scroll(ing)?", options: .caseInsensitive)
        if let match = lockScrollRegex?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)) {
            let scrollCommandRange = Range(match.range(withName: "scrollCommand"), in: command)!
            let scrollCommand = command[scrollCommandRange].lowercased()
            if scrollCommand == "enable" || scrollCommand == "unlock" {
                enableScroll()
            } else {
                disableScroll()
            }
            return true
        }
        
        let navigateToRegex = try? NSRegularExpression(pattern: "(navigate|go|(take me)) to (?<link>(www.)?[a-z]+.(com|org|edu|net))", options: .caseInsensitive)
        if let match = navigateToRegex?.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)) {
            let linkRange = Range(match.range(withName: "link"), in: command)!
            var link = command[linkRange].lowercased()
            if !link.starts(with: "www") {
                link = "www." + link
            }
            print(link)
            let url = URL(string: "https://" + link + "/")!
            webView.load(URLRequest(url: url))
        }
        return false
    }
    
    func enableScroll() {
        scrollEnabled = true
        webView.scrollView.isScrollEnabled = true
        webView.layer.borderWidth = 0
    }
    
    func disableScroll() {
        scrollEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.layer.borderWidth = 10
    }
}

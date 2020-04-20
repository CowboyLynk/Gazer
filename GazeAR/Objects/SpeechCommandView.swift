//
//  SpeechCommandView.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/19/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import UIKit
import Speech

protocol SpeechCommandViewDelegate {
    func processCommand(command: String) -> Bool
}

class SpeechCommandView: UIView {
    
    // MARK: - Variables
    // UI Elements
    var voiceRecognitionField: UITextField!
    var circleProgressIndicator: CircleView!
    var microphoneIcon: UIImageView!
    
    // Speech Recognition
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var speechTimer: Timer?
    
    // Other variables
    let delegate: SpeechCommandViewDelegate!
    var voiceCommandWidthConstraint: NSLayoutConstraint!
    
    
    // MARK: - Initialization
    init(frame: CGRect, delegate: SpeechCommandViewDelegate) {
        self.delegate = delegate
        super.init(frame: frame)
        initializeUIElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeUIElements() {
        // Self
        let frameHeight = self.frame.height
        self.layer.cornerRadius = frameHeight / 2
        self.layer.masksToBounds = true
        let fullFrame = CGRect(x: 0, y: 0, width: frameHeight, height: frameHeight)
        
        // Blur effect
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = fullFrame
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        let blurViewConstraints = [
            blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ]
        self.addSubview(blurEffectView)
        
        // Microphone icon
        let micSize = frameHeight * 0.5
        let image = UIImage(systemName: "mic.fill")
        microphoneIcon = UIImageView(image: image)
        microphoneIcon.tintColor = .white
        microphoneIcon.translatesAutoresizingMaskIntoConstraints = false
        microphoneIcon.contentMode = .scaleAspectFit
        let micConstraints = [
            microphoneIcon.heightAnchor.constraint(equalToConstant: micSize),
            microphoneIcon.widthAnchor.constraint(equalToConstant: micSize),
            microphoneIcon.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: micSize/2),
            microphoneIcon.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ]
        self.addSubview(microphoneIcon)
        
        // Recognition field
        voiceRecognitionField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: frameHeight))
        voiceRecognitionField.textColor = .white
        voiceRecognitionField.translatesAutoresizingMaskIntoConstraints = false
        voiceRecognitionField.attributedPlaceholder = NSAttributedString(string: "Please say a command...",attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray3])
        voiceRecognitionField.borderStyle = .none
        let recognitionContraints = [
            voiceRecognitionField.leadingAnchor.constraint(
                equalTo: microphoneIcon.leadingAnchor,
                constant: 3/2*micSize + 5),
            voiceRecognitionField.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ]
        self.addSubview(voiceRecognitionField)
        
        // Progress indicator
        circleProgressIndicator = CircleView(frame: fullFrame)
        self.addSubview(circleProgressIndicator)
        
        let constraints = blurViewConstraints + micConstraints + recognitionContraints
        NSLayoutConstraint.activate(constraints)
        self.layoutIfNeeded()
    }
    
    // MARK: - Functions
    func handleStartSpeech() {
        speechTimer?.invalidate()
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
    
    func updateCircle(progress: CGFloat) {
        circleProgressIndicator.updateCircle(progress: progress)
    }
    
    private func animateSpeechCommandView(toWidth width : CGFloat) {
        UIView.animate(withDuration: 1.0, animations: {
            var newFrame = self.frame
            newFrame.size.width = width
            self.frame = newFrame
            self.layoutIfNeeded()
        })
    }
}

// MARK: - Speech Recognizer Delegate
extension SpeechCommandView: SFSpeechRecognizerDelegate {
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
            print("There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else { return }
        if !myRecognizer.isAvailable {
            print("Speech recognition is not currently available. Check back at a later time.")
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.voiceRecognitionField.text = bestString
                if result.isFinal {
                    let isCommandRecognized = self.delegate.processCommand(command: bestString)
                } else {
                    // reset the timer
                    self.speechTimer?.invalidate()
                    self.speechTimer = Timer.scheduledTimer(timeInterval: speechTimeout, target: self, selector: #selector(self.handleEndSpeech), userInfo: nil, repeats: false)
                }
            } else if let error = error { print(error) }
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
}

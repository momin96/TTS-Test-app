//
//  ViewController.swift
//  TTS Test app
//
//  Created by Nasir Ahmed Momin on 11/12/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
        
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = "Here goes long story of a tiger in big jungle, where he used to stay with mama tiger & papa tiger, papa tiger always goes for hunting & mama tiger takes care of little baby tiger. Baby tiger loves to go to school"
        
        let gs = UIPanGestureRecognizer(target: self,
                                        action: #selector(handleGesture))
        self.view.addGestureRecognizer(gs)
        
    }
    
    @objc func handleGesture() {
        textView.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        StoryManager.shared.story = textView.text ?? ""
        textView.endEditing(true)
    }
}


class StoryManager {
    static var shared = StoryManager()
    var story = ""
}

class SpeakController: UIViewController, AVSpeechSynthesizerDelegate {
    
    @IBOutlet weak var label: UILabel!
    
    let avSpeechSynthesizer = AVSpeechSynthesizer()
    var utterance: AVSpeechUtterance?
    
    override func viewDidLoad() {
        avSpeechSynthesizer.delegate = self
        utterance = AVSpeechUtterance(string: StoryManager.shared.story)
        utterance?.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance?.volume = 0.1
        utterance?.rate = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let mutableAttributedString = NSMutableAttributedString(string: StoryManager.shared.story)
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                             value: UIColor.orange,
                                             range:  NSMakeRange(0, StoryManager.shared.story.count))
        
        label.attributedText = mutableAttributedString
    }
    
    @IBAction func play(_ sender: UIButton) {
        guard let utterance = self.utterance else {
            return
        }
        if avSpeechSynthesizer.isPaused {
            avSpeechSynthesizer.continueSpeaking()
        } else if !avSpeechSynthesizer.isSpeaking {
            avSpeechSynthesizer.speak(utterance)
        }
    }

    @IBAction func pause(_ sender: UIButton) {
        avSpeechSynthesizer.pauseSpeaking(at: .word)
    }
    
    @IBAction func stop(_ sender: UIButton) {
        avSpeechSynthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {

        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.orange, range:  NSMakeRange(0, StoryManager.shared.story.count))
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, characterRange.location + characterRange.length) )
        label.attributedText = mutableAttributedString
    }
}


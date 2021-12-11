//
//  ViewController.swift
//  TTS Test app
//
//  Created by Nasir Ahmed Momin on 11/12/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {

    let myStory = "Here goes long story of a tiger in big jungle, where he used to stay with mama tiger & papa tiger"
    
    @IBOutlet weak var textView: UITextView!
    
    let avSpeechSynthesizer = AVSpeechSynthesizer()
    var utterance: AVSpeechUtterance?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mutableAttributedString = NSMutableAttributedString(string: myStory)
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                             value: UIColor.orange,
                                             range:  NSMakeRange(0, myStory.count))
        
        textView.attributedText = mutableAttributedString
               
        avSpeechSynthesizer.delegate = self
        utterance = AVSpeechUtterance(string: myStory)
        utterance?.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance?.volume = 0.1
        utterance?.rate = 0.5
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
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.orange, range:  NSMakeRange(0, myStory.count))
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, characterRange.location + characterRange.length) )
        print(characterRange)
        textView.attributedText = mutableAttributedString
//        print (mutableAttributedString) //debug message
    }
}


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
    @IBOutlet var record_btn_ref: UIButton!
    @IBOutlet var play_btn_ref: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = "Here goes long story of a tiger in big jungle, where he used to stay with mama tiger & papa tiger, papa tiger always goes for hunting & mama tiger takes care of little baby tiger. Baby tiger loves to go to school"
        
        let gs = UIPanGestureRecognizer(target: self,
                                        action: #selector(handleGesture))
        self.view.addGestureRecognizer(gs)
        
        let chararacterSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let components = textView.text.components(separatedBy: chararacterSet)
        let words = components.filter { !$0.isEmpty }
        print(words.count)
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

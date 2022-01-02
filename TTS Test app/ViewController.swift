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

class SpeakController: UIViewController, AVSpeechSynthesizerDelegate, SpeechRecognizerdelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
   
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var choice: UISwitch!
    @IBOutlet weak var humanVoiceRecordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordingTimeLabel: UILabel!

    let avSpeechSynthesizer = AVSpeechSynthesizer()
    var utterance: AVSpeechUtterance?
    
//    var isRecording = false
//    var speechRecognizer = SpeechRecognizer()
    
    override func viewDidLoad() {
        requestAudioPermission()

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
        
//        speechRecognizer.reset()
//        speechRecognizer.transcribe()
//        isRecording = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        speechRecognizer.stopTranscribing()
//        isRecording = false
    }
    
    func requestAudioPermission()
    {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            isAudioRecordingGranted = true
            break
        case AVAudioSession.RecordPermission.denied:
            isAudioRecordingGranted = false
            break
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (allowed) in
                if allowed {
                    self.isAudioRecordingGranted = true
                } else {
                    self.isAudioRecordingGranted = false
                }
            })
            break
        default:
            break
        }
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func getFileUrl() -> URL
    {
        let filename = "myStory.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
    return filePath
    }
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer : AVAudioPlayer!
    var meterTimer:Timer!
    var textColorTimer: Timer!
    var isAudioRecordingGranted: Bool!
    var isRecording = false
    var isPlaying = false
    
    
    var startPotion = 0
    var elapsedWordCount = 0
    
    var counter = 0
    var stringLength = 0
    
    @objc func updateTextColor(_ timer: Timer) {
        
        if counter < self.rangeList.count {
            let length = self.rangeList[counter]
            
            stringLength += length
            
            let range = NSRange(location: 0, length: stringLength)

            let mutableAttributedString = NSMutableAttributedString(string: StoryManager.shared.story)
            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.orange, range:  NSMakeRange(0, StoryManager.shared.story.count))
            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: range)
            label.attributedText = mutableAttributedString
            
            
            counter += 1
            
        } else {
            textColorTimer.invalidate()
            textColorTimer = nil
            counter = 0
            stringLength = 0
        }
    }
    
    @objc func updateAudioMeter(timer: Timer)
    {
        if audioRecorder.isRecording
        {
            let hr = Int((audioRecorder.currentTime / 60) / 60)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            recordingTimeLabel.text = totalTimeString
            audioRecorder.updateMeters()
        }
    }
    
    func prepare_play()
    {
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl())
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        }
        catch{
            print("Error")
        }
    }
    
    @IBAction func choiceToggle(_ sender: UISwitch) {
        humanVoiceRecordButton.isHidden = !sender.isOn
        recordingTimeLabel.isHidden = !sender.isOn
    }
    
    var rangeList = [Int]()

    func calculateRangesForTextColoring() {
        let chararacterSet = CharacterSet.whitespacesAndNewlines//.union(.punctuationCharacters)
        let components = StoryManager.shared.story.components(separatedBy: chararacterSet)
        let words = components.filter { !$0.isEmpty }
        
        var coloredWordsCount = 0
        
        let duration = Int(audioPlayer.duration)
                
        var rangeList = [Int]()
        
        for i in 0..<duration {
            
            if coloredWordsCount < words.count {
                let wps = Int((Double(words.count - coloredWordsCount) / Double(duration - i )).rounded(.toNearestOrAwayFromZero)) // 41.0 / (15.0 - 0.0)
                
                var wordLength = 0
                for j in coloredWordsCount..<coloredWordsCount+wps {
                    wordLength += words[j].count
                }

                wordLength += wps

                if i == duration - 1 {
                    rangeList.append(wordLength - 1)
                } else {
                    rangeList.append(wordLength)
                }
                
                coloredWordsCount += wps
            }
        }

        
        let totalWords = rangeList.reduce(0) { partialResult, v in
            partialResult + v
        }
        
        print("totalWords \(totalWords)  storylength \(StoryManager.shared.story.count)")
        
        self.rangeList = rangeList
    }
    
    
    @IBAction func recordHumanVoice(_ sender: UIButton) {
        if(isRecording)
        {
            finishAudioRecording(success: true)
            humanVoiceRecordButton.setTitle("Record", for: .normal)
            playButton.isEnabled = true
            isRecording = false
            
            // Make sure `audioPlayer` instance is initilized
            prepare_play()
            
            // Perform calculation
            calculateRangesForTextColoring()
        }
        else
        {
            setup_recorder()

            audioRecorder.record()
            meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
            humanVoiceRecordButton.setTitle("Stop", for: .normal)
            playButton.isEnabled = false
            isRecording = true
        }
    }
    
    func finishAudioRecording(success: Bool)
    {
        if success
        {
            audioRecorder.stop()
            audioRecorder = nil
            meterTimer.invalidate()
            print("recorded successfully.")
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Recording failed.", action_title: "OK")
        }
    }
    
    func setup_recorder()
    {
        if isAudioRecordingGranted
        {
            let session = AVAudioSession.sharedInstance()
            do
            {
                try session.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
            }
            catch let error {
                display_alert(msg_title: "Error", msg_desc: error.localizedDescription, action_title: "OK")
            }
        }
        else
        {
            display_alert(msg_title: "Error", msg_desc: "Don't have access to use your microphone.", action_title: "OK")
        }
    }
    
    func display_alert(msg_title : String , msg_desc : String ,action_title : String)
    {
        let ac = UIAlertController(title: msg_title, message: msg_desc, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: action_title, style: .default)
        {
            (result : UIAlertAction) -> Void in
        _ = self.navigationController?.popViewController(animated: true)
        })
        present(ac, animated: true)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        if !flag
        {
            finishAudioRecording(success: false)
        }
        playButton.isEnabled = true
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        humanVoiceRecordButton.isEnabled = true
    }
    
    @IBAction func play(_ sender: UIButton) {
        
        if choice.isOn {

            if(isPlaying)
            {
                audioPlayer.stop()
                humanVoiceRecordButton.isEnabled = true
                playButton.setTitle("Play", for: .normal)
                isPlaying = false
            }
            else
            {
                if FileManager.default.fileExists(atPath: getFileUrl().path)
                {
                    humanVoiceRecordButton.isEnabled = false
                    playButton.setTitle("pause", for: .normal)
//                    prepare_play()
                    audioPlayer.play()
                    isPlaying = true

                    audioPlayer.enableRate = true

                    textColorTimer = Timer.scheduledTimer(timeInterval: 1,
                                                          target:self, selector:#selector(updateTextColor(_:)),
                                                          userInfo:nil,
                                                          repeats:true)

                }
                else
                {
                    display_alert(msg_title: "Error", msg_desc: "Audio file is missing.", action_title: "OK")
                }
            }
            
        } else {
            
            guard let utterance = self.utterance else {
                return
            }
            
            if avSpeechSynthesizer.isSpeaking {
                avSpeechSynthesizer.pauseSpeaking(at: .word)
                playButton.setTitle("Play", for: .normal)
            } else if avSpeechSynthesizer.isPaused {
                avSpeechSynthesizer.continueSpeaking()
                playButton.setTitle("Pause", for: .normal)
            } else if !avSpeechSynthesizer.isSpeaking {
                avSpeechSynthesizer.speak(utterance)
                playButton.setTitle("Pause", for: .normal)
            }
        }
    }

    @IBAction func pause(_ sender: UIButton) {
        avSpeechSynthesizer.pauseSpeaking(at: .word)
    }
    
    @IBAction func stop(_ sender: UIButton) {
        avSpeechSynthesizer.stopSpeaking(at: .immediate)
    }

    @available(iOS 13.0, *)
    func speechRecognizer(_ recognizer: SpeechRecognizer, didSpokenText text: String) {
        
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {

        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.orange, range:  NSMakeRange(0, StoryManager.shared.story.count))
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSMakeRange(0, characterRange.location + characterRange.length) )
        label.attributedText = mutableAttributedString
    }
}


//
//  SpeakController.swift
//  TTS Test app
//
//  Created by Nasir Ahmed Momin on 09/01/22.
//

import UIKit
import AVFoundation
import SwiftUI

@available(iOS 13.0, *)
class SpeakController: UIViewController, AVSpeechSynthesizerDelegate, SpeechRecognizerdelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
   
    enum VoiceState: String {
        case Play
        case Pause
        case Stop
    }
    
    var currentVoice: AVSpeechSynthesisVoice?
    
    var currentVoiceState: VoiceState = .Play {
        didSet {
            playButton.setTitle(currentVoiceState.rawValue, for: .normal)
        }
    }
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var choice: UISwitch!
    @IBOutlet weak var humanVoiceRecordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var selectedVoiceButton: UIButton!
    @IBOutlet weak var voiceSpeed: UISlider!
    @IBOutlet weak var speedLabel: UILabel!
    
    let avSpeechSynthesizer = AVSpeechSynthesizer()
    var utterance: AVSpeechUtterance?
    
//    var isRecording = false
//    var speechRecognizer = SpeechRecognizer()
    
    override func viewDidLoad() {
        requestAudioPermission()

        avSpeechSynthesizer.delegate = self
        updateVoice(with: AVSpeechSynthesisVoice.currentLanguageCode())
    }
    
    fileprivate func updateVoice(with language: String, and name: String? = nil) {
        
        var title = language
        if let name = name {
            title += " - \(name)"
        }
        
        selectedVoiceButton.setTitle(title, for: .normal)
        utterance = AVSpeechUtterance(string: StoryManager.shared.story)
        utterance?.voice = AVSpeechSynthesisVoice(language: language)
        currentVoice = utterance?.voice
        utterance?.volume = 0.9
        updateVoiceSpeed(with: voiceSpeed.value)
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
    
    @IBAction func play(_ sender: UIButton!) {
        
        if choice.isOn {

            if(isPlaying)
            {
                audioPlayer.stop()
                humanVoiceRecordButton.isEnabled = true
                currentVoiceState = .Play
                isPlaying = false
            }
            else
            {
                if FileManager.default.fileExists(atPath: getFileUrl().path)
                {
                    humanVoiceRecordButton.isEnabled = false
                    currentVoiceState = .Pause
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
                currentVoiceState = .Play
            } else if avSpeechSynthesizer.isPaused {
                avSpeechSynthesizer.continueSpeaking()
                currentVoiceState = .Pause
            } else if !avSpeechSynthesizer.isSpeaking {
                avSpeechSynthesizer.speak(utterance)
                currentVoiceState = .Pause
            }
        }
    }

    @IBAction func pause(_ sender: UIButton) {
        avSpeechSynthesizer.pauseSpeaking(at: .word)
    }
    
    @IBAction func stop(_ sender: UIButton) {
        stopVoicePlaying()
    }

    @IBAction func selectVoice(_ sender: UIButton) {
        showAvailableVoices()
    }
    
    @IBAction func voiceSpeedChanged(_ sender: UISlider) {
        updateVoiceSpeed(with: sender.value)
    }
    
    fileprivate func updateVoiceSpeed(with value: Float) {
        utterance?.rate = value
        speedLabel.text = String(Int(value * 100.0)) + "%"
        stopVoicePlaying()
    }
    
    enum VoiceGender {
        case male
        case female
    }
    
    var voiceGender: VoiceGender = .female
    
    @IBAction func voiceGenderChanged(_ sender: UISwitch) {
        updateVoiceGender(sender.isOn)
    }
    
    fileprivate func updateVoiceGender(_ isMale: Bool) {
        voiceGender = isMale ? .male : .female
//        utterance?.voice?.gender = isMale ? .male : .female
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

@available(iOS 13.0, *)
extension SpeakController {
    
    
    fileprivate func stopVoicePlaying() {
        avSpeechSynthesizer.stopSpeaking(at: .immediate)
        currentVoiceState = .Play
        
    }
    
    func showAvailableVoices() {
        
        stopVoicePlaying()
        let voices = AVSpeechSynthesisVoice.speechVoices()

        
        let voiceListView = VoicesItemList(voices: voices,
                                           currentVoice: currentVoice) { [weak self] selectedVoice in
            self?.updateVoice(with: selectedVoice.language, and: selectedVoice.name)
        }
        
        let hostingContoller = UIHostingController(rootView: voiceListView)
        present(hostingContoller, animated: true)
    }
}



@available(iOS 13.0, *)
struct VoicesItemList: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var voices: [AVSpeechSynthesisVoice]
    var currentVoice: AVSpeechSynthesisVoice?
    
    var selectionHandler: (AVSpeechSynthesisVoice) -> Void
    
    var body: some View {
        if #available(iOS 14.0, *) {
            bodyView
                .navigationTitle("Select a voice")
        } else {
            bodyView
                .navigationBarTitle("Select a voice")
        }
    }
    
    var bodyView: some View {
        NavigationView {
            SwiftUI.Form {
                ForEach(voices, id: \.self) { item in
                    Button {
                        selectionHandler(item)
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack {
                            Text("\(item.language) - \(item.name)")
                            Spacer()
                            currentVoice.map { value in
                                VStack {
                                    if item.language == value.language && item.name == value.name {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

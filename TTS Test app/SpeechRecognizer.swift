/*
See LICENSE folder for this sample’s licensing information.
*/

import AVFoundation
import Foundation
import Speech
//import SwiftUI

protocol SpeechRecognizerdelegate {
    @available(iOS 13.0, *)
    func speechRecognizer(_ recognizer: SpeechRecognizer, didSpokenText text: String)
}

/// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
@available(iOS 13.0, *)
class SpeechRecognizer: ObservableObject {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    var transcript: String = ""
    var delegate: SpeechRecognizerdelegate?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    /**
     Initializes a new speech recognizer. If this is the first time you've used the class, it
     requests access to the speech recognizer and the microphone.
     */
    init() {
        recognizer = SFSpeechRecognizer()
        
        DispatchQueue.global(qos: .background).async {
            do {
                guard self.recognizer != nil else {
                    throw RecognizerError.nilRecognizer
                }
                
                SFSpeechRecognizer.hasAuthorizationToRecognize { (authorised) in
                    if authorised {
                        AVAudioSession.sharedInstance().hasPermissionToRecord { (has) in
                            if has {
                                
                            } else {
                                fatalError("RecognizerError.notPermittedToRecord")
                            }
                        }
                    } else {
                        fatalError("RecognizerError.notAuthorizedToRecognize")
                    }
                }
            }
            catch {
                self.speakError(error)
            }
        }
        
//        Task(priority: .background) {
//            do {
//                guard recognizer != nil else {
//                    throw RecognizerError.nilRecognizer
//                }
//                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
//                    throw RecognizerError.notAuthorizedToRecognize
//                }
//                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
//                    throw RecognizerError.notPermittedToRecord
//                }
//            } catch {
//                speakError(error)
//            }
//        }
    }
    
    deinit {
        reset()
    }
    
    /**
        Begin transcribing audio.
     
        Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
        The resulting transcription is continuously written to the published `transcript` property.
     */
    func transcribe() {
        DispatchQueue(label: "Speech Recognizer Queue", qos: .background).async {             guard let recognizer = self.recognizer, recognizer.isAvailable else {
                self.speakError(RecognizerError.recognizerIsUnavailable)
                return
            }
            
            do {
                let (audioEngine, request) = try Self.prepareEngine()
                self.audioEngine = audioEngine
                self.request = request
                self.task = recognizer.recognitionTask(with: request, resultHandler: self.recognitionHandler(result:error:))
            } catch {
                self.reset()
                self.speakError(error)
            }
        }
    }
    
    /// Stop transcribing audio.
    func stopTranscribing() {
        reset()
    }
    
    /// Reset the speech recognizer.
    func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    private func recognitionHandler(result: SFSpeechRecognitionResult?, error: Error?) {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
        }
        
        if let result = result {
            speak(result.bestTranscription.formattedString)
        }
    }
    
    private func speak(_ message: String) {
        delegate?.speechRecognizer(self, didSpokenText: message)
        print(message)
        transcript = message
    }
    
    private func speakError(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        transcript = "<< \(errorMessage) >>"
    }
}

extension SFSpeechRecognizer {
    
    static func hasAuthorizationToRecognize(_ completion: @escaping (Bool) -> Void) {
        requestAuthorization { (status) in
            completion(status == .authorized)
        }
    }
    
    
//    static func hasAuthorizationToRecognize() async -> Bool {
//        await withCheckedContinuation { continuation in
//            requestAuthorization { status in
//                continuation.resume(returning: status == .authorized)
//            }
//        }
//    }
}

extension AVAudioSession {
    
    func hasPermissionToRecord(_ completion: @escaping (Bool) -> Void) {
        requestRecordPermission { (authorized) in
            completion(authorized)
        }
    }
    
//    func hasPermissionToRecord() async -> Bool {
//        await withCheckedContinuation { continuation in
//            requestRecordPermission { authorized in
//                continuation.resume(returning: authorized)
//            }
//        }
//    }
}

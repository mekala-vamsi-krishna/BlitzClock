import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isSoundEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isSoundEnabled") }
    }
    
    private let synthesizer = AVSpeechSynthesizer()
    
    init() {
        // Ensure default is true if never set
        if UserDefaults.standard.object(forKey: "isSoundEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "isSoundEnabled")
        }
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category.")
        }
    }
    
    func playTapSound() {
        guard isEnabled else { return }
        // 1104 is a standard keyboard click sound
        AudioServicesPlaySystemSound(1104) 
    }
    
    func playVoiceAlert(_ message: String) {
        guard isEnabled else { return }
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
    
    func playEndSound() {
        guard isEnabled else { return }
        // End Game Sound Alert
        AudioServicesPlayAlertSound(SystemSoundID(1025))
    }
}

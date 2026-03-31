import Foundation
import CoreHaptics
import UIKit

class HapticsManager {
    static let shared = HapticsManager()
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isHapticsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isHapticsEnabled") }
    }
    
    private var engine: CHHapticEngine?
    
    init() {
        // Default to true
        if UserDefaults.standard.object(forKey: "isHapticsEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "isHapticsEnabled")
        }
        prepareHaptics()
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    func playLightImpact() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func playHeavyImpact() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func playTimeWarning() {
        guard isEnabled, CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playHeavyImpact()
            return
        }
        
        var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

import Foundation
import SwiftUI
import Combine
import AVKit

enum GameState {
    case idle
    case running
    case paused
    case gameOver
}

class ChessClockViewModel: ObservableObject {
    @Published var topPlayer: Player
    @Published var bottomPlayer: Player
    @Published var gameState: GameState = .idle
    @Published var timeControl: TimeControl {
        didSet {
            reset()
            saveCustomTimeControl()
        }
    }
    
    // Configurable styles via UserDefaults/AppStorage
    @AppStorage("activeColorHex") var activeColorHex: String = "#2E6F40" // Green
    @AppStorage("warningColorHex") var warningColorHex: String = "#FF0035" // Red
    
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.chessclock.timer", qos: .userInteractive)
    
    private var lastTickTime: Date?
    
    init() {
        // Determine the initial time control
        let initialTimeControl: TimeControl
        if let savedData = UserDefaults.standard.data(forKey: "customTimeControl"),
           let decoded = try? JSONDecoder().decode(TimeControl.self, from: savedData) {
            initialTimeControl = decoded
        } else {
            initialTimeControl = TimeControl.presets[2] // Blitz (3|0)
        }
        // Assign to property
        self.timeControl = initialTimeControl
        self.topPlayer = Player(id: .top, timeRemaining: initialTimeControl.playerBTime, color: .gray)
        self.bottomPlayer = Player(id: .bottom, timeRemaining: initialTimeControl.playerATime, color: .gray)
        resetColors()
        setupLifecycleObservers()
    }
    
    // MARK: - Game Controls
    
    func tapPlayer(side: PlayerSide) {
        guard gameState != .gameOver else { return }
        
        if gameState == .idle || gameState == .paused {
            // First tap starts the game for the OPPOSITE player
            startGame(activeSide: side == .top ? .bottom : .top)
            SoundManager.shared.playTapSound()
            HapticsManager.shared.playLightImpact()
            return
        }
        
        // If running, tapping active player switches turns
        if side == .top && topPlayer.isActive {
            switchTurn(to: .bottom)
        } else if side == .bottom && bottomPlayer.isActive {
            switchTurn(to: .top)
        }
    }
    
    private func startGame(activeSide: PlayerSide) {
        gameState = .running
        if activeSide == .top {
            topPlayer.isActive = true
            bottomPlayer.isActive = false
        } else {
            bottomPlayer.isActive = true
            topPlayer.isActive = false
        }
        updateColors()
        startTimer()
    }
    
    func pause() {
        guard gameState == .running else { return }
        gameState = .paused
        stopTimer()
        updateColors()
    }
    
    func resume() {
        guard gameState == .paused else {
            if gameState == .idle {
                // Determine whose turn it's supposed to be (White traditionally starts, let's say bottom)
                startGame(activeSide: .bottom)
            }
            return
        }
        gameState = .running
        updateColors()
        startTimer()
    }
    
    func reset() {
        stopTimer()
        gameState = .idle
        topPlayer = Player(id: .top, timeRemaining: timeControl.playerBTime, moves: 0, isActive: false, color: .gray)
        bottomPlayer = Player(id: .bottom, timeRemaining: timeControl.playerATime, moves: 0, isActive: false, color: .gray)
        resetColors()
        warnedAt10 = false
        warnedAt30 = false
    }
    
    private func switchTurn(to side: PlayerSide) {
        // Apply Increment/Delay to the player who just finished their turn
        if timeControl.type == .increment {
            if side == .bottom {
                // Top just finished turn
                topPlayer.timeRemaining += TimeInterval(timeControl.incrementSeconds)
                topPlayer.moves += 1
            } else {
                // Bottom just finished turn
                bottomPlayer.timeRemaining += TimeInterval(timeControl.incrementSeconds)
                bottomPlayer.moves += 1
            }
        } else {
            // Standard / Delay (simple standard mapping for now)
            if side == .bottom {
                topPlayer.moves += 1
            } else {
                bottomPlayer.moves += 1
            }
        }
        
        SoundManager.shared.playTapSound()
        HapticsManager.shared.playLightImpact()
        
        startGame(activeSide: side)
    }
    
    // MARK: - Timer Logic
    
    private func startTimer() {
        stopTimer()
        lastTickTime = Date()
        
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now(), repeating: .milliseconds(50))
        
        timer?.setEventHandler { [weak self] in
            self?.tick()
        }
        
        timer?.resume()
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
        lastTickTime = nil
    }
    
    private func tick() {
        guard let lastTime = lastTickTime else { return }
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTime)
        self.lastTickTime = now
        
        DispatchQueue.main.async {
            self.updateActiveTimer(elapsed: elapsed)
        }
    }
    
    private func updateActiveTimer(elapsed: TimeInterval) {
        if topPlayer.isActive {
            topPlayer.timeRemaining -= elapsed
            if topPlayer.timeRemaining <= 0 {
                topPlayer.timeRemaining = 0
                endGame()
            } else {
                checkWarning(for: .top)
            }
        } else if bottomPlayer.isActive {
            bottomPlayer.timeRemaining -= elapsed
            if bottomPlayer.timeRemaining <= 0 {
                bottomPlayer.timeRemaining = 0
                endGame()
            } else {
                checkWarning(for: .bottom)
            }
        }
        
        // Update UI colors dynamically
        updateColors()
    }
    
    private var warnedAt10 = false
    private var warnedAt30 = false
    
    private func checkWarning(for side: PlayerSide) {
        let remaining = side == .top ? topPlayer.timeRemaining : bottomPlayer.timeRemaining
        
        if remaining <= 10.5 && !warnedAt10 {
            warnedAt10 = true
            SoundManager.shared.playVoiceAlert("10 seconds")
            HapticsManager.shared.playTimeWarning()
        } else if remaining <= 30.5 && remaining > 30.0 && !warnedAt30 {
            warnedAt30 = true
            SoundManager.shared.playVoiceAlert("30 seconds")
        }
        
        // Reset warnings if time went up due to increment
        if remaining > 10.5 { warnedAt10 = false }
        if remaining > 30.5 { warnedAt30 = false }
    }
    
    private func endGame() {
        stopTimer()
        gameState = .gameOver
        topPlayer.isActive = false
        bottomPlayer.isActive = false
        SoundManager.shared.playEndSound()
        HapticsManager.shared.playHeavyImpact()
        updateColors()
    }
    
    // MARK: - Color Management
    
    private func resetColors() {
        topPlayer.color = .gray.opacity(0.3)
        bottomPlayer.color = .gray.opacity(0.3)
    }
    
    private func updateColors() {
        let activeColor = Color(hex: activeColorHex) ?? .green
        let warningColor = Color(hex: warningColorHex) ?? .red
        
        if gameState == .gameOver {
            topPlayer.color = topPlayer.timeRemaining <= 0 ? warningColor : .gray.opacity(0.3)
            bottomPlayer.color = bottomPlayer.timeRemaining <= 0 ? warningColor : .gray.opacity(0.3)
        } else if gameState == .paused || gameState == .idle {
            if topPlayer.isActive {
                topPlayer.color = topPlayer.isWarning ? warningColor.opacity(0.7) : activeColor.opacity(0.7)
                bottomPlayer.color = .gray.opacity(0.3)
            } else if bottomPlayer.isActive {
                bottomPlayer.color = bottomPlayer.isWarning ? warningColor.opacity(0.7) : activeColor.opacity(0.7)
                topPlayer.color = .gray.opacity(0.3)
            } else {
                resetColors()
            }
        } else {
            // Running
            if topPlayer.isActive {
                topPlayer.color = topPlayer.isWarning ? warningColor : activeColor
                bottomPlayer.color = .gray.opacity(0.3)
            } else if bottomPlayer.isActive {
                bottomPlayer.color = bottomPlayer.isWarning ? warningColor : activeColor
                topPlayer.color = .gray.opacity(0.3)
            }
        }
    }
    
    // MARK: - Lifecycle Observer
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.pause()
        }
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] _ in
            self?.pause()
        }
    }
    
    // MARK: - Persistence
    func saveCustomTimeControl() {
        if let encoded = try? JSONEncoder().encode(timeControl) {
            UserDefaults.standard.set(encoded, forKey: "customTimeControl")
        }
    }
}

// Helper for Color Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b: Double
        if hexSanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0

            self.init(red: r, green: g, blue: b)
        } else {
            return nil
        }
    }
    
    func toHex() -> String? {
        // Needs a UI color representation
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

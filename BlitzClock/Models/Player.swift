import Foundation
import SwiftUI

enum PlayerSide: String, Codable {
    case top
    case bottom
}

struct Player: Identifiable, Equatable {
    let id: PlayerSide
    var timeRemaining: TimeInterval
    var moves: Int = 0
    var isActive: Bool = false
    var color: Color
    
    // Timer formatting
    var timeString: String {
        let isNegative = timeRemaining < 0
        let absTime = abs(timeRemaining)
        let minutes = Int(absTime) / 60
        let seconds = Int(absTime) % 60
        
        if minutes >= 1 {
            return String(format: "%@%d:%02d", isNegative ? "-" : "", minutes, seconds)
        } else {
            // Include tenths of a second if less than 1 minute
            let tenths = Int((absTime.truncatingRemainder(dividingBy: 1)) * 10)
            return String(format: "%@%02d.%d", isNegative ? "-" : "", seconds, tenths)
        }
    }
    
    var isWarning: Bool {
        return timeRemaining > 0 && timeRemaining <= 10
    }
}

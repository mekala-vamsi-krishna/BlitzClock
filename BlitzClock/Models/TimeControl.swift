import Foundation

enum TimeControlType: String, Codable, CaseIterable {
    case standard = "Standard"
    case increment = "Increment"
    case delay = "Delay"
}

struct TimeControl: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    
    var usesAsymmetricTime: Bool
    var playerATime: TimeInterval
    var playerBTime: TimeInterval
    
    var incrementSeconds: Int
    var type: TimeControlType
    
    var totalSeconds: TimeInterval {
        return playerATime // Fallback
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, usesAsymmetricTime, playerATime, playerBTime, incrementSeconds, type
        case minutes // For parsing older versions
    }
    
    init(name: String, minutes: Int, incrementSeconds: Int, type: TimeControlType) {
        self.id = UUID()
        self.name = name
        self.usesAsymmetricTime = false
        let time = TimeInterval(minutes * 60)
        self.playerATime = time
        self.playerBTime = time
        self.incrementSeconds = incrementSeconds
        self.type = type
    }
    
    init(name: String, playerAMinutes: Int, playerASeconds: Int, playerBMinutes: Int, playerBSeconds: Int, incrementSeconds: Int, type: TimeControlType) {
        self.id = UUID()
        self.name = name
        self.usesAsymmetricTime = true
        self.playerATime = TimeInterval((playerAMinutes * 60) + playerASeconds)
        self.playerBTime = TimeInterval((playerBMinutes * 60) + playerBSeconds)
        self.incrementSeconds = incrementSeconds
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.incrementSeconds = try container.decode(Int.self, forKey: .incrementSeconds)
        self.type = try container.decode(TimeControlType.self, forKey: .type)
        
        if let minutes = try? container.decode(Int.self, forKey: .minutes) {
            self.usesAsymmetricTime = false
            let time = TimeInterval(minutes * 60)
            self.playerATime = time
            self.playerBTime = time
        } else {
            self.usesAsymmetricTime = try container.decodeIfPresent(Bool.self, forKey: .usesAsymmetricTime) ?? false
            self.playerATime = try container.decode(TimeInterval.self, forKey: .playerATime)
            self.playerBTime = try container.decode(TimeInterval.self, forKey: .playerBTime)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(usesAsymmetricTime, forKey: .usesAsymmetricTime)
        try container.encode(playerATime, forKey: .playerATime)
        try container.encode(playerBTime, forKey: .playerBTime)
        try container.encode(incrementSeconds, forKey: .incrementSeconds)
        try container.encode(type, forKey: .type)
    }
    
    static let presets: [TimeControl] = [
        TimeControl(name: "Bullet", minutes: 1, incrementSeconds: 0, type: .standard),
        TimeControl(name: "Bullet (1|1)", minutes: 1, incrementSeconds: 1, type: .increment),
        TimeControl(name: "Blitz (3|0)", minutes: 3, incrementSeconds: 0, type: .standard),
        TimeControl(name: "Blitz (3|2)", minutes: 3, incrementSeconds: 2, type: .increment),
        TimeControl(name: "Blitz (5|0)", minutes: 5, incrementSeconds: 0, type: .standard),
        TimeControl(name: "Blitz (5|3)", minutes: 5, incrementSeconds: 3, type: .increment),
        TimeControl(name: "Rapid (10|0)", minutes: 10, incrementSeconds: 0, type: .standard),
        TimeControl(name: "Rapid (15|10)", minutes: 15, incrementSeconds: 10, type: .increment),
        TimeControl(name: "Classical (30|0)", minutes: 30, incrementSeconds: 0, type: .standard)
    ]
}

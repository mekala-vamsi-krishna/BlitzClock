import SwiftUI

@main
struct BlitzClockApp: App {
    var body: some Scene {
        WindowGroup {
            ChessClockView()
                .preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

struct PlayerTimerView: View {
    @ObservedObject var viewModel: ChessClockViewModel
    let player: Player
    let invert: Bool
    
    var body: some View {
        ZStack {
            player.color
                .ignoresSafeArea()
            
            VStack {
                Text(player.timeString)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)
                
                Text("Moves: \(player.moves)")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .rotationEffect(.degrees(invert ? 180 : 0))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.tapPlayer(side: player.id)
        }
        .animation(.easeInOut(duration: 0.2), value: player.color)
    }
}

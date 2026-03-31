import SwiftUI

struct ChessClockView: View {
    @StateObject private var viewModel = ChessClockViewModel()
    @State private var showingSettings = false
    @State private var showingPresets = false
    @State private var showingResetAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Player
                PlayerTimerView(viewModel: viewModel, player: viewModel.topPlayer, invert: true)
                    .frame(height: max((geometry.size.height - 80) / 2, 0))
                
                // Control Bar
                ZStack {
                    HStack(spacing: 30) {
                        Button(action: {
                        showingPresets = true
                    }) {
                        VStack {
                            Image(systemName: "timer")
                                .font(.title2)
                            Text(viewModel.timeControl.name)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if viewModel.gameState == .running || viewModel.gameState == .paused {
                        Button(action: {
                            if viewModel.gameState == .running {
                                viewModel.pause()
                            } else {
                                viewModel.resume()
                            }
                        }) {
                            Image(systemName: viewModel.gameState == .running ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.primary)
                        }
                    } else if viewModel.gameState == .gameOver {
                        Text("Game Over")
                            .font(.headline)
                            .foregroundColor(.red)
                    } else {
                        // Invisible placeholder for idle state center alignment
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.clear)
                    }
                    
                    Spacer()
                    
                    // Reset or Settings
                    if viewModel.gameState == .idle {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                        }
                        .foregroundColor(.primary)
                    } else {
                        Button(action: {
                            viewModel.pause()
                            showingResetAlert = true
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title2)
                        }
                        .foregroundColor(.primary)
                    }
                }
                }
                .frame(height: 80)
                .padding(.horizontal, 30)
                .background(Color(UIColor.systemBackground))
                
                // Bottom Player
                PlayerTimerView(viewModel: viewModel, player: viewModel.bottomPlayer, invert: false)
                    .frame(height: max((geometry.size.height - 80) / 2, 0))
            }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingPresets) {
            if viewModel.gameState == .idle {
                PresetPickerView(viewModel: viewModel)
            }
        }
        .alert("Reset Game?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {
                // Resume game or stay paused based on user preference
                // Usually kept paused, waiting for play button or tap
            }
            Button("Reset", role: .destructive) {
                viewModel.reset()
            }
        } message: {
            Text("Are you sure you want to reset the current game?")
        }
        .onAppear {
            // Ensure no screen dimming while playing
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

// Preview Provider
struct ChessClockView_Previews: PreviewProvider {
    static var previews: some View {
        ChessClockView()
            .preferredColorScheme(.dark)
    }
}

import SwiftUI

struct ChessClockView: View {
    @StateObject private var viewModel = ChessClockViewModel()
    @State private var showingSettings = false
    @State private var showingPresets = false
    @State private var showingResetAlert = false
    @State private var showingTimeAdjustment = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Player
                PlayerTimerView(viewModel: viewModel, player: viewModel.topPlayer, invert: true)
                    .frame(height: max((geometry.size.height - 80) / 2, 0))
                
                // Control Bar
                ZStack {
                    HStack(spacing: 30) {
                        // Left Button
                        if viewModel.gameState == .idle {

                            Button {
                                showingPresets = true
                            } label: {
                                VStack {
                                    Image(systemName: "timer")
                                        .font(.title2)

                                    Text(viewModel.timeControl.name)
                                        .font(.caption)
                                }
                            }

                        } else if viewModel.gameState == .running || viewModel.gameState == .paused {

                            Button {
                                if viewModel.gameState == .running {
                                    viewModel.pause()
                                }

                                showingTimeAdjustment = true
                            } label: {
                                VStack {
                                    Image(systemName: "plusminus.circle.fill")
                                        .font(.title2)

                                    Text("Adjust")
                                        .font(.caption)
                                }
                            }

                        } else {

                            // Keep spacing when game is over
                            VStack {
                                Image(systemName: "plusminus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.clear)
                            }

                        }
                        
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
                        
                        // Reset and +/- and Settings
                        HStack(spacing: 18) {
                            
                            if viewModel.gameState == .idle {
                                
                                Button {
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                }
                                
                            } else {
                                
                                Button {
                                    viewModel.pause()
                                    showingResetAlert = true
                                } label: {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.title2)
                                }
                                
                            }
                            
                        }
                        .foregroundColor(.primary)
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
        .sheet(isPresented: $showingTimeAdjustment) {
            ArbiterTimeAdjustmentView(viewModel: viewModel)
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

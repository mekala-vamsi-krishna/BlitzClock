//
//  ArbiterTimeAdjustmentView.swift
//  BlitzClock
//
//  Created by Mekala Vamsi Krishna on 7/3/26.
//

import SwiftUI

struct ArbiterTimeAdjustmentView: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChessClockViewModel
    
    @AppStorage("activeColorHex")
    private var activeColorHex: String = "#2E6F40"
    
    private var activeColor: Color {
        Color(hex: activeColorHex) ?? .green
    }
    
    private let values: [(String, TimeInterval)] = [
        ("5s", 5),
        ("30s", 30),
        ("1m", 60),
        ("5m", 300)
    ]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    playerSection(
                        title: "Top Player",
                        side: .top,
                        remaining: viewModel.topPlayer.timeRemaining
                    )
                    
                    Divider()
                    
                    playerSection(
                        title: "Bottom Player",
                        side: .bottom,
                        remaining: viewModel.bottomPlayer.timeRemaining
                    )
                }
                .padding()
            }
            .navigationTitle("Adjust Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func playerSection(
        title: String,
        side: PlayerSide,
        remaining: TimeInterval
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 18) {
            
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(timeString(from: remaining))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(activeColor)
            }
            
            Text("Add Time")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(values, id: \.0) { value in
                    addButton(
                        title: "+\(value.0)",
                        action: {
                            viewModel.addTime(to: side, seconds: value.1)
                        }
                    )
                }
            }
            
            Text("Subtract Time")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(values, id: \.0) { value in
                    subtractButton(
                        title: "-\(value.0)",
                        action: {
                            viewModel.subtractTime(from: side, seconds: value.1)
                        }
                    )
                }
            }
        }
    }
    
    private func addButton(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .foregroundStyle(.white)
                .background(
                    Capsule()
                        .fill(activeColor)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func subtractButton(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .foregroundStyle(activeColor)
                .background(
                    Capsule()
                        .stroke(activeColor, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let totalSeconds = max(Int(interval), 0)
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%01d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ArbiterTimeAdjustmentView(viewModel: ChessClockViewModel())
}

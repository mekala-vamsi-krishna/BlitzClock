import SwiftUI

struct PresetPickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ChessClockViewModel
    
    @State private var showingCustom = false
    @State private var useAsymmetric = false
    
    @State private var customMinutesA = 5
    @State private var customSecondsA = 0
    @State private var customMinutesB = 5
    @State private var customSecondsB = 0
    
    @State private var customIncrement = 0
    @State private var customType: TimeControlType = .standard
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Presets")) {
                    ForEach(TimeControl.presets) { preset in
                        Button(action: {
                            viewModel.timeControl = preset
                            dismiss()
                        }) {
                            HStack {
                                Text(preset.name)
                                Spacer()
                                if viewModel.timeControl.name == preset.name {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Custom")) {
                    Button("Create Custom Timer...") {
                        showingCustom = true
                    }
                }
            }
            .navigationTitle("Time Control")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showingCustom) {
                let isValid = useAsymmetric ?
                    (customMinutesA > 0 || customSecondsA > 0) && (customMinutesB > 0 || customSecondsB > 0) :
                    (customMinutesA > 0 || customSecondsA > 0)
                
                NavigationView {
                    Form {
                        Section(header: Text("Mode")) {
                            Toggle("Use Different Time For Each Player", isOn: $useAsymmetric.animation())
                        }
                        
                        if useAsymmetric {
                            Section(header: Text("Player A Time (Bottom)")) {
                                Stepper(value: $customMinutesA, in: 0...120) {
                                    Text("\(customMinutesA) Minutes")
                                }
                                Stepper(value: $customSecondsA, in: 0...59) {
                                    Text("\(customSecondsA) Seconds")
                                }
                            }
                            Section(header: Text("Player B Time (Top)")) {
                                Stepper(value: $customMinutesB, in: 0...120) {
                                    Text("\(customMinutesB) Minutes")
                                }
                                Stepper(value: $customSecondsB, in: 0...59) {
                                    Text("\(customSecondsB) Seconds")
                                }
                            }
                        } else {
                            Section(header: Text("Time")) {
                                Stepper(value: $customMinutesA, in: 0...120) {
                                    Text("\(customMinutesA) Minutes")
                                }
                                Stepper(value: $customSecondsA, in: 0...59) {
                                    Text("\(customSecondsA) Seconds")
                                }
                            }
                        }
                        
                        Section(header: Text("Type")) {
                            Picker("Type", selection: $customType) {
                                ForEach(TimeControlType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        if customType != .standard {
                            Section(header: Text(customType == .increment ? "Increment" : "Delay")) {
                                Stepper(value: $customIncrement, in: 0...60) {
                                    Text("\(customIncrement) Seconds")
                                }
                            }
                        }
                    }
                    .navigationTitle("Custom Timer")
                    .navigationBarItems(leading: Button("Cancel") {
                        showingCustom = false
                    }, trailing: Button("Save") {
                        let custom = TimeControl(
                            name: useAsymmetric ? "Handicap (\(customMinutesA)m \(customSecondsA)s | \(customMinutesB)m \(customSecondsB)s)" : "Custom (\(customMinutesA)m:(\(customSecondsA))s |+\(customIncrement)s)",
                            playerAMinutes: customMinutesA,
                            playerASeconds: customSecondsA,
                            playerBMinutes: useAsymmetric ? customMinutesB : customMinutesA,
                            playerBSeconds: useAsymmetric ? customSecondsB : customSecondsA,
                            incrementSeconds: customType == .standard ? 0 : customIncrement,
                            type: customType
                        )
                        var finalCustom = custom
                        finalCustom.usesAsymmetricTime = useAsymmetric
                        
                        viewModel.timeControl = finalCustom
                        showingCustom = false
                        dismiss()
                    }
                    .disabled(!isValid))
                }
            }
        }
    }
}

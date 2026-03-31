import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ChessClockViewModel
    
    @AppStorage("isSoundEnabled") private var isSoundEnabled = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    
    @AppStorage("activeColorHex") private var activeColorHex: String = "#00FF00"
    @AppStorage("warningColorHex") private var warningColorHex: String = "#FF0000"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Settings")) {
                    Toggle("Sound", isOn: $isSoundEnabled)
                    Toggle("Haptics", isOn: $isHapticsEnabled)
                }
                
                Section(header: Text("Theme Color Defaults")) {
                    ColorPicker("Active Color", selection: Binding(get: {
                        Color(hex: activeColorHex) ?? .green
                    }, set: { newValue in
                        if let hex = newValue.toHex() {
                            activeColorHex = hex
                            viewModel.activeColorHex = hex
                        }
                    }))
                    
                    ColorPicker("Warning Color", selection: Binding(get: {
                        Color(hex: warningColorHex) ?? .red
                    }, set: { newValue in
                        if let hex = newValue.toHex() {
                            warningColorHex = hex
                            viewModel.warningColorHex = hex
                        }
                    }))
                    
                    Button("Reset Colors") {
                        activeColorHex = "#00FF00"
                        warningColorHex = "#FF0000"
                        viewModel.activeColorHex = "#00FF00"
                        viewModel.warningColorHex = "#FF0000"
                    }
                    .foregroundColor(.red)
                }
                
                Section(footer: Text("Note: Mute disables both tap sounds and voice alerts.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

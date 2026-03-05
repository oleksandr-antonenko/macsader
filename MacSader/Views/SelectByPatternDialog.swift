import SwiftUI

struct SelectByPatternDialog: View {
    @Binding var isPresented: Bool
    @Binding var pattern: String
    let isDeselect: Bool
    let onConfirm: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isDeselect ? "minus.circle" : "plus.circle")
                    .foregroundColor(.accentColor)
                Text(isDeselect ? "Deselect by Pattern" : "Select by Pattern")
                    .font(.headline)
                Spacer()
            }

            Text("Use * and ? wildcards (e.g., *.swift, test_?.txt)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Pattern", text: $pattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .onSubmit {
                    if !pattern.isEmpty {
                        onConfirm(pattern)
                        isPresented = false
                    }
                }

            HStack {
                // Quick pattern buttons
                ForEach(["*.*", "*.swift", "*.txt", "*.json"], id: \.self) { preset in
                    Button(preset) {
                        pattern = preset
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(isDeselect ? "Deselect" : "Select") {
                    if !pattern.isEmpty {
                        onConfirm(pattern)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pattern.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}

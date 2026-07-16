import SwiftUI

/// One unified sheet enum per screen — stacking multiple `.sheet(item:)` or
/// `.alert(...)` modifiers on the same view is a known SwiftUI bug (only the
/// last-declared one reliably fires). Route every sheet through this enum.
enum PresetSheetMode: Identifiable {
    case add
    case edit(MeetingPreset)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let preset): return preset.id.uuidString
        case .paywall: return "paywall"
        }
    }
}

struct PresetEditSheet: View {
    let mode: PresetSheetMode
    let onSave: (String, Int, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var attendeeCount: Int
    @State private var hourlyRate: Double
    @State private var hourlyRateText: String

    init(mode: PresetSheetMode, onSave: @escaping (String, Int, Double) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .edit(let preset):
            _name = State(initialValue: preset.name)
            _attendeeCount = State(initialValue: preset.attendeeCount)
            _hourlyRate = State(initialValue: preset.hourlyRate)
            _hourlyRateText = State(initialValue: String(format: "%.0f", preset.hourlyRate))
        default:
            _name = State(initialValue: "")
            _attendeeCount = State(initialValue: 4)
            _hourlyRate = State(initialValue: 75)
            _hourlyRateText = State(initialValue: "75")
        }
    }

    private var title: String {
        if case .edit = mode { return "Edit Meeting" }
        return "New Meeting"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meeting") {
                    TextField("Name (e.g. Standup)", text: $name)
                        .accessibilityIdentifier("presetNameField")

                    Stepper("Attendees: \(attendeeCount)", value: $attendeeCount, in: 1...100)
                        .accessibilityIdentifier("presetAttendeeStepper")
                }
                Section("Average hourly rate per attendee") {
                    HStack {
                        Text("$")
                        TextField("75", text: $hourlyRateText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("presetRateField")
                            .onChange(of: hourlyRateText) { _, newValue in
                                hourlyRate = Double(newValue) ?? 0
                            }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, attendeeCount, hourlyRate)
                        dismiss()
                    }
                    .accessibilityIdentifier("presetSaveButton")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}

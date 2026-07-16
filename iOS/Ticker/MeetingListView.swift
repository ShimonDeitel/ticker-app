import SwiftUI

struct MeetingListView: View {
    @EnvironmentObject private var store: TickerStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: PresetSheetMode?
    @State private var deletingPreset: MeetingPreset?
    @State private var showingSummary: MeetingRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                TKTheme.backdrop.ignoresSafeArea()

                if store.isRunning, let preset = store.activePreset {
                    LiveCounterView(preset: preset)
                } else {
                    idleList
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    PresetEditSheet(mode: mode) { name, attendees, rate in
                        switch mode {
                        case .add:
                            store.addPreset(name: name, attendeeCount: attendees, hourlyRate: rate, isPro: purchases.isPro)
                        case .edit(let preset):
                            store.updatePreset(preset.id, name: name, attendeeCount: attendees, hourlyRate: rate)
                        case .paywall:
                            break
                        }
                    }
                }
            }
            .confirmationDialog(
                "Remove \(deletingPreset?.name ?? "Meeting")?",
                isPresented: Binding(
                    get: { deletingPreset != nil },
                    set: { if !$0 { deletingPreset = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deletingPreset {
                        store.deletePreset(deletingPreset.id)
                    }
                    deletingPreset = nil
                }
                Button("Cancel", role: .cancel) { deletingPreset = nil }
            }
            .alert("Meeting Ended", isPresented: Binding(
                get: { showingSummary != nil },
                set: { if !$0 { showingSummary = nil } }
            )) {
                Button("OK") { showingSummary = nil }
            } message: {
                if let record = showingSummary {
                    Text("\(record.name) cost \(formatDollars(record.totalCost)) over \(formatDuration(record.durationSeconds)).")
                }
            }
        }
    }

    private var idleList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Ticker")
                        .font(TKTheme.titleFont)
                        .foregroundStyle(TKTheme.ink)
                    Spacer()
                    Button {
                        if store.canAddPreset(isPro: purchases.isPro) {
                            sheetMode = .add
                        } else {
                            sheetMode = .paywall
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(TKTheme.coral)
                    }
                    .accessibilityIdentifier("addPresetButton")
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                if store.presets.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.presets) { preset in
                            PresetRow(preset: preset) {
                                Haptics.medium()
                                store.start(preset: preset)
                            } onEdit: {
                                sheetMode = .edit(preset)
                            } onDelete: {
                                Haptics.warning()
                                deletingPreset = preset
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    if !purchases.isPro {
                        Text("Free plan: \(store.presets.count)/\(TickerStore.freePresetLimit) meetings saved")
                            .font(.caption)
                            .foregroundStyle(TKTheme.inkFaded)
                            .padding(.horizontal, 18)
                    }
                }

                if !store.history.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Meetings")
                            .font(TKTheme.headlineFont)
                            .foregroundStyle(TKTheme.ink)
                            .padding(.horizontal, 18)
                        ForEach(store.history.prefix(5)) { record in
                            HStack {
                                Text(record.name)
                                    .foregroundStyle(TKTheme.ink)
                                Spacer()
                                Text(formatDollars(record.totalCost))
                                    .foregroundStyle(TKTheme.coral)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 34))
                .foregroundStyle(TKTheme.inkFaded)
            Text("No meetings yet. Tap + to set up your first one.")
                .font(.subheadline)
                .foregroundStyle(TKTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func formatDollars(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

private struct PresetRow: View {
    let preset: MeetingPreset
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(TKTheme.surfaceRaised)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(TKTheme.coral)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TKTheme.ink)
                Text("\(preset.attendeeCount) people · $\(Int(preset.hourlyRate))/hr avg")
                    .font(.caption)
                    .foregroundStyle(TKTheme.inkFaded)
            }

            Spacer()

            Button(action: onStart) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(TKTheme.backdrop)
                    .padding(10)
                    .background(Circle().fill(TKTheme.coral))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("startButton_\(preset.name)")

            Menu {
                Button(action: onEdit) {
                    Label("Edit Meeting", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Remove Meeting", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(TKTheme.inkFaded)
                    .padding(8)
            }
            .accessibilityIdentifier("presetMenu_\(preset.name)")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TKTheme.surface)
        )
    }
}

/// The quirky signature feature: a live, ticking dollar counter that fills
/// the whole screen while a meeting is running, digits rolling in real time,
/// with a subtle haptic buzz firing on every whole-dollar crossing.
private struct LiveCounterView: View {
    @EnvironmentObject private var store: TickerStore
    let preset: MeetingPreset
    @State private var showingStopConfirm = false

    private var minutes: Int { Int(store.elapsedSeconds) / 60 }
    private var seconds: Int { Int(store.elapsedSeconds) % 60 }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(preset.name)
                .font(TKTheme.headlineFont)
                .foregroundStyle(TKTheme.inkFaded)

            Text(String(format: "$%.2f", store.currentCost))
                .font(TKTheme.displayFont)
                .foregroundStyle(TKTheme.coralBright)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: store.currentCost)
                .accessibilityIdentifier("liveCostLabel")

            Text(String(format: "%02d:%02d elapsed", minutes, seconds))
                .font(.subheadline)
                .foregroundStyle(TKTheme.inkFaded)

            Text("\(preset.attendeeCount) people burning $\(Int(preset.costPerSecond * 60))/min")
                .font(.caption)
                .foregroundStyle(TKTheme.mint)

            Spacer()

            Button {
                showingStopConfirm = true
            } label: {
                Text("Stop Ticking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TKTheme.coral)
                    .foregroundStyle(TKTheme.backdrop)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .accessibilityIdentifier("stopMeetingButton")
            .padding(.bottom, 40)
        }
        .confirmationDialog("End this meeting?", isPresented: $showingStopConfirm, titleVisibility: .visible) {
            Button("End Meeting", role: .destructive) {
                Haptics.success()
                store.stop()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    MeetingListView()
        .environmentObject(TickerStore())
        .environmentObject(PurchaseManager())
}

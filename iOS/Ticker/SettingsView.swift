import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TickerStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("ticker_haptics_enabled") private var hapticsEnabled: Bool = true

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: PresetSheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                TKTheme.backdrop.ignoresSafeArea()

                Form {
                    Section {
                        if purchases.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(TKTheme.coral)
                                Text("Ticker Pro unlocked")
                                    .foregroundStyle(TKTheme.ink)
                            }
                        } else {
                            Button {
                                sheetMode = .paywall
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill").foregroundStyle(TKTheme.coral)
                                    Text("Unlock Ticker Pro")
                                        .foregroundStyle(TKTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(TKTheme.inkFaded)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(TKTheme.surface)

                    Section("Meetings") {
                        ForEach(store.presets) { preset in
                            HStack {
                                Text(preset.name).foregroundStyle(TKTheme.ink)
                                Spacer()
                                Text("$\(Int(preset.hourlyRate))/hr")
                                    .font(.caption)
                                    .foregroundStyle(TKTheme.inkFaded)
                                Button {
                                    sheetMode = .edit(preset)
                                } label: {
                                    Image(systemName: "pencil.circle").foregroundStyle(TKTheme.inkFaded)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("editPreset_\(preset.name)")
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deletePreset(preset.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("deletePresetSwipe_\(preset.name)")
                            }
                        }
                        .onMove { source, destination in
                            store.movePresets(from: source, to: destination)
                        }

                        Button {
                            if store.canAddPreset(isPro: purchases.isPro) {
                                sheetMode = .add
                            } else {
                                sheetMode = .paywall
                            }
                        } label: {
                            Label("Add Meeting", systemImage: "plus.circle")
                                .foregroundStyle(TKTheme.coral)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsAddPresetButton")

                        if !purchases.isPro {
                            Text("\(store.presets.count)/\(TickerStore.freePresetLimit) free meetings used")
                                .font(.caption)
                                .foregroundStyle(TKTheme.inkFaded)
                        }
                    }
                    .listRowBackground(TKTheme.surface)

                    Section("Preferences") {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap.fill")
                                .foregroundStyle(TKTheme.ink)
                        }
                        .tint(TKTheme.coral)
                        .accessibilityIdentifier("hapticsToggle")
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(TKTheme.ink)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(TKTheme.surface)

                    Section("About") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/ticker-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundStyle(TKTheme.ink)
                        }
                        Link(destination: URL(string: "https://shimondeitel.github.io/ticker-site/support.html")!) {
                            Label("Support", systemImage: "questionmark.circle")
                                .foregroundStyle(TKTheme.ink)
                        }
                        Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundStyle(TKTheme.ink)
                        }
                        HStack {
                            Text("Version").foregroundStyle(TKTheme.ink)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(TKTheme.inkFaded)
                        }
                    }
                    .listRowBackground(TKTheme.surface)

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(TKTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(TKTheme.backdrop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { EditButton() }
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
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every saved meeting and history entry. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    SettingsView()
        .environmentObject(TickerStore())
        .environmentObject(PurchaseManager())
}

import Foundation
import Combine

@MainActor
final class TickerStore: ObservableObject {
    @Published private(set) var presets: [MeetingPreset] = []
    @Published private(set) var history: [MeetingRecord] = []

    // Live meeting state.
    @Published private(set) var isRunning = false
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var currentCost: Double = 0
    @Published private(set) var lastMilestoneDollar: Int = 0
    @Published var activePreset: MeetingPreset?

    static let freePresetLimit = 3

    private let fileURL: URL
    private var timer: AnyCancellable?
    private var startDate: Date?

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("ticker_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if presets.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        presets = [
            MeetingPreset(name: "Standup", attendeeCount: 6, hourlyRate: 85),
            MeetingPreset(name: "Exec Sync", attendeeCount: 4, hourlyRate: 220)
        ]
        save()
    }

    func canAddPreset(isPro: Bool) -> Bool {
        isPro || presets.count < Self.freePresetLimit
    }

    @discardableResult
    func addPreset(name: String, attendeeCount: Int, hourlyRate: Double, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddPreset(isPro: isPro) else { return false }
        presets.append(MeetingPreset(name: trimmed, attendeeCount: max(1, attendeeCount), hourlyRate: max(0, hourlyRate)))
        save()
        return true
    }

    func updatePreset(_ id: UUID, name: String, attendeeCount: Int, hourlyRate: Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = presets.firstIndex(where: { $0.id == id }) else { return }
        presets[idx].name = trimmed
        presets[idx].attendeeCount = max(1, attendeeCount)
        presets[idx].hourlyRate = max(0, hourlyRate)
        save()
    }

    func deletePreset(_ id: UUID) {
        presets.removeAll { $0.id == id }
        save()
    }

    func movePresets(from source: IndexSet, to destination: Int) {
        presets.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func deleteAllData() {
        presets = []
        history = []
        seedDefaults()
    }

    // MARK: - Live counter

    /// The quirky signature feature: a real-time running-dollar counter for
    /// the meeting in progress, updating on a sub-second tick so the digits
    /// visibly roll, with a distinct haptic buzz fired every time the total
    /// crosses a whole-dollar milestone (a literal "cha-ching" cadence).
    func start(preset: MeetingPreset) {
        activePreset = preset
        elapsedSeconds = 0
        currentCost = 0
        lastMilestoneDollar = 0
        startDate = Date()
        isRunning = true
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard let startDate, let preset = activePreset else { return }
        elapsedSeconds = Date().timeIntervalSince(startDate)
        currentCost = elapsedSeconds * preset.costPerSecond
        let wholeDollar = Int(currentCost)
        if wholeDollar > lastMilestoneDollar {
            lastMilestoneDollar = wholeDollar
            Haptics.light()
        }
    }

    @discardableResult
    func stop() -> MeetingRecord? {
        guard let preset = activePreset else { return nil }
        timer?.cancel()
        timer = nil
        isRunning = false
        let record = MeetingRecord(
            name: preset.name,
            attendeeCount: preset.attendeeCount,
            hourlyRate: preset.hourlyRate,
            durationSeconds: elapsedSeconds,
            totalCost: currentCost
        )
        history.insert(record, at: 0)
        save()
        activePreset = nil
        return record
    }

    func discardRun() {
        timer?.cancel()
        timer = nil
        isRunning = false
        activePreset = nil
        elapsedSeconds = 0
        currentCost = 0
    }

    func deleteHistoryRecord(_ id: UUID) {
        history.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var presets: [MeetingPreset]
        var history: [MeetingRecord]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            presets = decoded.presets
            history = decoded.history
        }
    }

    private func save() {
        let snapshot = Snapshot(presets: presets, history: history)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

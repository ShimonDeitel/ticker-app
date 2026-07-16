import XCTest
@testable import Ticker

final class TickerTests: XCTestCase {
    func testCostPerSecondCalculation() {
        let preset = MeetingPreset(name: "Test", attendeeCount: 4, hourlyRate: 90)
        // 4 people * $90/hr = $360/hr = $0.1 per second
        XCTAssertEqual(preset.costPerSecond, 0.1, accuracy: 0.0001)
    }

    func testCostPerSecondScalesWithAttendees() {
        let small = MeetingPreset(name: "A", attendeeCount: 2, hourlyRate: 100)
        let large = MeetingPreset(name: "B", attendeeCount: 8, hourlyRate: 100)
        XCTAssertEqual(large.costPerSecond, small.costPerSecond * 4, accuracy: 0.0001)
    }

    @MainActor
    func testStoreAddPresetRespectsFreeLimit() {
        let store = TickerStore()
        for preset in store.presets { store.deletePreset(preset.id) }
        XCTAssertTrue(store.addPreset(name: "A", attendeeCount: 4, hourlyRate: 75, isPro: false))
        XCTAssertTrue(store.addPreset(name: "B", attendeeCount: 4, hourlyRate: 75, isPro: false))
        XCTAssertTrue(store.addPreset(name: "C", attendeeCount: 4, hourlyRate: 75, isPro: false))
        XCTAssertFalse(store.addPreset(name: "D", attendeeCount: 4, hourlyRate: 75, isPro: false))
        XCTAssertTrue(store.addPreset(name: "D", attendeeCount: 4, hourlyRate: 75, isPro: true))
    }

    @MainActor
    func testStartAndStopProducesHistoryRecord() {
        let store = TickerStore()
        for preset in store.presets { store.deletePreset(preset.id) }
        store.addPreset(name: "Sync", attendeeCount: 3, hourlyRate: 60, isPro: false)
        let preset = store.presets[0]
        store.start(preset: preset)
        XCTAssertTrue(store.isRunning)
        let record = store.stop()
        XCTAssertNotNil(record)
        XCTAssertFalse(store.isRunning)
        XCTAssertEqual(store.history.first?.id, record?.id)
    }

    @MainActor
    func testDiscardRunDoesNotSaveHistory() {
        let store = TickerStore()
        for preset in store.presets { store.deletePreset(preset.id) }
        store.addPreset(name: "Sync", attendeeCount: 3, hourlyRate: 60, isPro: false)
        let preset = store.presets[0]
        let beforeCount = store.history.count
        store.start(preset: preset)
        store.discardRun()
        XCTAssertFalse(store.isRunning)
        XCTAssertEqual(store.history.count, beforeCount)
    }

    @MainActor
    func testUpdatePresetChangesRate() {
        let store = TickerStore()
        for preset in store.presets { store.deletePreset(preset.id) }
        store.addPreset(name: "Sync", attendeeCount: 3, hourlyRate: 60, isPro: false)
        let preset = store.presets[0]
        store.updatePreset(preset.id, name: "Renamed", attendeeCount: 5, hourlyRate: 100)
        XCTAssertEqual(store.presets[0].name, "Renamed")
        XCTAssertEqual(store.presets[0].attendeeCount, 5)
        XCTAssertEqual(store.presets[0].hourlyRate, 100)
    }

    @MainActor
    func testDeletePresetRemovesIt() {
        let store = TickerStore()
        for preset in store.presets { store.deletePreset(preset.id) }
        store.addPreset(name: "Sync", attendeeCount: 3, hourlyRate: 60, isPro: false)
        let preset = store.presets[0]
        store.deletePreset(preset.id)
        XCTAssertTrue(store.presets.isEmpty)
    }
}

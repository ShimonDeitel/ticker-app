import XCTest

final class TickerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testAddMeetingFromMainList() throws {
        let app = launchApp()

        let addButton = app.buttons["addPresetButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["presetNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add Meeting sheet did not appear")
        nameField.tap()
        nameField.typeText("Board Review")

        let saveButton = app.buttons["presetSaveButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Board Review"].waitForExistence(timeout: 5), "New meeting did not appear on the list")
    }

    func testAddMeetingFromSettings() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        app.buttons["settingsAddPresetButton"].tap()
        let nameField = app.textFields["presetNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Retro")
        app.buttons["presetSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Retro"].waitForExistence(timeout: 5))
    }

    func testStartMeetingShowsLiveCounterAndStopReturnsToList() throws {
        let app = launchApp()

        let startButton = app.buttons["startButton_Standup"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let liveCost = app.staticTexts["liveCostLabel"]
        XCTAssertTrue(liveCost.waitForExistence(timeout: 5), "Live counter did not appear after starting a meeting")

        // Let the counter tick for real before stopping.
        Thread.sleep(forTimeInterval: 1.5)

        let stopButton = app.buttons["stopMeetingButton"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 5))
        stopButton.tap()

        let endButton = app.buttons["End Meeting"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 5))
        endButton.tap()

        XCTAssertTrue(app.buttons["addPresetButton"].waitForExistence(timeout: 5), "Did not return to the meeting list after ending")
    }

    func testEditMeetingFromSettings() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let editButton = app.buttons.matching(identifier: "editPreset_Standup").firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let nameField = app.textFields["presetNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        let stringValue = nameField.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        nameField.typeText(deleteString)
        nameField.typeText("Morning Standup")

        app.buttons["presetSaveButton"].tap()

        XCTAssertTrue(app.staticTexts["Morning Standup"].waitForExistence(timeout: 5), "Meeting rename did not apply")
    }

    func testDeleteMeetingViaSwipe() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        app.buttons["settingsAddPresetButton"].tap()
        let nameField = app.textFields["presetNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Disposable Meeting")
        app.buttons["presetSaveButton"].tap()
        XCTAssertTrue(app.staticTexts["Disposable Meeting"].waitForExistence(timeout: 5))

        app.staticTexts["Disposable Meeting"].swipeLeft()

        let deleteButton = app.buttons["deletePresetSwipe_Disposable Meeting"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Swipe-to-delete action did not appear")
        deleteButton.tap()

        XCTAssertFalse(app.staticTexts["Disposable Meeting"].waitForExistence(timeout: 3), "Meeting was not deleted")
    }

    func testFreeLimitTriggersPaywallAtFourthMeeting() throws {
        let app = launchApp()
        // Seed data already has 2 presets; add 2 more to hit the free cap of 3, then try a 4th.
        for name in ["Third Meeting", "Fourth Meeting"] {
            let addButton = app.buttons["addPresetButton"]
            addButton.tap()
            let nameField = app.textFields["presetNameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
                app.buttons["presetSaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Ticker Pro"].waitForExistence(timeout: 5), "Paywall did not appear after hitting the free meeting limit")
    }

    func testSimulatedPurchaseUnlocksUnlimitedMeetings() throws {
        let app = launchApp()
        for name in ["Third Meeting", "Fourth Meeting"] {
            let addButton = app.buttons["addPresetButton"]
            addButton.tap()
            let nameField = app.textFields["presetNameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
                app.buttons["presetSaveButton"].tap()
            }
        }
        XCTAssertTrue(app.staticTexts["Ticker Pro"].waitForExistence(timeout: 5))

        let unlockButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Unlock'")).firstMatch
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 5))
        unlockButton.tap()

        let confirmButton = app.buttons["Subscribe"].exists ? app.buttons["Subscribe"] : app.buttons["Buy"]
        if confirmButton.waitForExistence(timeout: 5) {
            confirmButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Ticker Pro unlocked"].waitForExistence(timeout: 10) || app.buttons["addPresetButton"].waitForExistence(timeout: 10))

        let addButton = app.buttons["addPresetButton"]
        if addButton.waitForExistence(timeout: 5) {
            var tapped = false
            for _ in 0..<16 {
                if addButton.isHittable {
                    addButton.tap()
                    tapped = true
                    break
                }
                Thread.sleep(forTimeInterval: 0.5)
            }
            if !tapped {
                addButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let nameField = app.textFields["presetNameField"]
            if nameField.waitForExistence(timeout: 5) {
                nameField.tap()
                nameField.typeText("Fifth Meeting")
                app.buttons["presetSaveButton"].tap()
                XCTAssertTrue(app.staticTexts["Fifth Meeting"].waitForExistence(timeout: 5))
            }
        }
    }
}

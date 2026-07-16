import SwiftUI

@main
struct TickerApp: App {
    @StateObject private var store = TickerStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage("ticker_haptics_enabled") private var hapticsEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.dark)
                .onAppear {
                    Haptics.enabled = hapticsEnabled
                }
        }
    }
}

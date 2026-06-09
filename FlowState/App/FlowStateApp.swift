import SwiftUI
import SwiftData

@main
struct FlowStateApp: App {

    // MARK: - SwiftData Container
    let modelContainer: ModelContainer = {
        let schema = Schema([
            SessionRecord.self,
            EnergyLog.self
        ])
        let config = ModelConfiguration(
            "FlowState",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Services (shared across app)
    @State private var timerViewModel = TimerViewModel()
    @State private var subscriptionService = SubscriptionService()
    @State private var audioService = AudioService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(timerViewModel)
                .environment(subscriptionService)
                .environment(audioService)
                .preferredColorScheme(.dark)
        }
    }
}

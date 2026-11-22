import SwiftUI
import SwiftData

@main
struct PawprintDaysApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let container: ModelContainer
    @State private var coordinator: GameCoordinator

    init() {
        let schema = Schema([
            DiaryDayRecord.self,
            AnchorSiteRecord.self,
            EncounterLog.self,
            PetResidentState.self,
            HomeSpotPlacement.self,
            TeachingIntention.self,
            WalletAndCurioLedger.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [config])
            self.container = modelContainer
            self._coordinator = State(initialValue: GameCoordinator(modelContext: modelContainer.mainContext))
        } catch {
            fatalError("Failed to initialize Pawprint Days SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootStageView(coordinator: coordinator)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        coordinator.handleAppBecameActive()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    coordinator.handleAppBecameActive()
                }
        }
        .modelContainer(container)
    }
}

import SwiftUI
import SwiftData

@main
struct PawprintDaysApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let container: ModelContainer
    @State private var coordinator: GameCoordinator

    init() {
        let schema = Schema(versionedSchema: PawprintSchemaV2.self)
        let (resolvedContainer, recoveryWhisper) = Self.makeResilientContainer(schema: schema)
        self.container = resolvedContainer
        let gameCoordinator = GameCoordinator(modelContext: resolvedContainer.mainContext)
        if let recoveryWhisper {
            gameCoordinator.showWhisper(recoveryWhisper)
        }
        self._coordinator = State(initialValue: gameCoordinator)
    }

    private static func makeResilientContainer(schema: Schema) -> (ModelContainer, String?) {
        let persistentConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            return (container, nil)
        }

        // Safe recovery: archive unreadable store files rather than crashing on startup.
        let storeURL = persistentConfig.url
        let fm = FileManager.default
        if fm.fileExists(atPath: storeURL.path) {
            let stamp = Int(Date().timeIntervalSince1970)
            let backupBase = storeURL.deletingPathExtension().appendingPathExtension("backup-\(stamp).store")
            for suffix in ["", "-wal", "-shm"] {
                let src = URL(fileURLWithPath: storeURL.path + suffix)
                let dst = URL(fileURLWithPath: backupBase.path + suffix)
                if fm.fileExists(atPath: src.path) {
                    try? fm.moveItem(at: src, to: dst)
                }
            }
        }
        if let recovered = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            return (recovered, "資料庫已自動安全修復，舊檔已備份於本機。")
        }

        // Final fail-safe: in-memory store (zero fatalError).
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let memoryContainer = try! ModelContainer(for: schema, configurations: [memoryConfig])
        return (memoryContainer, "目前以暫存模式開啟日記，請確認裝置儲存空間。")
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
                .onOpenURL { url in
                    coordinator.handleDeepLink(url)
                }
        }
        .modelContainer(container)
    }
}

import SwiftUI
import SwiftData
import os

@main
struct PawprintDaysApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let container: ModelContainer
    @State private var coordinator: GameCoordinator

    init() {
        let (resolvedContainer, recoveryWhisper) = Self.makeResilientContainer()
        self.container = resolvedContainer
        let gameCoordinator = GameCoordinator(modelContext: resolvedContainer.mainContext)
        if let recoveryWhisper {
            gameCoordinator.showWhisper(recoveryWhisper)
        }
        self._coordinator = State(initialValue: gameCoordinator)
    }

    private static let persistenceLog = Logger(subsystem: "com.pawprintdays.app", category: "persistence")

    // There is deliberately no "clean reset" wipe here. An earlier one-time reset
    // (`pawprintdays.releaseCleanReset.v1_mystical`) deleted the store on first launch to clear
    // pre-mystical-rework data; it was removed so no build can ever erase a player's diary.
    // Changes to the stored model shape go through `PawprintMigrationPlan` instead.

    // MARK: - Resilient container
    private static func makeResilientContainer() -> (ModelContainer, String?) {
        let schema = PawprintPersistence.currentSchema
        let persistentConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let storeURL = persistentConfig.url

        do {
            return (try PawprintPersistence.makeContainer(configuration: persistentConfig), nil)
        } catch {
            logStoreOpenFailure(error, storeURL: storeURL, attempt: "initial open")
        }

        // Safe recovery: archive unreadable store files rather than crashing on startup.
        // The archived files are kept next to the store so a future build (or support) can
        // migrate them by hand; nothing is deleted.
        let fm = FileManager.default
        if fm.fileExists(atPath: storeURL.path) {
            let stamp = Int(Date().timeIntervalSince1970)
            let backupBase = storeURL.deletingPathExtension().appendingPathExtension("backup-\(stamp).store")
            for suffix in ["", "-wal", "-shm"] {
                let src = URL(fileURLWithPath: storeURL.path + suffix)
                let dst = URL(fileURLWithPath: backupBase.path + suffix)
                guard fm.fileExists(atPath: src.path) else { continue }
                do {
                    try fm.moveItem(at: src, to: dst)
                } catch {
                    persistenceLog.error("Could not archive \(src.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
            persistenceLog.error("Archived unreadable store to \(backupBase.lastPathComponent, privacy: .public); starting with an empty diary.")
        }

        do {
            let recovered = try PawprintPersistence.makeContainer(configuration: persistentConfig)
            return (recovered, "資料庫已自動安全修復，舊檔已備份於本機。")
        } catch {
            logStoreOpenFailure(error, storeURL: storeURL, attempt: "reopen after archive")
        }

        // Final fail-safe: in-memory store (zero fatalError).
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let memoryContainer = try ModelContainer(for: schema, configurations: [memoryConfig])
            return (memoryContainer, "目前以暫存模式開啟日記，請確認裝置儲存空間。")
        } catch {
            persistenceLog.fault("In-memory fallback container failed: \(String(describing: error), privacy: .public)")
        }
        let fallback = try! ModelContainer(for: DiaryDayRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return (fallback, nil)
    }

    /// Logs a store-open failure with enough detail to tell a schema migration failure apart from
    /// I/O or corruption problems. Domain/code/reason are public (they hold no player data); the
    /// full error dump stays private because Core Data validation errors can echo diary text.
    private static func logStoreOpenFailure(_ error: Error, storeURL: URL, attempt: String) {
        let nsError = error as NSError
        let kind = isMigrationFailure(nsError) ? "schema migration failure" : "store open failure"
        let schemaVersion = String(describing: PawprintPersistence.currentVersionedSchema.versionIdentifier)
        let reason = nsError.localizedFailureReason ?? "-"
        var underlyingSummary = "-"
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            underlyingSummary = "\(underlying.domain)#\(underlying.code) \(underlying.localizedDescription)"
        }
        persistenceLog.error("""
            [\(attempt, privacy: .public)] \(kind, privacy: .public) opening \(storeURL.lastPathComponent, privacy: .public) \
            (target schema \(schemaVersion, privacy: .public)): \(nsError.domain, privacy: .public)#\(nsError.code, privacy: .public) \
            \(nsError.localizedDescription, privacy: .public) | reason: \(reason, privacy: .public) | underlying: \(underlyingSummary, privacy: .public)
            """)
        persistenceLog.debug("Full store-open error: \(String(reflecting: error), privacy: .private)")
    }

    /// Core Data reports model-version / migration problems in the 134100–134199 Cocoa error range
    /// (e.g. 134100 incompatible version hash, 134110 migration error, 134130 missing source model).
    private static func isMigrationFailure(_ error: NSError) -> Bool {
        let migrationRange = 134_100...134_199
        if error.domain == NSCocoaErrorDomain, migrationRange.contains(error.code) { return true }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isMigrationFailure(underlying)
        }
        return false
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

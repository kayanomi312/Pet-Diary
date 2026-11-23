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
                    persistenceLog.error("Could not archive \(src.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .private)")
                }
            }
            // `@Attribute(.externalStorage)` blobs (walk photos, baked postcards) live in the
            // `.<store name>_SUPPORT` sibling folder; move it alongside so the archive stays complete.
            let storeDir = storeURL.deletingLastPathComponent()
            let supportSrc = storeDir.appendingPathComponent(".\(storeURL.deletingPathExtension().lastPathComponent)_SUPPORT")
            let supportDst = storeDir.appendingPathComponent(".\(backupBase.deletingPathExtension().lastPathComponent)_SUPPORT")
            if fm.fileExists(atPath: supportSrc.path) {
                do {
                    try fm.moveItem(at: supportSrc, to: supportDst)
                } catch {
                    persistenceLog.error("Could not archive external-storage folder: \(error.localizedDescription, privacy: .private)")
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
            persistenceLog.fault("In-memory fallback container failed: \(String(describing: error), privacy: .private)")
        }
        // Last resort: an in-memory container over every model type, without the versioned schema
        // wrapper. (A container missing model types would only crash later, inside GameCoordinator.)
        let fallback = try! ModelContainer(
            for: Schema(PawprintSchemaV2.models),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return (fallback, nil)
    }

    /// Logs a store-open failure with enough detail to tell a schema migration failure apart from
    /// I/O or corruption problems.
    ///
    /// The kind, schema version and every `domain#code` in the error chain are public (no player data).
    /// Descriptions and reasons stay private: Core Data / SQLite text can include file paths, attribute
    /// names or values echoed from the diary.
    private static func logStoreOpenFailure(_ error: Error, storeURL: URL, attempt: String) {
        let chain = PawprintPersistence.errorChain(error)
        let kind = PawprintPersistence.isMigrationFailure(error) ? "schema migration failure" : "store open failure"
        let schemaVersion = String(describing: PawprintPersistence.currentVersionedSchema.versionIdentifier)
        let codes = chain.map { "\($0.domain)#\($0.code)" }.joined(separator: " > ")
        let details = chain.map { ns in
            "\(ns.domain)#\(ns.code): \(ns.localizedDescription) | reason: \(PawprintPersistence.failureReason(of: ns) ?? "-")"
        }.joined(separator: " > ")
        persistenceLog.error("""
            [\(attempt, privacy: .public)] \(kind, privacy: .public) opening \(storeURL.lastPathComponent, privacy: .public) \
            (target schema \(schemaVersion, privacy: .public)): \(codes, privacy: .public) | \(details, privacy: .private)
            """)
        persistenceLog.debug("Full store-open error: \(String(reflecting: error), privacy: .private)")
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

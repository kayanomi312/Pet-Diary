import SwiftUI

/// 統一溫潤繪本主路由：四大核心分頁（街區／陽光室／日記／小舖）共用底部懸浮暖棉紙導覽列，
/// 進入街角相遇劇場、近距離照護或陽光室賞景模式時自動收起，讓視野純淨無干擾！
struct RootStageView: View {
    @Bindable var coordinator: GameCoordinator

    private var showsFloatingDock: Bool {
        switch coordinator.currentScreen {
        case .street, .sketchbook, .curioCubbies:
            return true
        case .home:
            return !coordinator.isSunroomPhotoMode
        case .encounter, .tactileCare:
            return false
        }
    }

    private var hasReadyMentorship: Bool {
        coordinator.teachingIntentions.contains { $0.state == .demonstrated }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch coordinator.currentScreen {
                case .street:
                    StreetOverworldView(coordinator: coordinator)
                        .transition(.opacity)
                case .encounter(let siteID, let petID, let companionStreetPetID):
                    SidewalkEncounterView(
                        coordinator: coordinator,
                        siteID: siteID,
                        petID: petID,
                        companionStreetPetID: companionStreetPetID
                    )
                    .transition(.opacity)
                case .home:
                    HomeSunroomView(coordinator: coordinator)
                        .transition(.opacity)
                case .tactileCare(let petID):
                    TactileCareView(coordinator: coordinator, petID: petID)
                        .transition(.opacity)
                case .sketchbook:
                    HardcoverSketchbookView(coordinator: coordinator)
                        .transition(.opacity)
                case .curioCubbies:
                    CurioCubbiesView(coordinator: coordinator)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsFloatingDock {
                CozyFloatingDockBar(
                    currentScreen: $coordinator.currentScreen,
                    coinBalance: coordinator.ledger.coinBalance,
                    hasReadyMentorship: hasReadyMentorship,
                    onSelectTab: { target in
                        if target == .home {
                            coordinator.solveHomeRoomNow()
                        }
                        coordinator.currentScreen = target
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.24), value: coordinator.currentScreen)
        .sheet(isPresented: $coordinator.showFixtureDrawer) {
            Stage1FixtureDrawerView(coordinator: coordinator)
                .presentationDetents([.medium, .large])
        }
    }
}

import SwiftUI

/// Zero-HUD Diegetic Router — zero standard iOS tab bars or stat dashboards.
struct RootStageView: View {
    @Bindable var coordinator: GameCoordinator

    var body: some View {
        ZStack {
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
                    .transition(.move(edge: .trailing))
            case .curioCubbies:
                CurioCubbiesView(coordinator: coordinator)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: coordinator.currentScreen)
        .sheet(isPresented: $coordinator.showFixtureDrawer) {
            Stage1FixtureDrawerView(coordinator: coordinator)
                .presentationDetents([.medium, .large])
        }
    }
}

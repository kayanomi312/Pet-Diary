import SwiftUI

/// 測試與天氣切換面板（繁體中文：14 天自動驗證、Metal LUT 天氣預覽、步數模擬）
struct Stage1FixtureDrawerView: View {
    @Bindable var coordinator: GameCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("14 天自動驗證劇本") {
                    Button {
                        _ = coordinator.runStage1Deterministic14DayFixture()
                    } label: {
                        Label("執行 14 天完整驗證劇本", systemImage: "play.circle.fill")
                            .font(AppTheme.diegeticLabel(15))
                            .foregroundStyle(AppTheme.forestTeal)
                    }

                    if let report = coordinator.latestFixtureReport {
                        GateRow(title: "1. 75m 距離鎖定、第 3 天手勢記憶與保底奇幻訪客", passed: report.gate1ProximityAndDay3CallbackPassed)
                        GateRow(title: "2. 第 1 天素頸原圖明信片不因第 2 天換緞帶改寫", passed: report.gate2ImmutableSnapshotPassed)
                        GateRow(title: "3. 獨立區間步數幣（5,840 + 160 − 12 = 18 幣）", passed: report.gate3DisjointCoinLedgerPassed)
                        GateRow(title: "4. 單日地點抹除後完整保留室友與步數幣", passed: report.gate4SingleDayErasurePassed)

                        ForEach(report.details, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(AppTheme.softInk)
                        }
                    }
                }

                Section("天氣與 Metal 紙紋光影預覽") {
                    Picker("目前天氣", selection: $coordinator.activeWeather) {
                        ForEach(WeatherMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }

                Section("快轉天數與步數測試") {
                    Button("往前推進 +1 天（\(coordinator.currentLocalDateISO)）") {
                        coordinator.advanceSimulatedDays(1)
                    }
                    Button("模擬 +1,250 步（觸發剩 200 步金光預告）") {
                        _ = coordinator.ingestSteps(
                            steps: 1_250,
                            intervalStartUTC: coordinator.currentSimulatedDate.addingTimeInterval(Double.random(in: 1000...8000)),
                            placeLabel: "麵包店巷口"
                        )
                    }
                    Button("模擬 +200 步（拾獲口袋小物與 +1 步數幣）") {
                        _ = coordinator.ingestSteps(
                            steps: 200,
                            intervalStartUTC: coordinator.currentSimulatedDate.addingTimeInterval(Double.random(in: 9000...18000)),
                            placeLabel: "溪畔木椅"
                        )
                    }
                    Button("前往精裝日記（檢視不可變明信片）") {
                        dismiss()
                        coordinator.currentScreen = .sketchbook
                    }
                    Button("前往陽光室家園（檢視多寵相聚）") {
                        dismiss()
                        coordinator.solveHomeRoomNow()
                        coordinator.currentScreen = .home
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.parchmentTray)
            .navigationTitle("測試與光影面板")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

private struct GateRow: View {
    let title: String
    let passed: Bool

    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .foregroundStyle(passed ? AppTheme.vineGreen : AppTheme.clothBookmark)
            Text(title)
                .font(AppTheme.serifBody(14))
                .foregroundStyle(AppTheme.deepPineInk)
        }
    }
}

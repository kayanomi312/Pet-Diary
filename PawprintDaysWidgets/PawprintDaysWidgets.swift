import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Home Screen Widget Provider
struct PawprintWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: PawprintWidgetSnapshot
}

struct PawprintWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PawprintWidgetEntry {
        PawprintWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PawprintWidgetEntry) -> Void) {
        completion(PawprintWidgetEntry(date: Date(), snapshot: PawprintWidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PawprintWidgetEntry>) -> Void) {
        let entry = PawprintWidgetEntry(date: Date(), snapshot: PawprintWidgetStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct PawprintHomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PawprintWidgetEntry

    private let creamBG = Color(red: 0.98, green: 0.96, blue: 0.91)
    private let pineInk = Color(red: 0.16, green: 0.21, blue: 0.21)
    private let forestTeal = Color(red: 0.14, green: 0.34, blue: 0.35)
    private let amberGold = Color(red: 0.85, green: 0.62, blue: 0.24)

    var body: some View {
        Group {
            if family == .systemSmall {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .containerBackground(creamBG, for: .widget)
        .widgetURL(URL(string: "pawprintdays://start-stroll"))
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.snapshot.weatherSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(forestTeal)
                Text(entry.snapshot.weatherDisplayName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(pineInk.opacity(0.75))
                Spacer()
            }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(amberGold)
                Text(entry.snapshot.companionName)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(pineInk)
                    .lineLimit(1)
            }

            Text("再走 \(entry.snapshot.stepsUntilPocketFind) 步拾遺")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(forestTeal)

            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 10, weight: .bold))
                Text("出發散步")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(amberGold, in: Capsule())
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: entry.snapshot.weatherSymbol)
                        .foregroundStyle(forestTeal)
                    Text("足印日記 · \(entry.snapshot.weatherDisplayName)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(pineInk.opacity(0.78))
                }
                Text("\(entry.snapshot.companionName)在等你散步")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(pineInk)
                Text("今日 \(entry.snapshot.stepsToday.formatted()) 步 · 袋中 \(entry.snapshot.coinBalance) 幣")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(pineInk.opacity(0.72))
                Text("再走 \(entry.snapshot.stepsUntilPocketFind) 步可撿到街區拾遺")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(forestTeal)
            }
            Spacer(minLength: 4)
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 48, height: 48)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(forestTeal)
                }
                Text("出發散步")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(amberGold, in: Capsule())
            }
        }
    }
}

struct PawprintHomeWidget: Widget {
    let kind: String = "PawprintHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PawprintWidgetProvider()) { entry in
            PawprintHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("足印日記散步小卡")
        .description("一眼看見散步夥伴、今日天氣與下一件拾遺步數，輕點立即出發散步。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Lock Screen & Dynamic Island Live Activity
#if canImport(ActivityKit)
struct StrollLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StrollLiveActivityAttributes.self) { context in
            // Lock Screen Banner
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: "pawprint.fill")
                            .foregroundStyle(Color(red: 0.85, green: 0.62, blue: 0.24))
                        Text("與\(context.attributes.companionName)散步中")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                    }
                    Text("最近街角：\(context.state.nearestCornerLabel) · \(context.state.nearestDistanceMeters)m")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    if context.state.isNearPocketFind {
                        Text("✦ 快撿到街區拾遺囉！")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.16))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(context.state.steps.formatted()) 步")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("+\(context.state.coinsEarned) 幣")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.14, green: 0.34, blue: 0.35))
                }
            }
            .padding(14)
            .activityBackgroundTint(Color(red: 0.98, green: 0.96, blue: 0.91))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.companionName, systemImage: "pawprint.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.94, green: 0.75, blue: 0.40))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.steps) 步")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("前方 \(context.state.nearestCornerLabel) · \(context.state.nearestDistanceMeters)m")
                            .font(.system(size: 12, design: .rounded))
                        Spacer()
                        Text(context.attributes.charmTitle)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(Color(red: 0.94, green: 0.75, blue: 0.40))
            } compactTrailing: {
                Text("\(context.state.steps)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            } minimal: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(Color(red: 0.94, green: 0.75, blue: 0.40))
            }
        }
    }
}
#endif

@main
struct PawprintDaysWidgetBundle: WidgetBundle {
    var body: some Widget {
        PawprintHomeWidget()
        #if canImport(ActivityKit)
        StrollLiveActivityWidget()
        #endif
    }
}

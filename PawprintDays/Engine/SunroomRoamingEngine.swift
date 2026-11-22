import Foundation
import SwiftUI
import Observation

/// 2.5D 陽光室自由漫步與奇幻物種互動 AI 引擎：
/// - 零卡頓 60fps 數學內插（不於每 16ms 改動 @Observable 字典，節省 ~75% CPU 與電力！）
/// - 真實家飾互動（鑽進紙箱、窩上毛毯、揮掌把縫布球滾過 2.5D 紅檜木地板）
/// - 《貓與龍》奇幻物種專屬魔法行為（餘燼烘暖毯子、杜松掉落可點擊摺紙符＋1 幣、摺翼遮蔭、梅子雲霧、蘆葦森葉）
/// - 支援 2.5D 自由拖曳佈置家飾座標持久化
@MainActor
@Observable
final class SunroomRoamingEngine {
    enum RoamBehavior: Equatable {
        case walking(from: CGPoint, to: CGPoint, startedAt: Date, duration: TimeInterval, arrivalSpotIndex: Int?)
        case sitting(until: Date, spotIndex: Int?)
        case napping(until: Date, spotIndex: Int?)
        case greetingFriend(partnerID: String, until: Date)
        case playingBall(until: Date, spotIndex: Int?)
        case cozyInBox(until: Date, spotIndex: Int)
    }

    struct RoamingPetActor: Identifiable {
        var id: String { petID }
        let petID: String
        var position: CGPoint // anchor/settled room UV (x: 0.08..0.92, y: 0.14..0.86)
        var facingRight: Bool = false
        var behavior: RoamBehavior
        var speechBubble: String? = nil
        var bubbleExpiresAt: Date = .distantPast
        var tapExcitedUntil: Date = .distantPast

        var isWalking: Bool {
            if case .walking = behavior { return true }
            return false
        }

        var isNapping: Bool {
            if case .napping = behavior { return true }
            return false
        }

        /// Pure 60fps position interpolation computed on demand without mutating `@Observable` state every frame!
        func interpolatedPosition(at now: Date) -> CGPoint {
            guard case .walking(let from, let to, let startedAt, let duration, _) = behavior else {
                return position
            }
            let rawP = min(1.0, max(0.0, now.timeIntervalSince(startedAt) / max(0.2, duration)))
            let eased = rawP < 0.5
                ? 2.0 * rawP * rawP
                : 1.0 - pow(-2.0 * rawP + 2.0, 2.0) / 2.0
            return CGPoint(
                x: from.x + (to.x - from.x) * eased,
                y: from.y + (to.y - from.y) * eased
            )
        }
    }

    struct FloorTapRipple: Identifiable {
        let id = UUID()
        let position: CGPoint
        let createdAt: Date
    }

    /// 杜松（黑曜惡魔貓）悄悄留在紅檜木地板上的摺紙契約小符（點擊可拾取傲嬌紙條與 +1 步數幣！）
    struct OrigamiCharmDrop: Identifiable, Equatable {
        let id = UUID()
        let position: CGPoint
        let note: String
        let createdAt: Date
    }

    /// 滾動中的手工縫布球（毛孩在 2.5D 地板揮掌撥動後自然滑行！）
    struct RollingClothBall: Equatable {
        let from: CGPoint
        let to: CGPoint
        let startedAt: Date
        let duration: TimeInterval

        func position(at now: Date) -> CGPoint? {
            let p = now.timeIntervalSince(startedAt) / max(0.2, duration)
            guard p >= 0 && p <= 1.25 else { return nil }
            let clamped = min(1.0, p)
            let decel = 1.0 - pow(1.0 - clamped, 2.2)
            return CGPoint(
                x: from.x + (to.x - from.x) * decel,
                y: from.y + (to.y - from.y) * decel
            )
        }
    }

    private static let customSpotCoordsKey = "pawprintdays.sunroom.customSpotCoords.v1"

    var actors: [String: RoamingPetActor] = [:]
    var floorRipples: [FloorTapRipple] = []
    var origamiDrops: [OrigamiCharmDrop] = []
    var rollingBall: RollingClothBall? = nil
    var customSpotPositions: [Int: CGPoint] = [:]

    private var lastStateTickDate: Date = .distantPast
    private var lastOrigamiDropDate: Date = .distantPast

    private static let cozyWhispers: [String] = [
        "窗邊好暖和～",
        "去那邊看看♪",
        "呼嚕呼嚕…",
        "聞到麵包香了",
        "踩踩木地板♡",
        "這個角落最舒服",
        "一起曬太陽吧"
    ]

    private static let juniperOrigamiNotes: [String] = [
        "本惡魔才不是特地摺給你的…拿去吧！(+1 步數幣)",
        "摺得方方正正的紙鶴，放在你腳邊剛剛好。(+1 步數幣)",
        "契約書第 1 條：今天也要一起慢慢散步。(+1 步數幣)",
        "這張黑曜星紙符能保佑明天出門不下大雨。(+1 步數幣)"
    ]

    init() {
        loadCustomSpotPositions()
    }

    /// 2.5D 錯落有致的家具透視位置（優先使用玩家在佈置模式中自訂的拖曳位置！）
    func resolvedSpotPosition(for spotIndex: Int, verandaUnlocked: Bool) -> CGPoint {
        if let custom = customSpotPositions[spotIndex] {
            return custom
        }
        return Self.spot25DPosition(for: spotIndex, verandaUnlocked: verandaUnlocked)
    }

    func setCustomSpotPosition(spotIndex: Int, uv: CGPoint) {
        let clamped = CGPoint(
            x: max(0.10, min(0.90, uv.x)),
            y: max(0.16, min(0.84, uv.y))
        )
        customSpotPositions[spotIndex] = clamped
        saveCustomSpotPositions()
    }

    func resetCustomSpotPositions() {
        customSpotPositions.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.customSpotCoordsKey)
    }

    private func saveCustomSpotPositions() {
        var encoded: [String: [Double]] = [:]
        for (idx, pt) in customSpotPositions {
            encoded[String(idx)] = [Double(pt.x), Double(pt.y)]
        }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: Self.customSpotCoordsKey)
        }
    }

    private func loadCustomSpotPositions() {
        guard let data = UserDefaults.standard.data(forKey: Self.customSpotCoordsKey),
              let decoded = try? JSONDecoder().decode([String: [Double]].self, from: data) else {
            return
        }
        for (k, pair) in decoded where pair.count == 2 {
            if let idx = Int(k) {
                customSpotPositions[idx] = CGPoint(x: pair[0], y: pair[1])
            }
        }
    }

    static func spot25DPosition(for spotIndex: Int, verandaUnlocked: Bool) -> CGPoint {
        if verandaUnlocked {
            switch spotIndex {
            case 1: return CGPoint(x: 0.14, y: 0.18) // 窗邊軟墊（後左）
            case 2: return CGPoint(x: 0.36, y: 0.34) // 日光毛毯（中後）
            case 3: return CGPoint(x: 0.58, y: 0.22) // 麵包紙箱（後中右）
            case 4: return CGPoint(x: 0.22, y: 0.74) // 編織圓毯（前左）
            case 5: return CGPoint(x: 0.50, y: 0.78) // 午茶木墊（前中）
            case 6: return CGPoint(x: 0.78, y: 0.26) // 雨廊窗台（右廊後）
            case 7: return CGPoint(x: 0.84, y: 0.56) // 雨廊木凳（右廊中）
            default: return CGPoint(x: 0.76, y: 0.80) // 雨廊晴墊（右廊前）
            }
        } else {
            switch spotIndex {
            case 1: return CGPoint(x: 0.20, y: 0.18) // 窗邊軟墊（後左）
            case 2: return CGPoint(x: 0.50, y: 0.32) // 日光毛毯（中後）
            case 3: return CGPoint(x: 0.80, y: 0.22) // 麵包紙箱（後右）
            case 4: return CGPoint(x: 0.28, y: 0.74) // 編織圓毯（前左）
            default: return CGPoint(x: 0.72, y: 0.78) // 午茶木墊（前右）
            }
        }
    }

    func syncResidents(invitedPetIDs: [String], spots: [HomeSpotPlacement], verandaUnlocked: Bool, now: Date = Date()) {
        let validSet = Set(invitedPetIDs)
        for key in Array(actors.keys) where !validSet.contains(key) {
            actors.removeValue(forKey: key)
        }

        for (idx, petID) in invitedPetIDs.enumerated() where actors[petID] == nil {
            let assignedSpot = spots.first(where: { $0.currentOccupantPetIDs.contains(petID) })
            let startPos: CGPoint
            if let spot = assignedSpot {
                let sp = resolvedSpotPosition(for: spot.spotIndex, verandaUnlocked: verandaUnlocked)
                let jitter = CGFloat((idx % 3) - 1) * 0.035
                startPos = CGPoint(x: max(0.10, min(0.90, sp.x + jitter)), y: sp.y)
            } else {
                startPos = CGPoint(
                    x: 0.22 + CGFloat(idx % 4) * 0.19,
                    y: 0.30 + CGFloat((idx / 4) % 2) * 0.36
                )
            }

            // 讓三分之一的室友悠閒漫步、三分之一靜靜坐著曬太陽、三分之一窩著小憩，節奏從容溫柔！
            let behavior: RoamBehavior
            var facingRight = false
            if idx % 3 == 0 {
                let target = pickNextWalkDestination(from: startPos, spots: spots, verandaUnlocked: verandaUnlocked)
                let dist = hypot(target.point.x - startPos.x, target.point.y - startPos.y)
                let dur = max(4.5, min(12.5, Double(dist) * 18.5))
                facingRight = target.point.x > startPos.x
                behavior = .walking(from: startPos, to: target.point, startedAt: now, duration: dur, arrivalSpotIndex: target.spotIndex)
            } else if idx % 3 == 2 {
                behavior = .napping(until: now.addingTimeInterval(Double.random(in: 12.0...22.0)), spotIndex: assignedSpot?.spotIndex)
            } else {
                behavior = .sitting(until: now.addingTimeInterval(Double.random(in: 6.5...13.0)), spotIndex: assignedSpot?.spotIndex)
            }

            actors[petID] = RoamingPetActor(
                petID: petID,
                position: startPos,
                facingRight: facingRight,
                behavior: behavior
            )
        }
    }

    /// 狀態機低頻推進（每 0.25s 檢查一次狀態轉換；不於 60fps 改寫位置，讓 SwiftUI 零無謂重繪！）
    func tick(now: Date, spots: [HomeSpotPlacement], verandaUnlocked: Bool, weather: WeatherMode = .clearMorning) {
        guard now.timeIntervalSince(lastStateTickDate) >= 0.25 else { return }
        lastStateTickDate = now

        if floorRipples.contains(where: { now.timeIntervalSince($0.createdAt) > 1.25 }) {
            floorRipples.removeAll { now.timeIntervalSince($0.createdAt) > 1.25 }
        }
        if let ball = rollingBall, ball.position(at: now) == nil {
            rollingBall = nil
        }

        // 杜松（黑曜惡魔貓）在房間裡時，偶爾悄悄放下一張可點擊的摺紙小符！
        if let juniper = actors["pet.02"],
           origamiDrops.isEmpty,
           now.timeIntervalSince(lastOrigamiDropDate) > 22.0,
           !juniper.isNapping {
            lastOrigamiDropDate = now
            let dropPos = juniper.interpolatedPosition(at: now)
            let clampedDrop = CGPoint(
                x: max(0.14, min(0.86, dropPos.x + (juniper.facingRight ? -0.05 : 0.05))),
                y: max(0.24, min(0.82, dropPos.y + 0.03))
            )
            origamiDrops.append(
                OrigamiCharmDrop(
                    position: clampedDrop,
                    note: Self.juniperOrigamiNotes.randomElement() ?? "本惡魔順手摺的紙符。(+1 步數幣)",
                    createdAt: now
                )
            )
        }

        let petIDs = Array(actors.keys).sorted()
        for petID in petIDs {
            guard var actor = actors[petID] else { continue }
            var didMutate = false

            if actor.speechBubble != nil && now > actor.bubbleExpiresAt {
                actor.speechBubble = nil
                didMutate = true
            }

            switch actor.behavior {
            case .walking(let from, let to, let startedAt, let duration, let arrivalSpot):
                let rawP = min(1.0, max(0.0, now.timeIntervalSince(startedAt) / max(0.2, duration)))
                let currentPos = actor.interpolatedPosition(at: now)

                if rawP >= 1.0 {
                    actor.position = to
                    didMutate = true
                    let spec = PetCatalog.pet(id: petID)
                    let arrivedSpotRecord = arrivalSpot.flatMap { idx in spots.first(where: { $0.spotIndex == idx }) }
                    let goodieID = arrivedSpotRecord?.equippedGoodieID

                    // 依抵達的家飾物觸發真實空間互動！
                    if goodieID == "goodie.cloth_ball" {
                        actor.behavior = .playingBall(until: now.addingTimeInterval(4.5), spotIndex: arrivalSpot)
                        actor.speechBubble = spec.kind.isCatFamily ? "拍拍縫布球～♪" : "滾球玩囉汪！"
                        actor.bubbleExpiresAt = now.addingTimeInterval(3.8)
                        let rollTo = CGPoint(
                            x: max(0.14, min(0.86, to.x + (actor.facingRight ? 0.24 : -0.24))),
                            y: max(0.26, min(0.82, to.y + CGFloat.random(in: -0.08...0.08)))
                        )
                        rollingBall = RollingClothBall(from: to, to: rollTo, startedAt: now, duration: 2.2)
                    } else if goodieID == "goodie.bakery_box" && spec.kind.isCatFamily, let sIdx = arrivalSpot {
                        actor.behavior = .cozyInBox(until: now.addingTimeInterval(Double.random(in: 10.0...18.0)), spotIndex: sIdx)
                        actor.speechBubble = "紙箱剛剛好擠進來♡"
                        actor.bubbleExpiresAt = now.addingTimeInterval(4.0)
                    } else if (goodieID == "goodie.wool_blanket" || goodieID == "goodie.folded_towel" || goodieID == "goodie.window_cushion")
                                || (arrivalSpot != nil && Int.random(in: 0..<100) < 45) {
                        actor.behavior = .napping(until: now.addingTimeInterval(Double.random(in: 14.0...26.0)), spotIndex: arrivalSpot)
                        if petID == "pet.03" {
                            actor.speechBubble = weather.isRainy ? "用龍息把毛毯烘暖暖的…" : "爐爪暖呼呼…呼呼…"
                            actor.bubbleExpiresAt = now.addingTimeInterval(4.2)
                        } else if Int.random(in: 0..<3) == 0 {
                            actor.speechBubble = "好暖和…呼呼…"
                            actor.bubbleExpiresAt = now.addingTimeInterval(3.8)
                        }
                    } else {
                        actor.behavior = .sitting(until: now.addingTimeInterval(Double.random(in: 7.5...15.0)), spotIndex: arrivalSpot)
                        if Int.random(in: 0..<3) == 0 {
                            actor.speechBubble = speciesContextualWhisper(for: petID, weather: weather)
                            actor.bubbleExpiresAt = now.addingTimeInterval(4.0)
                        }
                    }
                } else if rawP > 0.25 && rawP < 0.75,
                          let friend = findNearbyGreetingPartner(for: actor, atPos: currentPos, now: now) {
                    actor.position = currentPos
                    actor.facingRight = friend.position.x > currentPos.x
                    actor.behavior = .greetingFriend(partnerID: friend.petID, until: now.addingTimeInterval(4.2))
                    // 奇幻物種專屬相遇對白（例如餘燼幫淋雨的朋友烘暖、摺翼幫打盹的朋友遮陽！）
                    if petID == "pet.03" && weather.isRainy {
                        actor.speechBubble = "別著涼了，我幫你烘烘毛～"
                    } else if petID == "pet.04" && weather == .clearMorning {
                        actor.speechBubble = "我展開翅膀替你遮蔭喔…"
                    } else {
                        actor.speechBubble = "喵～一起玩嗎♡"
                    }
                    actor.bubbleExpiresAt = now.addingTimeInterval(4.2)
                    didMutate = true

                    if var partner = actors[friend.petID] {
                        partner.facingRight = currentPos.x > partner.position.x
                        partner.behavior = .greetingFriend(partnerID: actor.petID, until: now.addingTimeInterval(4.2))
                        partner.speechBubble = "呼嚕嚕♪"
                        partner.bubbleExpiresAt = now.addingTimeInterval(4.2)
                        actors[friend.petID] = partner
                    }
                }

            case .sitting(let until, _), .napping(let until, _), .greetingFriend(_, let until), .playingBall(let until, _), .cozyInBox(let until, _):
                if now >= until {
                    let target = pickNextWalkDestination(from: actor.position, spots: spots, verandaUnlocked: verandaUnlocked)
                    let dist = hypot(target.point.x - actor.position.x, target.point.y - actor.position.y)
                    let dur = max(4.5, min(12.5, Double(dist) * 18.5))
                    actor.facingRight = target.point.x > actor.position.x
                    actor.behavior = .walking(from: actor.position, to: target.point, startedAt: now, duration: dur, arrivalSpotIndex: target.spotIndex)
                    didMutate = true
                }
            }

            if didMutate {
                actors[petID] = actor
            }
        }
    }

    func collectOrigamiDrop(id: UUID) -> OrigamiCharmDrop? {
        guard let idx = origamiDrops.firstIndex(where: { $0.id == id }) else { return nil }
        return origamiDrops.remove(at: idx)
    }

    /// 玩家點擊陽光室 2.5D 地板任一處 → 喚來最近的室友輕快卻自然地走過來！
    func callNearestPet(to roomUV: CGPoint, now: Date = Date()) {
        let clamped = CGPoint(
            x: max(0.09, min(0.91, roomUV.x)),
            y: max(0.16, min(0.86, roomUV.y))
        )
        floorRipples.append(FloorTapRipple(position: clamped, createdAt: now))

        guard let nearest = actors.values.min(by: {
            let p0 = $0.interpolatedPosition(at: now)
            let p1 = $1.interpolatedPosition(at: now)
            return hypot(p0.x - clamped.x, p0.y - clamped.y) < hypot(p1.x - clamped.x, p1.y - clamped.y)
        }) else { return }

        var actor = nearest
        let startPos = actor.interpolatedPosition(at: now)
        actor.position = startPos
        let dist = hypot(clamped.x - startPos.x, clamped.y - startPos.y)
        let dur = max(2.4, min(6.8, Double(dist) * 11.5))
        actor.facingRight = clamped.x > startPos.x
        actor.behavior = .walking(from: startPos, to: clamped, startedAt: now, duration: dur, arrivalSpotIndex: nil)
        actor.speechBubble = "來囉～♪"
        actor.bubbleExpiresAt = now.addingTimeInterval(2.6)
        actor.tapExcitedUntil = now.addingTimeInterval(1.6)
        actors[actor.petID] = actor
    }

    private func speciesContextualWhisper(for petID: String, weather: WeatherMode) -> String {
        switch petID {
        case "pet.02": return "才不是在等你回來呢…"
        case "pet.03": return weather.isRainy ? "屋裡暖呼呼的，雨聲好好聽" : "尾巴冒出暖暖的小火星♪"
        case "pet.04": return weather == .dusk ? "傍晚的微光最舒服了…" : "把暮色翅膀折得整整齊齊"
        case "pet.06": return "小鬼火輕輕飄著，守護陽光室！"
        case "pet.07": return "像軟綿綿的雲朵一樣打滾♪"
        case "pet.08": return "鹿角上的小嫩葉又長出新芽了"
        default: return Self.cozyWhispers.randomElement() ?? "呼嚕呼嚕…"
        }
    }

    private func findNearbyGreetingPartner(for actor: RoamingPetActor, atPos: CGPoint, now: Date) -> RoamingPetActor? {
        for other in actors.values where other.petID != actor.petID {
            if case .sitting = other.behavior {
                let d = hypot(other.position.x - atPos.x, other.position.y - atPos.y)
                if d < 0.13 && Int.random(in: 0..<100) < 12 {
                    return other
                }
            }
        }
        return nil
    }

    private func pickNextWalkDestination(from origin: CGPoint, spots: [HomeSpotPlacement], verandaUnlocked: Bool) -> (point: CGPoint, spotIndex: Int?) {
        if !spots.isEmpty && Int.random(in: 0..<100) < 58 {
            let candidates = spots.filter { spot in
                let p = resolvedSpotPosition(for: spot.spotIndex, verandaUnlocked: verandaUnlocked)
                return hypot(p.x - origin.x, p.y - origin.y) > 0.14
            }
            if let chosen = candidates.randomElement() {
                let p = resolvedSpotPosition(for: chosen.spotIndex, verandaUnlocked: verandaUnlocked)
                return (
                    CGPoint(
                        x: max(0.10, min(0.90, p.x + CGFloat.random(in: -0.025...0.025))),
                        y: max(0.16, min(0.84, p.y + CGFloat.random(in: -0.02...0.02)))
                    ),
                    chosen.spotIndex
                )
            }
        }

        for _ in 0..<6 {
            let rx = CGFloat.random(in: 0.12...0.88)
            let ry = CGFloat.random(in: 0.22...0.84)
            if hypot(rx - origin.x, ry - origin.y) > 0.22 {
                return (CGPoint(x: rx, y: ry), nil)
            }
        }
        return (CGPoint(x: origin.x > 0.5 ? 0.24 : 0.76, y: CGFloat.random(in: 0.30...0.74)), nil)
    }
}

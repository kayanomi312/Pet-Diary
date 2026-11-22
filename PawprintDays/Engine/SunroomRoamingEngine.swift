import Foundation
import SwiftUI
import Observation

/// 2.5D 陽光室自由漫步 AI 引擎：讓所有室友在具透視深度的地板與家飾之間
/// 流暢走動、自動轉向左右、依前後深度自動縮放與遮擋排序（zIndex）、互相打招呼、窩上軟墊午睡，以及響應點擊地板前來撒嬌！
@MainActor
@Observable
final class SunroomRoamingEngine {
    enum RoamBehavior: Equatable {
        case walking(from: CGPoint, to: CGPoint, startedAt: Date, duration: TimeInterval, arrivalSpotIndex: Int?)
        case sitting(until: Date, spotIndex: Int?)
        case napping(until: Date, spotIndex: Int?)
        case greetingFriend(partnerID: String, until: Date)
    }

    struct RoamingPetActor: Identifiable {
        var id: String { petID }
        let petID: String
        var position: CGPoint // x: 0.08..0.92 (horizontal room UV), y: 0.14..0.86 (depth 0=back window, 1=front rug)
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
    }

    struct FloorTapRipple: Identifiable {
        let id = UUID()
        let position: CGPoint // room UV (x, depth)
        let createdAt: Date
    }

    var actors: [String: RoamingPetActor] = [:]
    var floorRipples: [FloorTapRipple] = []
    private var lastTickDate: Date = .distantPast

    private static let cozyWhispers: [String] = [
        "窗邊好暖和～",
        "去那邊看看♪",
        "呼嚕呼嚕…",
        "聞到麵包香了",
        "踩踩木地板♡",
        "這個角落最舒服",
        "一起曬太陽吧"
    ]

    /// 2.5D 錯落有致的家具透視位置（不再是一字排開的 1D 橫排！）
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

    /// 同步目前已入住的室友清單（若有尚未開鎖室友，也能讓第一位遇見的或已入住室友自由散步）
    func syncResidents(invitedPetIDs: [String], spots: [HomeSpotPlacement], verandaUnlocked: Bool, now: Date = Date()) {
        let validSet = Set(invitedPetIDs)
        // 移除不在清單中的角色
        for key in Array(actors.keys) where !validSet.contains(key) {
            actors.removeValue(forKey: key)
        }

        // 替新入住的室友初始化在牠所屬的家飾位置或陽光地板上
        for (idx, petID) in invitedPetIDs.enumerated() where actors[petID] == nil {
            let assignedSpot = spots.first(where: { $0.currentOccupantPetIDs.contains(petID) })
            let startPos: CGPoint
            if let spot = assignedSpot {
                let sp = Self.spot25DPosition(for: spot.spotIndex, verandaUnlocked: verandaUnlocked)
                let jitter = CGFloat((idx % 3) - 1) * 0.04
                startPos = CGPoint(x: max(0.10, min(0.90, sp.x + jitter)), y: sp.y)
            } else {
                startPos = CGPoint(
                    x: 0.22 + CGFloat(idx % 4) * 0.19,
                    y: 0.30 + CGFloat((idx / 4) % 2) * 0.36
                )
            }

            // 讓一半的室友一進來就開始自在散步，另一半先休息或張望，畫面立刻充滿生機！
            let startWalking = (idx % 2 == 0)
            let behavior: RoamBehavior
            var facingRight = false
            if startWalking {
                let target = pickNextWalkDestination(from: startPos, spots: spots, verandaUnlocked: verandaUnlocked)
                let dist = hypot(target.point.x - startPos.x, target.point.y - startPos.y)
                let dur = max(2.4, min(6.2, Double(dist) * 8.5))
                facingRight = target.point.x > startPos.x
                behavior = .walking(from: startPos, to: target.point, startedAt: now, duration: dur, arrivalSpotIndex: target.spotIndex)
            } else {
                behavior = .sitting(until: now.addingTimeInterval(Double.random(in: 2.5...5.5)), spotIndex: assignedSpot?.spotIndex)
            }

            actors[petID] = RoamingPetActor(
                petID: petID,
                position: startPos,
                facingRight: facingRight,
                behavior: behavior
            )
        }
    }

    /// 每幀推進 2.5D 漫步位置、抵達狀態切換、相遇打招呼與自動對話泡泡（60fps 流暢滑行）
    func tick(now: Date, spots: [HomeSpotPlacement], verandaUnlocked: Bool) {
        guard now.timeIntervalSince(lastTickDate) >= 0.016 else { return }
        lastTickDate = now

        // 清理已淡出的地板點擊波紋
        floorRipples.removeAll { now.timeIntervalSince($0.createdAt) > 1.25 }

        let petIDs = Array(actors.keys).sorted()
        for petID in petIDs {
            guard var actor = actors[petID] else { continue }

            // 清除過期的對話泡泡
            if actor.speechBubble != nil && now > actor.bubbleExpiresAt {
                actor.speechBubble = nil
            }

            switch actor.behavior {
            case .walking(let from, let to, let startedAt, let duration, let arrivalSpot):
                let rawP = min(1.0, max(0.0, now.timeIntervalSince(startedAt) / max(0.2, duration)))
                // Smooth ease-in-out cubic so starting and stopping walks feel organic and gentle
                let eased = rawP < 0.5
                    ? 2.0 * rawP * rawP
                    : 1.0 - pow(-2.0 * rawP + 2.0, 2.0) / 2.0
                let nx = from.x + (to.x - from.x) * eased
                let ny = from.y + (to.y - from.y) * eased
                actor.position = CGPoint(x: nx, y: ny)
                if abs(to.x - from.x) > 0.015 {
                    actor.facingRight = (to.x > from.x)
                }

                if rawP >= 1.0 {
                    // 抵達目的地！選擇坐下張望或窩下來午睡
                    let shouldNap = (arrivalSpot != nil && Int.random(in: 0..<10) < 4)
                    if shouldNap {
                        actor.behavior = .napping(until: now.addingTimeInterval(Double.random(in: 6.5...11.0)), spotIndex: arrivalSpot)
                        if Int.random(in: 0..<3) == 0 {
                            actor.speechBubble = "好暖和…呼呼…"
                            actor.bubbleExpiresAt = now.addingTimeInterval(3.2)
                        }
                    } else {
                        actor.behavior = .sitting(until: now.addingTimeInterval(Double.random(in: 3.0...6.5)), spotIndex: arrivalSpot)
                        if Int.random(in: 0..<4) == 0 {
                            actor.speechBubble = Self.cozyWhispers.randomElement()
                            actor.bubbleExpiresAt = now.addingTimeInterval(3.2)
                        }
                    }
                } else {
                    // 走路途中若巧遇另一位靜止的室友，停下來互相打招呼！
                    if rawP > 0.25 && rawP < 0.75,
                       let friend = findNearbyGreetingPartner(for: actor, now: now) {
                        actor.facingRight = friend.position.x > actor.position.x
                        actor.behavior = .greetingFriend(partnerID: friend.petID, until: now.addingTimeInterval(2.6))
                        actor.speechBubble = "喵～一起玩嗎♡"
                        actor.bubbleExpiresAt = now.addingTimeInterval(2.6)

                        if var partner = actors[friend.petID] {
                            partner.facingRight = actor.position.x > partner.position.x
                            partner.behavior = .greetingFriend(partnerID: actor.petID, until: now.addingTimeInterval(2.6))
                            partner.speechBubble = "呼嚕嚕♪"
                            partner.bubbleExpiresAt = now.addingTimeInterval(2.6)
                            actors[friend.petID] = partner
                        }
                    }
                }

            case .sitting(let until, _), .napping(let until, _), .greetingFriend(_, let until):
                if now >= until {
                    let target = pickNextWalkDestination(from: actor.position, spots: spots, verandaUnlocked: verandaUnlocked)
                    let dist = hypot(target.point.x - actor.position.x, target.point.y - actor.position.y)
                    let dur = max(2.2, min(6.5, Double(dist) * 8.8))
                    actor.facingRight = target.point.x > actor.position.x
                    actor.behavior = .walking(from: actor.position, to: target.point, startedAt: now, duration: dur, arrivalSpotIndex: target.spotIndex)
                }
            }

            actors[petID] = actor
        }
    }

    /// 玩家點擊陽光室 2.5D 地板任一處 → 喚來最近的室友開心地小跑過來！
    func callNearestPet(to roomUV: CGPoint, now: Date = Date()) {
        let clamped = CGPoint(
            x: max(0.09, min(0.91, roomUV.x)),
            y: max(0.16, min(0.86, roomUV.y))
        )
        floorRipples.append(FloorTapRipple(position: clamped, createdAt: now))

        guard let nearest = actors.values.min(by: {
            hypot($0.position.x - clamped.x, $0.position.y - clamped.y) <
            hypot($1.position.x - clamped.x, $1.position.y - clamped.y)
        }) else { return }

        var actor = nearest
        let dist = hypot(clamped.x - actor.position.x, clamped.y - actor.position.y)
        let dur = max(1.2, min(4.2, Double(dist) * 6.4))
        actor.facingRight = clamped.x > actor.position.x
        actor.behavior = .walking(from: actor.position, to: clamped, startedAt: now, duration: dur, arrivalSpotIndex: nil)
        actor.speechBubble = "來囉～♪"
        actor.bubbleExpiresAt = now.addingTimeInterval(2.4)
        actor.tapExcitedUntil = now.addingTimeInterval(1.4)
        actors[actor.petID] = actor
    }

    private func findNearbyGreetingPartner(for actor: RoamingPetActor, now: Date) -> RoamingPetActor? {
        for other in actors.values where other.petID != actor.petID {
            if case .sitting = other.behavior {
                let d = hypot(other.position.x - actor.position.x, other.position.y - actor.position.y)
                if d < 0.13 && Int.random(in: 0..<100) < 6 {
                    return other
                }
            }
        }
        return nil
    }

    private func pickNextWalkDestination(from origin: CGPoint, spots: [HomeSpotPlacement], verandaUnlocked: Bool) -> (point: CGPoint, spotIndex: Int?) {
        // 55% 機率走向某個陽光家飾位置（毛毯／軟墊／紙箱），45% 機率在寬敞木地板自由探索漫步！
        if !spots.isEmpty && Int.random(in: 0..<100) < 55 {
            let candidates = spots.filter { spot in
                let p = Self.spot25DPosition(for: spot.spotIndex, verandaUnlocked: verandaUnlocked)
                return hypot(p.x - origin.x, p.y - origin.y) > 0.14
            }
            if let chosen = candidates.randomElement() {
                let p = Self.spot25DPosition(for: chosen.spotIndex, verandaUnlocked: verandaUnlocked)
                return (
                    CGPoint(
                        x: max(0.10, min(0.90, p.x + CGFloat.random(in: -0.04...0.04))),
                        y: max(0.16, min(0.84, p.y + CGFloat.random(in: -0.03...0.03)))
                    ),
                    chosen.spotIndex
                )
            }
        }

        // 自由選一個距離足夠遠的陽光木地板落點
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

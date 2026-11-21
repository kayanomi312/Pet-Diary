import Foundation

struct NarrativeSelection: Sendable {
    let sceneRevisionID: String
    /// 街頭手撕紙條低語（精簡溫柔、不阻擋畫面）
    let streetSlipLine: String
    /// 日記系統客觀紀事（只記可見事實，個人心情留給玩家親筆書寫）
    let diarySystemSentence: String
}

enum NarrativeEngine {
    /// 四層防重複故事挑選器（自動避開該動物最近 3 次的場景 ID）
    static func selectStreetScene(
        pet: PetResidentState,
        secondaryStreetPet: PetSpec? = nil,
        anchorLabel: String,
        weather: WeatherMode,
        chosenGesture: GreetingGesture,
        localDateISO: String,
        pastEncounters: [EncounterLog],
        activeIntentions: [TeachingIntention],
        activeOutingPack: OutingPackKind? = nil
    ) -> NarrativeSelection {
        let spec = PetCatalog.pet(id: pet.petID)
        let projectedDays = (pet.lastSharedDateISO == localDateISO) ? pet.sharedDaysCount : (pet.sharedDaysCount + 1)
        let recent = Set(pet.recentSceneIDs.suffix(3))

        // 雙動物漫步連鎖場景（Stroll Chain）
        if let guide = secondaryStreetPet {
            let rev = "\(pet.petID).stroll_chain.\(guide.id).\(localDateISO)"
            let slip = "\(guide.name)領著路，在\(anchorLabel)的屋簷下把\(spec.name)介紹給你。"
            let diary = "\(guide.name)帶著我多走了一個街口，在\(anchorLabel)一起遇見了\(spec.name)。"
            return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
        }

        // 優先序 1：里程碑章節（Day 1 / Day 3 記得第一天手勢 / Day 6 / Day 10 / Day 15 / Day 25）
        if projectedDays == 1 {
            let rev = "\(pet.petID).milestone.day1.\(chosenGesture.rawValue)"
            let slip = firstMetSlip(for: spec, gesture: chosenGesture, weather: weather)
            let diary = "在\(anchorLabel)初次遇見\(spec.name)，牠\(chosenGesture.diaryVerb)。"
            return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
        }

        if projectedDays == 3, let day1Gesture = pet.firstGesture {
            let rev = "\(pet.petID).milestone.day3.callback.\(day1Gesture.rawValue)"
            if !recent.contains(rev) {
                let slip = day3CallbackSlip(for: spec, day1Gesture: day1Gesture)
                let diary = "\(spec.name)還記得我們初見時「\(day1Gesture.title)」，主動走出來迎上我。"
                return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
            }
        }

        if projectedDays == 6 {
            let rev = "\(pet.petID).milestone.day6.companion"
            if !recent.contains(rev) {
                let slip = "\(spec.name)在\(weather.displayName)裡安穩靠進掌心，喉間傳來細細暖意。"
                let diary = "\(spec.name)像老朋友般在\(anchorLabel)停下腳步，連喜歡的點心口感都記牢了。"
                return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
            }
        }

        if projectedDays == 10 {
            let rev = "\(pet.petID).milestone.day10.kindred"
            if !recent.contains(rev) {
                let slip = "\(spec.name)就在騎樓邊自然地展現出「\(spec.signatureHabitTitle)」。"
                let diary = "\(spec.name)在\(anchorLabel)旁自在地做起牠拿手的「\(spec.signatureHabitTitle)」。"
                return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
            }
        }

        if projectedDays == 15 {
            let rev = "\(pet.petID).milestone.day15.mentor"
            if !recent.contains(rev) {
                let slip = "\(spec.name)眼神沉穩柔和，已經能把「\(spec.signatureHabitTitle)」教給其他室友了。"
                let diary = "\(spec.name)在\(anchorLabel)成了能引領新夥伴的溫柔導師。"
                return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
            }
        }

        if projectedDays >= 25 {
            let rev = "\(pet.petID).milestone.day25.pillar"
            if !recent.contains(rev) {
                let slip = "\(spec.name)安靜地\(spec.matureKindness)"
                let diary = "街角暖心記事（\(anchorLabel)）：\(spec.name)\(spec.matureKindness)"
                return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
            }
        }

        // 雨天步道毛巾組專屬小劇場
        if activeOutingPack == .trailShelterTowel && weather.isRainy {
            let rev = "\(pet.petID).outing.towel_dry.\(localDateISO)"
            let slip = "\(spec.name)乖乖靠進乾毛巾裡，甩掉毛尖上的細細雨珠。"
            let diary = "在\(anchorLabel)的雨簷下，拿步道毛巾替\(spec.name)把毛輕輕擦乾。"
            return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
        }

        // 優先序 2：跨物種傳承計畫回響
        if let active = activeIntentions.first(where: { $0.state != .mastered && ($0.learnerPetID == pet.petID || $0.mentorPetID == pet.petID) }) {
            let partnerID = (active.mentorPetID == pet.petID) ? active.learnerPetID : active.mentorPetID
            let partner = PetCatalog.pet(id: partnerID)
            let rev = "\(pet.petID).mentorship.\(active.habitFamilyID)"
            if !recent.contains(rev) {
                let slip = "\(spec.name)若有所思地停了半拍，像在回想\(partner.name)在家教過的小動作。"
                let diary = "\(spec.name)在\(anchorLabel)悄悄練習著與\(partner.name)一起約好的溫柔習慣。"
                return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
            }
        }

        // 優先序 3：跨日記憶回響（距離 7 天以上的舊日記）
        if let older = pastEncounters.first(where: {
            $0.petID == pet.petID &&
            CivilCalendarHelper.daysBetween(startISO: $0.localDateISO, endISO: localDateISO) >= 7
        }) {
            let rev = "\(pet.petID).memory.\(older.localDateISO)"
            if !recent.contains(rev) {
                let slip = "\(spec.name)在\(anchorLabel)自在待著，比那次\(older.weatherSnapshot.displayName)相遇從容多了。"
                let diary = "\(spec.name)在\(anchorLabel)輕鬆地迎上前，讓人想起\(CivilCalendarHelper.displayDate(from: older.localDateISO))那天的散步。"
                return NarrativeSelection(sceneRevisionID: rev, streetSlipLine: slip, diarySystemSentence: diary)
            }
        }

        // 優先序 4：天氣與日常微風景（自動避開最近 3 則）
        let ambientPool = ambientScenes(for: spec, weather: weather, anchorLabel: anchorLabel)
        return ambientPool.first(where: { !recent.contains($0.sceneRevisionID) }) ?? ambientPool[0]
    }

    private static func firstMetSlip(for spec: PetSpec, gesture: GreetingGesture, weather: WeatherMode) -> String {
        switch spec.id {
        case "pet.01": // 芝麻
            return gesture == .offerHand
                ? "芝麻從木凳下探出頭，白左掌輕點石面，嗅了嗅你的手背。"
                : "芝麻把白左掌收在胸前，在木凳陰影下安靜地望著你。"
        case "pet.02": // 杜松
            return "杜松擺了擺彎鉤尾巴，把一張摺整齊的小紙片推到你鞋邊。"
        case "pet.03": // 餘燼
            return "餘燼在細雨中躲進屋簷，背上的赤陶小鱗透著淡淡暖光。"
        case "pet.04": // 摺翼
            return "摺翼從乾爽的招牌下探頭，細褶的莢果翅膀安靜收在背上。"
        case "pet.05": // 味噌
            return gesture == .rollBall
                ? "味噌小跑接住縫布球，乖乖啣回放在你的鞋尖前。"
                : "味噌歪著那隻折耳，尾巴在微濕的石板上輕輕敲了一下。"
        case "pet.06": // 鈕扣
            return "鈕扣踩著淺色腳趾走近，還順道確認門口的墊子有沒有歪。"
        case "pet.07": // 梅子
            return "銀吻的梅子放慢腳步，不疾不徐地在你衣袖旁停了下來。"
        case "pet.08": // 蘆葦
            return "蘆葦豎起微捲的長耳，往騎樓最乾爽的那塊石階看了看。"
        default:
            return "\(spec.name)在\(weather.displayName)中停下腳步，願意讓你再靠近一步。"
        }
    }

    private static func day3CallbackSlip(for spec: PetSpec, day1Gesture: GreetingGesture) -> String {
        switch day1Gesture {
        case .offerHand:
            return "\(spec.name)還記得你第一次伸出的手，立刻走出來輕蹭你的衣袖。"
        case .crouchQuietly:
            return "\(spec.name)認得你不疾不徐的步調，很快就在你鞋旁安穩坐下。"
        case .rollBall:
            return "\(spec.name)一看到你便豎起耳朵，期待地等著再玩一次滾布球。"
        case .holdUmbrella:
            return "\(spec.name)像熟悉的老鄰居，自然地走進你的乾爽傘簷下。"
        }
    }

    private static func ambientScenes(for spec: PetSpec, weather: WeatherMode, anchorLabel: String) -> [NarrativeSelection] {
        let w = weather.displayName
        return [
            NarrativeSelection(
                sceneRevisionID: "\(spec.id).ambient.\(weather.rawValue).1",
                streetSlipLine: "\(spec.name)在\(w)裡慢慢眨眼，於\(anchorLabel)安靜陪你歇了一會兒。",
                diarySystemSentence: "\(w)時分，\(spec.name)在\(anchorLabel)陪我靜靜待了一會兒。"
            ),
            NarrativeSelection(
                sceneRevisionID: "\(spec.id).ambient.\(weather.rawValue).2",
                streetSlipLine: "\(spec.name)把額頭輕靠進你的手心，隨後望向慢步經過的街景。",
                diarySystemSentence: "\(spec.name)在\(anchorLabel)靠過來討了一次溫柔的招呼。"
            ),
            NarrativeSelection(
                sceneRevisionID: "\(spec.id).ambient.\(weather.rawValue).3",
                streetSlipLine: "\(spec.name)朝屋簷滴水聲轉了轉耳朵，安穩地挨近你的腳邊。",
                diarySystemSentence: "在\(anchorLabel)與\(spec.name)共享了一段安靜的通勤片刻。"
            ),
            NarrativeSelection(
                sceneRevisionID: "\(spec.id).ambient.\(weather.rawValue).4",
                streetSlipLine: "\(spec.name)在老屋瓦簷下耐心候著，好像早知道你今天會經過。",
                diarySystemSentence: "\(spec.name)在\(anchorLabel)的簷下靜靜等我經過。"
            )
        ]
    }
}

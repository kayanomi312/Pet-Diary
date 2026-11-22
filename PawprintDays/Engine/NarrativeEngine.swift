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

        // 雙動物漫步連鎖場景（Stroll Chain）— 依物種配對呈現專屬互動小劇場
        if let guide = secondaryStreetPet {
            let rev = "\(pet.petID).stroll_chain.\(guide.id).\(localDateISO)"
            let (slip, diary) = pairDialogue(primary: spec, secondary: guide, anchorLabel: anchorLabel, weather: weather)
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

    /// 雙寵專屬跨物種對話（用於漫步連鎖與常去街角重逢）
    static func pairDialogue(
        primary: PetSpec,
        secondary: PetSpec,
        anchorLabel: String,
        weather: WeatherMode
    ) -> (slip: String, diary: String) {
        let pairKey = [primary.id, secondary.id].sorted().joined(separator: "+")
        switch pairKey {
        case "pet.01+pet.03": // 芝麻 & 餘燼
            return (
                "芝麻用白左掌輕拍餘燼的背，替緊張到小鱗微紅的牠讓出一塊乾爽石階。",
                "在\(anchorLabel)看見芝麻從容地陪著餘燼，像老母貓照看一隻以為自己是貓的小龍。"
            )
        case "pet.02+pet.06": // 杜松 & 鈕扣
            return (
                "杜松嘴上嫌棄鈕扣的藍紫小鬼火太亮，卻順手幫牠把歪掉的門墊撥正。",
                "在\(anchorLabel)遇見杜松與鈕扣；傲嬌的惡魔貓與忠厚的小魔犬意外很有默契。"
            )
        case "pet.04+pet.08": // 摺翼 & 蘆葦
            return (
                "摺翼在屋簷陰影裡收起暮色小翼，靜靜聽蘆葦搖晃嫩葉鹿角確認風向。",
                "在\(anchorLabel)的騎樓下，摺翼與蘆葦並肩共享了一段安靜微涼的片刻。"
            )
        case "pet.05+pet.07": // 味噌 & 梅子
            return (
                "味噌興沖沖滾來縫布球，梅子溫柔放慢星霧腳步，陪牠輕輕把球推回你腳邊。",
                "在\(anchorLabel)看見味噌和梅子一快一慢地並肩散步，氣氛柔和極了。"
            )
        case "pet.02+pet.03": // 杜松 & 餘燼
            return (
                "杜松遞出方正摺紙符，餘燼好奇湊近一嗅，差點把紙角烘得暖烘烘捲起來。",
                "在\(anchorLabel)撞見杜松與餘燼互相比劃小本領，兩個小傢伙都認真得可愛。"
            )
        case "pet.01+pet.04": // 芝麻 & 摺翼
            return (
                "芝麻安穩伏在木凳上，摺翼張開細褶蝠翼替牠擋住斜射過來的光線。",
                "在\(anchorLabel)看見芝麻與摺翼安靜相伴，誰也沒說話卻格外安心。"
            )
        case "pet.03+pet.05": // 餘燼 & 味噌
            return (
                "味噌把最心愛的布球滾給餘燼，餘燼小心翼翼收起爪尖，把球烘得暖暖地推回去。",
                "在\(anchorLabel)看見味噌熱情邀約餘燼玩球，小龍貓臉上露出了藏不住的笑意。"
            )
        case "pet.01+pet.02": // 芝麻 & 杜松
            return (
                "杜松高傲地抬著黑曜小角，卻乖乖坐在芝麻身旁讓牠替自己理順耳尖。",
                "在\(anchorLabel)遇見芝麻與杜松；再講究的惡魔貓在老街守護者面前也變溫順了。"
            )
        case "pet.06+pet.08": // 鈕扣 & 蘆葦
            return (
                "蘆葦找出騎樓最乾爽的石板，鈕扣馬上在旁邊亮起溫和微火替路人標出好走的路。",
                "在\(anchorLabel)看見鈕扣與蘆葦默契十足地守在轉角，彷彿街區的小小巡守隊。"
            )
        case "pet.04+pet.07": // 摺翼 & 梅子
            return (
                "摺翼的星塵羽翼映著梅子的柔白雲氣，兩道安靜的身影把轉角襯得像繪本一頁。",
                "在\(anchorLabel)的\(weather.displayName)裡遇見摺翼與梅子並肩靜坐。"
            )
        default:
            return (
                "\(secondary.name)領著路，在\(anchorLabel)的屋簷下把\(primary.name)溫柔介紹給你。",
                "\(secondary.name)帶著我多走了一個街口，在\(anchorLabel)一起遇見了\(primary.name)。"
            )
        }
    }

    /// 依物種、時段與天氣產生的「街角順路探望」生動微場景
    static func revisitVignette(
        pet: PetSpec,
        secondary: PetSpec?,
        anchorLabel: String,
        timeBandKey: String,
        weather: WeatherMode
    ) -> String {
        if let secondary {
            return pairDialogue(primary: pet, secondary: secondary, anchorLabel: anchorLabel, weather: weather).slip
        }
        switch (pet.id, timeBandKey) {
        case ("pet.01", "morning"):
            return "芝麻端坐在「\(anchorLabel)」的晨光木凳上，白左掌收得整整齊齊，目送街坊出門。"
        case ("pet.01", "afternoon"):
            return "午後的「\(anchorLabel)」靜悄悄，芝麻瞇著眼替經過的小麻雀讓出半塊石階。"
        case ("pet.01", _):
            return "傍晚燈色亮起，芝麻仍守在「\(anchorLabel)」轉角，像在清點街區夥伴都回家了沒。"

        case ("pet.02", "morning"):
            return "杜松在「\(anchorLabel)」把一張小紙片壓平，瞄了你一眼又裝作只是剛好經過。"
        case ("pet.02", "afternoon"):
            return "杜松蜷在「\(anchorLabel)」最整潔的陰影處打盹，黑曜小角在微風裡微微晃動。"
        case ("pet.02", _):
            return "暮色降臨，杜松在「\(anchorLabel)」輕甩彎鉤尾，把一張晚安小摺紙推到石階邊。"

        case ("pet.03", "morning"):
            return "晨涼時分，餘燼在「\(anchorLabel)」悄悄哈出一口微溫氣息，把冰涼的石面烘暖。"
        case ("pet.03", "afternoon"):
            return "餘燼正認真學著普通貓咪在「\(anchorLabel)」理毛，背上的赤陶小鱗卻透著暖烘烘的光。"
        case ("pet.03", _):
            return "夜風起時，餘燼靠在「\(anchorLabel)」牆角打起小呼嚕，像一盞小小暖爐。"

        case ("pet.04", "morning"):
            return "早晨陽光太亮，摺翼在「\(anchorLabel)」招牌陰影裡把暮色蝠翼收得像把小摺扇。"
        case ("pet.04", "afternoon"):
            return "摺翼在「\(anchorLabel)」悄悄探出圓眼，好奇盯著風裡打轉的落葉看了好一會兒。"
        case ("pet.04", _):
            return "黃昏是摺翼最自在的時刻，牠在「\(anchorLabel)」輕輕舒展星塵小翼向你點頭。"

        case ("pet.05", "morning"):
            return "味噌在「\(anchorLabel)」早早搖著尾巴，看到熟面孔路過立刻輕快地踏了兩下小碎步。"
        case ("pet.05", "afternoon"):
            return "味噌把下巴擱在「\(anchorLabel)」木椅腳邊小憩，那隻可愛的折耳一聽到腳步聲便豎起來。"
        case ("pet.05", _):
            return "晚歸經過「\(anchorLabel)」時，味噌暖烘烘地迎上前半步，好像說著「今天也辛苦了」。"

        case ("pet.06", "morning"):
            return "鈕扣一早就在「\(anchorLabel)」巡視乾爽的門口地墊，肩畔的小紫火安靜閃爍。"
        case ("pet.06", "afternoon"):
            return "午後的「\(anchorLabel)」涼風徐徐，鈕扣安穩趴在門檻旁替小店看顧著門口。"
        case ("pet.06", _):
            return "天色漸暗，鈕扣在「\(anchorLabel)」點起柔和的藍紫微光，悄悄照亮了轉角石階。"

        case ("pet.07", "morning"):
            return "梅子披著晨間柔白雲絮，在「\(anchorLabel)」以不疾不徐的步調向你微微點頭。"
        case ("pet.07", "afternoon"):
            return "梅子在「\(anchorLabel)」的微風中安詳小睡，周身縈繞著淡淡的星霧氣息。"
        case ("pet.07", _):
            return "傍晚雲影染金，梅子在「\(anchorLabel)」放慢呼吸，陪你把一天的匆忙輕輕放下。"

        case ("pet.08", "morning"):
            return "蘆葦在「\(anchorLabel)」抖落鹿角嫩葉上的晨露，替你指了指最乾爽好走的一側。"
        case ("pet.08", "afternoon"):
            return "蘆葦豎起長耳聽著「\(anchorLabel)」樹梢風聲，神情專注又帶著森林氣息。"
        case ("pet.08", _):
            return "暮色裡，蘆葦頭頂的小葉鹿角透出一絲螢火柔光，在「\(anchorLabel)」靜靜目送你返家。"

        default:
            return "\(pet.name)在「\(anchorLabel)」安靜待著，看見你再次經過便溫柔眨了眨眼。"
        }
    }

    /// 64 則以上「物種 × 天氣」專屬日常繪本微風景（嚴格對應晴、陰、雨、暮四種氣象，不再晴天說雨聲）
    private static func ambientScenes(for spec: PetSpec, weather: WeatherMode, anchorLabel: String) -> [NarrativeSelection] {
        let weatherGroup: String
        switch weather {
        case .clearMorning: weatherGroup = "clear"
        case .lightRain, .postRain: weatherGroup = "rain"
        case .dusk: weatherGroup = "dusk"
        case .overcast: weatherGroup = "overcast"
        }

        let pairs: [(slip: String, diary: String)] = speciesWeatherLines(
            petID: spec.id,
            petName: spec.name,
            weatherGroup: weatherGroup,
            weatherLabel: weather.displayName,
            anchorLabel: anchorLabel
        )

        return pairs.enumerated().map { idx, item in
            NarrativeSelection(
                sceneRevisionID: "\(spec.id).ambient.\(weatherGroup).\(idx + 1)",
                streetSlipLine: item.slip,
                diarySystemSentence: item.diary
            )
        }
    }

    private static func speciesWeatherLines(
        petID: String,
        petName: String,
        weatherGroup: String,
        weatherLabel: String,
        anchorLabel: String
    ) -> [(String, String)] {
        switch (petID, weatherGroup) {
        // MARK: pet.01 芝麻（沉靜守望的森林老母貓氣質）
        case ("pet.01", "clear"):
            return [
                ("芝麻在\(anchorLabel)的晴朗木凳上收攏白左掌，瞇著眼享受剛曬暖的陽光。", "晴日裡，芝麻在\(anchorLabel)的陽光木凳上安穩陪我歇了一會兒。"),
                ("晨風拂過灰白毛尖，芝麻緩緩眨了兩下眼，像老街裡最沉靜的守門人。", "在\(anchorLabel)遇見神色從容的芝麻，早晨步調也跟著慢了下來。")
            ]
        case ("pet.01", "rain"):
            return [
                ("細雨敲著屋瓦，芝麻把白左掌退到騎樓乾處，還刻意往旁邊讓出一小塊乾燥位置。", "雨天經過\(anchorLabel)，芝麻在騎樓乾爽處靜靜陪我聽了一會兒雨。"),
                ("芝麻望著石板上的雨圈慢慢暈開，喉間響起比雨聲更安穩的呼嚕。", "在\(anchorLabel)的雨簷下與芝麻並肩躲雨，格外安心。")
            ]
        case ("pet.01", "dusk"):
            return [
                ("橘紅晚霞映在芝麻灰白毛色上，牠在\(anchorLabel)靜靜等著熟識的晚歸腳步。", "黃昏路過\(anchorLabel)，芝麻像往常一樣在簷下安靜守望。"),
                ("芝麻輕蹭過你的腳踝，眼神溫厚得彷彿在確認你今天走得平不平安。", "暮色裡的\(anchorLabel)，芝麻給了我一個沉靜溫柔的招呼。")
            ]
        case ("pet.01", _):
            return [
                ("微涼陰天裡，芝麻端坐在\(anchorLabel)的轉角木箱上，安靜看著往來街坊。", "微陰的\(anchorLabel)，芝麻安穩守在老位置向我點頭。"),
                ("芝麻把尾巴整齊繞在腳邊，像一本攤開在街角的安靜速寫本。", "在\(anchorLabel)和芝麻共度了一段不疾不徐的散步片刻。")
            ]

        // MARK: pet.02 杜松（傲嬌講究的貓型小惡魔）
        case ("pet.02", "clear"):
            return [
                ("杜松嫌陽光有點刺眼卻又忍不住曬暖，嘴硬地把一張方正小紙符推到你腳邊。", "晴天在\(anchorLabel)遇見杜松，牠高傲地留下一張摺得筆直的小紙片。"),
                ("黑曜小角在晴空下泛著微光，杜松整理好領口毛才矜持地讓你摸了一下頭頂。", "在\(anchorLabel)和格外講究儀態的杜松打了招呼。")
            ]
        case ("pet.02", "rain"):
            return [
                ("杜松一滴雨也不願沾到毛尖，端正坐在\(anchorLabel)屋簷最裡面輕甩彎鉤尾巴。", "雨天的\(anchorLabel)，講究的杜松把毛理得乾乾淨淨等在簷下。"),
                ("「惡魔才不怕雨」——杜松雖這麼擺出架勢，卻悄悄靠進你身旁避風。", "在\(anchorLabel)避雨時，傲嬌的杜松悄悄挨近了我的衣角。")
            ]
        case ("pet.02", "dusk"):
            return [
                ("黃昏是杜松最得意的時段，牠昂起小黑角在\(anchorLabel)優雅地向你行了個貓式致意。", "暮色降臨\(anchorLabel)，杜松神氣又溫柔地出來迎上了我。"),
                ("路燈映著杜松酒紅色的眼眸，牠把一顆撿來的小石子排在磚縫正中央。", "傍晚在\(anchorLabel)看見杜松正認真擺放牠的小收藏。")
            ]
        case ("pet.02", _):
            return [
                ("陰涼微風很合杜松心意，牠在\(anchorLabel)慢條斯理地晃著彎鉤尾等你靠近。", "陰天在\(anchorLabel)遇見心情頗佳的杜松，難得主動蹭了手背。"),
                ("杜松歪頭打量你的鞋帶，接著滿意地點點頭，彷彿批准你繼續今天的散步。", "在\(anchorLabel)與一絲不苟的杜松交換了默契眼神。")
            ]

        // MARK: pet.03 餘燼（把自己當普通小貓的赤炎幼龍）
        case ("pet.03", "clear"):
            return [
                ("餘燼學著街貓在\(anchorLabel)曬太陽，背上赤陶小鱗吸飽晨光後暖得像剛出爐的麵包。", "晴朗的\(anchorLabel)，餘燼背上的小龍鱗在陽光下暖洋洋的。"),
                ("餘燼想發出可愛的喵嗚聲，結果鼻尖冒出一縷比蒲公英還輕的小暖煙。", "在\(anchorLabel)遇見努力裝成普通小貓的餘燼，讓人會心一笑。")
            ]
        case ("pet.03", "rain"):
            return [
                ("細雨微涼，餘燼貼心地把微溫的尾巴繞近你鞋邊，連周遭濕氣都被悄悄烘乾。", "雨天在\(anchorLabel)遇見餘燼，牠身上散發著爐火般的溫柔暖意。"),
                ("雨珠落在餘燼的赤陶鱗片上化作淡淡白霧，牠害羞地縮了縮前掌靠進你掌心。", "雨中經過\(anchorLabel)，餘燼暖烘烘地替這段路添了許多溫度。")
            ]
        case ("pet.03", "dusk"):
            return [
                ("暮色裡，餘燼背上的赤陶龍鱗透出炭火般柔和的橘紅微光，把\(anchorLabel)照得暖融融。", "黃昏在\(anchorLabel)看見發著微弱暖光的餘燼，像遇見一盞走動的小提燈。"),
                ("餘燼輕聲呼嚕著靠進你掌心，那份剛好的溫度剛好驅散傍晚的微涼。", "傍晚於\(anchorLabel)與暖呼呼的餘燼道了聲晚安。")
            ]
        case ("pet.03", _):
            return [
                ("微陰天氣裡，餘燼在\(anchorLabel)替一塊冰涼石階烘出暖度，然後邀請你一起歇腳。", "陰天在\(anchorLabel)遇見溫柔細心的餘燼，連空氣都暖和起來。"),
                ("餘燼小心翼翼把小爪子收好怕燙著你，卻還是忍不住用額頭輕輕頂了頂手心。", "在\(anchorLabel)和體貼的小龍貓餘燼共享了安靜片刻。")
            ]

        // MARK: pet.04 摺翼（好奇安靜的暮色蝠翼貓）
        case ("pet.04", "clear"):
            return [
                ("晴天光線明亮，摺翼在\(anchorLabel)的涼蔭處展開細褶暮色小翼，像撐起一把迷你遮陽傘。", "晴日在\(anchorLabel)的樹蔭下遇見摺翼，牠好奇地探出圓滾滾的雙眼。"),
                ("摺翼把星塵蝠翼妥貼摺在背上，安靜觀察著陽光裡飛舞的微小塵埃。", "早晨在\(anchorLabel)和安靜又充滿好奇心的摺翼打了招呼。")
            ]
        case ("pet.04", "rain"):
            return [
                ("雨天柔和的天光讓摺翼格外自在，牠在\(anchorLabel)簷下輕輕抖動細褶小翼聽雨聲。", "細雨裡的\(anchorLabel)，摺翼放鬆地舒展翅膀陪我歇了一會兒。"),
                ("摺翼躲在乾爽招牌下方，見你走近便悄悄往下探了半個小腦袋。", "雨日經過\(anchorLabel)，摺翼在招牌陰影下安靜地向我致意。")
            ]
        case ("pet.04", "dusk"):
            return [
                ("暮色漸沉，摺翼背上的星塵小翼與晚空融為一體，牠輕盈跳上\(anchorLabel)低牆向你點頭。", "黃昏是摺翼的主場，在\(anchorLabel)看見牠舒展夜色小翼的模樣美極了。"),
                ("摺翼輕輕靠上你的手背，涼絲絲的羽翼邊緣帶著傍晚微風的清甜氣息。", "傍晚在\(anchorLabel)與摺翼共享了最柔和的暮色時光。")
            ]
        case ("pet.04", _):
            return [
                ("雲層柔柔遮住烈日，摺翼在\(anchorLabel)自在地眨著紫灰色大眼，好奇嗅了嗅你的袖口。", "微陰的\(anchorLabel)正適合摺翼散步，牠安靜陪我停留了一會兒。"),
                ("摺翼把翅膀收成俐落的摺紙形狀，端正坐在石階旁靜靜望著街道。", "在\(anchorLabel)遇見安靜觀察街景的摺翼。")
            ]

        // MARK: pet.05 味噌（熱情好客的折耳小黃狗）
        case ("pet.05", "clear"):
            return [
                ("晴朗陽光灑在蜜糖色毛背上，味噌在\(anchorLabel)快活搖著尾巴，折耳一跳一跳迎上來。", "晴天在\(anchorLabel)遇見精神滿滿的味噌，被牠熱情的尾巴掃散了倦意。"),
                ("味噌小心把一顆乾燥小果實推到你鞋尖旁，眼神亮晶晶地等著你誇獎。", "在\(anchorLabel)與熱情好客的味噌開心打了招呼。")
            ]
        case ("pet.05", "rain"):
            return [
                ("雖然下著雨，味噌仍在\(anchorLabel)乾爽騎樓裡用力搖尾巴，甩落幾顆晶亮的小水珠。", "雨天經過\(anchorLabel)，味噌依然笑臉盈盈地迎上前打招呼。"),
                ("味噌乖巧地把濕答答的鼻尖縮回乾燥簷下，等你蹲下來摸摸牠柔軟的折耳。", "在\(anchorLabel)的雨簷下摸了摸味噌毛茸茸的折耳，心情立刻放晴。")
            ]
        case ("pet.05", "dusk"):
            return [
                ("夕陽把味噌的奶油耳朵染成金黃色，牠在\(anchorLabel)輕快踏步歡迎你結束忙碌一天。", "傍晚在\(anchorLabel)遇見守候已久的味噌，牠開心地繞著腳邊轉了半圈。"),
                ("味噌在路燈下安靜坐好，把溫暖的腦袋靠進你的掌心久久不肯離開。", "黃昏路過\(anchorLabel)，味噌給了我一個最真誠溫暖的迎接。")
            ]
        case ("pet.05", _):
            return [
                ("微風涼爽的陰天裡，味噌在\(anchorLabel)活力十足卻又懂得配合你的步調慢慢走。", "陰天在\(anchorLabel)遇見體貼的味噌，牠溫柔地陪我走了幾步。"),
                ("味噌歪著那隻可愛折耳聽你說話，尾巴在石板上拍出輕快的節拍。", "在\(anchorLabel)和愛撒嬌的味噌度過了輕鬆片刻。")
            ]

        // MARK: pet.06 鈕扣（忠厚貼心、伴著藍紫微火的小魔犬）
        case ("pet.06", "clear"):
            return [
                ("晴朗早晨裡，鈕扣把肩畔小紫火收得小小一顆，認真替\(anchorLabel)把門口的墊子撫平。", "晴日在\(anchorLabel)看見忠厚的鈕扣正細心整理轉角地墊。"),
                ("鈕扣踩著淺色小腳趾慢步走來，頭頂圓潤小魔角被晨光鍍上一圈暖邊。", "在\(anchorLabel)與踏實溫柔的小魔犬鈕扣打了招呼。")
            ]
        case ("pet.06", "rain"):
            return [
                ("雨絲飄落時，鈕扣肩旁的藍紫微火依舊安穩亮著，像在\(anchorLabel)替你標出乾爽落腳處。", "雨天經過\(anchorLabel)，鈕扣用微弱藍紫幽火替我照亮了騎樓石階。"),
                ("鈕扣低頭嗅了嗅濕潤的空氣，貼心地靠在你外側擋住一陣斜吹的小雨風。", "在\(anchorLabel)遇見默默守護的鈕扣，心裡暖烘烘的。")
            ]
        case ("pet.06", "dusk"):
            return [
                ("暮色轉暗，鈕扣肩畔的小鬼火變得格外柔和清亮，在\(anchorLabel)替晚歸的路人點燈。", "黃昏在\(anchorLabel)遇見提著藍紫微光的鈕扣，像遇見巷口的溫柔守夜犬。"),
                ("鈕扣安穩坐在門檻邊，確認你走穩了石階才滿足地輕搖一下短尾。", "傍晚在\(anchorLabel)與忠厚細心的鈕扣道了晚安。")
            ]
        case ("pet.06", _):
            return [
                ("陰天微涼，鈕扣在\(anchorLabel)安靜守在轉角，見你走近便禮貌地低下小魔角讓你輕撫。", "陰天在\(anchorLabel)遇見沉穩貼心的鈕扣，牠安靜靠在我身旁歇息。"),
                ("鈕扣把一塊歪掉的小木牌輕輕頂正，接著回頭朝你露出憨厚安心的神情。", "在\(anchorLabel)看著認真的鈕扣整理街角，覺得格外療癒。")
            ]

        // MARK: pet.07 梅子（銀吻星靈犬、伴著柔白雲絮）
        case ("pet.07", "clear"):
            return [
                ("晨光穿過梅子身周淡淡的柔白雲絮，牠在\(anchorLabel)放慢呼吸，陪你享有一份寧靜。", "晴天在\(anchorLabel)遇見梅子，柔和的雲氣讓整個街角都慢了下來。"),
                ("銀吻的梅子優雅地停下腳步，眼裡映著晴空與輕飄飄的晨雲。", "在\(anchorLabel)和溫和從容的星靈犬梅子並肩停駐。")
            ]
        case ("pet.07", "rain"):
            return [
                ("雨霧與梅子身邊的白雲氣息融在一起，牠在\(anchorLabel)輕聲嘆了口安穩的氣，令人心靜。", "細雨裡的\(anchorLabel)，梅子像一朵溫柔落地的雲靜靜伴在身旁。"),
                ("梅子不急著躲雨也不急著走，只溫柔陪你站在\(anchorLabel)看雨絲細細落下。", "在\(anchorLabel)與梅子共度了一段像詩一樣安靜的雨天片刻。")
            ]
        case ("pet.07", "dusk"):
            return [
                ("晚霞把梅子的雲絮染成淡金色，點點微星在牠步履間悄然閃爍於\(anchorLabel)。", "黃昏在\(anchorLabel)遇見身上泛著星霧光暈的梅子，美得像一場溫柔的夢。"),
                ("梅子放慢步伐配合你歸家的節奏，好像在說「不必趕路，慢慢來就好」。", "傍晚路過\(anchorLabel)，梅子以緩慢安穩的步調撫平了一天的疲憊。")
            ]
        case ("pet.07", _):
            return [
                ("雲厚風輕的陰天最襯梅子的銀白毛色，牠在\(anchorLabel)安詳閉眼感受微風。", "陰天在\(anchorLabel)遇見平靜溫和的梅子，連呼吸都自然慢了下來。"),
                ("梅子輕輕靠上你的衣袖，留下一點清淡柔和的雲霧暖意。", "在\(anchorLabel)獲得了梅子溫柔且耐心的陪伴。")
            ]

        // MARK: pet.08 蘆葦（頭頂抽著嫩綠鹿角的森靈犬）
        case ("pet.08", "clear"):
            return [
                ("晴朗日光下，蘆葦鹿角上的嫩綠新葉閃著朝露光澤，牠在\(anchorLabel)輕快地向你點頭。", "晴天在\(anchorLabel)遇見蘆葦，牠頭頂的嫩葉鹿角散發著清晨森林的清新氣息。"),
                ("蘆葦靈敏地聽著遠處鳥鳴，帶著你望向\(anchorLabel)枝葉間漏下的斑駁光影。", "在\(anchorLabel)與敏銳清新的森靈犬蘆葦共享了早晨微光。")
            ]
        case ("pet.08", "rain"):
            return [
                ("雨水讓蘆葦頭頂的嫩葉更加翠綠，牠一眼便在\(anchorLabel)替你找到最乾燥的石階。", "雨天在\(anchorLabel)遇見蘆葦，牠細心地領著我避開了積水處。"),
                ("蘆葦輕晃帶著雨珠的鹿角，空氣裡頓時多了一縷雨後青苔與檜木的清香。", "細雨中經過\(anchorLabel)，蘆葦帶來了一陣清新的林間氣息。")
            ]
        case ("pet.08", "dusk"):
            return [
                ("黃昏微光裡，蘆葦的小葉鹿角透出點點螢火般的青綠柔光，在\(anchorLabel)靜靜迎接你。", "傍晚在\(anchorLabel)看見鹿角發著微光的蘆葦，宛如森林派來的溫柔嚮導。"),
                ("蘆葦豎起微捲長耳傾聽晚風，安靜陪你在\(anchorLabel)看天色慢慢轉藍。", "暮色裡的\(anchorLabel)，蘆葦安穩陪我走過了一小段歸途。")
            ]
        case ("pet.08", _):
            return [
                ("陰天微風吹動蘆葦鹿角上的細葉，牠在\(anchorLabel)專注辨認風裡傳來的花草香氣。", "陰天在\(anchorLabel)遇見神情專注又細心的蘆葦。"),
                ("蘆葦輕輕用鼻尖碰了碰你的手背，傳來一絲宛如森林小徑的清爽氣息。", "在\(anchorLabel)與溫柔靈敏的蘆葦度過了平靜片刻。")
            ]

        default:
            return [
                ("\(petName)在\(weatherLabel)裡慢慢眨眼，於\(anchorLabel)安靜陪你歇了一會兒。", "\(weatherLabel)時分，\(petName)在\(anchorLabel)陪我靜靜待了一會兒。"),
                ("\(petName)把額頭輕靠進你的手心，隨後望向慢步經過的街景。", "\(petName)在\(anchorLabel)靠過來討了一次溫柔的招呼。")
            ]
        }
    }
}

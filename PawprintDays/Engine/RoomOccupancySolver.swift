import Foundation

enum RoomOccupancySolver {
    /// Populates visible Home spots smoothly using four gentle, non-punitive factors:
    /// 1. Placed Goodie Affinity
    /// 2. Weather & Time Resonance
    /// 3. Pinned Favorites & Active Mentorship Pairings
    /// 4. Anti-Neglect Freshness Rotation
    static func solveRoom(
        spots: [HomeSpotPlacement],
        residents: [PetResidentState],
        activeIntentions: [TeachingIntention],
        weather: WeatherMode,
        now: Date = Date()
    ) {
        let invited = residents.filter { $0.inviteState == .invitedHome }
        for spot in spots {
            spot.currentOccupantPetIDs = []
            spot.lastSolvedUTC = now
        }
        guard !invited.isEmpty else { return }

        var assignedPetIDs = Set<String>()

        // 1. Prioritize active Mentorship pair on their shared prop spot
        for intention in activeIntentions where intention.state != .mastered {
            guard invited.contains(where: { $0.petID == intention.mentorPetID }),
                  invited.contains(where: { $0.petID == intention.learnerPetID }) else { continue }
            if let matchingSpot = spots.first(where: { $0.equippedGoodieID == intention.sharedPropID }) ?? spots.first {
                matchingSpot.currentOccupantPetIDs = [intention.mentorPetID, intention.learnerPetID]
                matchingSpot.goodieUseCount += 1
                assignedPetIDs.insert(intention.mentorPetID)
                assignedPetIDs.insert(intention.learnerPetID)
            }
        }

        // 2. Score remaining pets for each open spot
        for spot in spots.sorted(by: { $0.spotIndex < $1.spotIndex }) {
            let capacity = spotCapacity(for: spot)
            var current = spot.currentOccupantPetIDs

            while current.count < capacity {
                let remaining = invited.filter { !assignedPetIDs.contains($0.petID) }
                guard !remaining.isEmpty else { break }

                let best = remaining.max { lhs, rhs in
                    score(pet: lhs, for: spot, weather: weather, now: now) <
                    score(pet: rhs, for: spot, weather: weather, now: now)
                }

                guard let chosen = best else { break }
                current.append(chosen.petID)
                assignedPetIDs.insert(chosen.petID)
                chosen.lastSeenInHomeUTC = now
            }

            if !current.isEmpty && spot.currentOccupantPetIDs.isEmpty {
                spot.goodieUseCount += 1
            }
            spot.currentOccupantPetIDs = current
        }
    }

    static func spotCapacity(for spot: HomeSpotPlacement) -> Int {
        guard let goodieID = spot.equippedGoodieID,
              let item = ShopCatalog.item(id: goodieID) else {
            return 1
        }
        return max(1, item.capacitySlots)
    }

    private static func score(
        pet: PetResidentState,
        for spot: HomeSpotPlacement,
        weather: WeatherMode,
        now: Date
    ) -> Double {
        let spec = PetCatalog.pet(id: pet.petID)
        var total = 1.0

        // Factor 1: Placed Goodie Affinity
        if let goodieID = spot.equippedGoodieID, spec.favoriteGoodieIDs.contains(goodieID) {
            total += 4.5
        }

        // Factor 2: Weather & Time Resonance
        if spec.resonantWeathers.contains(weather) {
            total += 2.5
            // Rain-watchers gravitate to Spot 1 (Window Ledge)
            if weather.isRainy && spot.spotIndex == 1 {
                total += 2.0
            }
        }

        // Factor 3: Pinned Favorites
        if pet.isPinned {
            total += 3.0
        }

        // Factor 4: Anti-Neglect Freshness Rotation
        if let lastSeen = pet.lastSeenInHomeUTC {
            let hoursSinceSeen = now.timeIntervalSince(lastSeen) / 3600.0
            total += min(4.0, max(0.0, hoursSinceSeen * 0.25))
        } else {
            total += 3.5 // Never seen at Home yet -> gentle immediate welcome
        }

        return total
    }
}

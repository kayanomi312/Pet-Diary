import Foundation
import CoreLocation

enum AnchorProximityCheck: Equatable, Sendable {
    case eligible(distanceM: Double)
    case tooFar(distanceM: Double, maxRadiusM: Double)
    case poorAccuracy(accuracyM: Double)
    case staleFix(ageSeconds: Double)
    case movingTooFast
    case alreadyMetToday
}

enum AnchorRotationEngine {
    static let maxActivationRadiusM: Double = 75.0
    static let maxHorizontalAccuracyM: Double = 40.0
    static let maxFixAgeSeconds: Double = 30.0
    static let maxPersonalFamiliarCorners: Int = 3

    /// Strict real-world proximity gate: distance <= 75m, accuracy <= 40m, fix age <= 30s, speed <= 12 km/h.
    static func evaluateProximity(
        anchor: AnchorSiteRecord,
        userLocation: CLLocation,
        now: Date = Date(),
        currentLocalDateISO: String
    ) -> AnchorProximityCheck {
        if anchor.lastVisitedLocalDate == currentLocalDateISO {
            return .alreadyMetToday
        }

        if userLocation.speed > LocationService.maxPedestrianSpeedMPS {
            return .movingTooFast
        }

        let fixAge = max(0, now.timeIntervalSince(userLocation.timestamp))
        if fixAge > maxFixAgeSeconds {
            return .staleFix(ageSeconds: fixAge)
        }

        if userLocation.horizontalAccuracy < 0 || userLocation.horizontalAccuracy > maxHorizontalAccuracyM {
            return .poorAccuracy(accuracyM: userLocation.horizontalAccuracy)
        }

        let anchorLocation = CLLocation(latitude: anchor.lat, longitude: anchor.lon)
        let distance = userLocation.distance(from: anchorLocation)
        let effectiveRadius = min(anchor.radiusM, maxActivationRadiusM)
        if distance > effectiveRadius {
            return .tooFar(distanceM: distance, maxRadiusM: effectiveRadius)
        }

        return .eligible(distanceM: distance)
    }

    /// Resolves which animal is waiting at this anchor using the 2-1-1 deterministic rotation
    /// across the full 8-pet launch roster and immediately caches `cachedVisitorOfferID` to prevent reload rerolling.
    static func resolveAndPersistOfferedPetID(
        anchor: AnchorSiteRecord,
        residents: [PetResidentState],
        ledger: WalletAndCurioLedger,
        availableSlicePetIDs: [String] = PetCatalog.allPets.map(\.id)
    ) -> String {
        if let cached = anchor.cachedVisitorOfferID, !cached.isEmpty {
            return cached
        }

        let turnIndex = anchor.cycleTapCount % 4
        let chosenPetID: String

        switch turnIndex {
        case 0, 1:
            // Taps 1 & 2: Site Regular
            chosenPetID = anchor.regularPetID

        case 2:
            // Tap 3: Eligible Unseen Visitor.
            // Pilot Guarantee: player's very first Tap-3 opportunity offers Cinder (pet.03) or Hem (pet.04).
            if !ledger.pilotTap3MagicalDelivered {
                let cinderMet = residents.first(where: { $0.petID == "pet.03" })?.inviteState != .unmet
                chosenPetID = (cinderMet || anchor.regularPetID == "pet.03") ? "pet.04" : "pet.03"
            } else {
                let candidates = availableSlicePetIDs.filter { $0 != anchor.regularPetID }
                let unseen = candidates.filter { id in
                    residents.first(where: { $0.petID == id })?.inviteState == .unmet
                }
                if let firstUnseen = unseen.first {
                    chosenPetID = firstUnseen
                } else {
                    let sorted = candidates.sorted { lhs, rhs in
                        let lDate = residents.first(where: { $0.petID == lhs })?.lastSharedDateISO ?? ""
                        let rDate = residents.first(where: { $0.petID == rhs })?.lastSharedDateISO ?? ""
                        return lDate < rDate
                    }
                    chosenPetID = sorted.first ?? anchor.regularPetID
                }
            }

        default:
            // Tap 4: Dynamic Callback, Visiting Friend, or Site Regular mature story
            let invitedFriends = residents.filter {
                $0.inviteState == .invitedHome &&
                $0.petID != anchor.regularPetID &&
                availableSlicePetIDs.contains($0.petID)
            }
            if let friend = invitedFriends.sorted(by: { ($0.lastSharedDateISO ?? "") < ($1.lastSharedDateISO ?? "") }).first {
                chosenPetID = friend.petID
            } else {
                chosenPetID = anchor.regularPetID
            }
        }

        anchor.cachedVisitorOfferID = chosenPetID
        return chosenPetID
    }

    /// Advances the 4-tap rotation strictly on a completed on-site encounter (never on calendar absence).
    static func commitCompletedTap(
        anchor: AnchorSiteRecord,
        offeredPetID: String,
        localDateISO: String,
        ledger: WalletAndCurioLedger
    ) {
        let wasTap3 = (anchor.cycleTapCount % 4) == 2
        if wasTap3 && (offeredPetID == "pet.03" || offeredPetID == "pet.04") {
            ledger.pilotTap3MagicalDelivered = true
        }
        anchor.cycleTapCount = (anchor.cycleTapCount + 1) % 4
        anchor.lastVisitedLocalDate = localDateISO
        anchor.cachedVisitorOfferID = nil
    }

    /// Picks an optional nearby unvisited walkable paw (preferring 120–380m) for a Multi-Paw Stroll Chain.
    static func pickStrollChainTarget(
        from source: AnchorSiteRecord,
        allAnchors: [AnchorSiteRecord],
        currentLocalDateISO: String
    ) -> AnchorSiteRecord? {
        let sourceLoc = CLLocation(latitude: source.lat, longitude: source.lon)
        let candidates = allAnchors.filter {
            $0.siteID != source.siteID &&
            !$0.isHiddenByUser &&
            $0.lastVisitedLocalDate != currentLocalDateISO
        }
        let sorted = candidates.sorted { a, b in
            let dA = sourceLoc.distance(from: CLLocation(latitude: a.lat, longitude: a.lon))
            let dB = sourceLoc.distance(from: CLLocation(latitude: b.lat, longitude: b.lon))
            return abs(dA - 260) < abs(dB - 260)
        }
        return sorted.first
    }

    /// Computes a coordinate N meters ahead along a bearing for 'Pin Familiar Corner 60m Ahead'.
    static func coordinateAhead(from origin: CLLocationCoordinate2D, meters: Double = 60.0, bearingDegrees: Double = 35.0) -> CLLocationCoordinate2D {
        let earthRadius = 6_378_137.0
        let bearing = bearingDegrees * .pi / 180.0
        let lat1 = origin.latitude * .pi / 180.0
        let lon1 = origin.longitude * .pi / 180.0
        let angularDist = meters / earthRadius

        let lat2 = asin(sin(lat1) * cos(angularDist) + cos(lat1) * sin(angularDist) * cos(bearing))
        let lon2 = lon1 + atan2(
            sin(bearing) * sin(angularDist) * cos(lat1),
            cos(angularDist) - sin(lat1) * sin(lat2)
        )
        return CLLocationCoordinate2D(latitude: lat2 * 180.0 / .pi, longitude: lon2 * 180.0 / .pi)
    }
}

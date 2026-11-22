import Foundation
import MapKit
import CoreLocation

struct DiscoveredWalkableAnchor: Sendable {
    let siteID: String
    let label: String
    let latitude: Double
    let longitude: Double
}

/// Real-world Tier A Pedestrian Anchor Discovery (Blueprint Chapter 3):
/// Queries MapKit strictly for safe walkable categories (.park, .publicTransport, .library, .cafe, .bakery)
/// anywhere in the world — zero server required.
enum MapKitAnchorDiscoveryService {
    static let walkableCategories: [MKPointOfInterestCategory] = [
        .park, .publicTransport, .library, .cafe, .bakery, .school, .museum, .store
    ]

    static func discoverNearbyWalkableAnchors(
        around center: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance = 750
    ) async -> [DiscoveredWalkableAnchor] {
        let request = MKLocalPointsOfInterestRequest(center: center, radius: radiusMeters)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: walkableCategories)

        let search = MKLocalSearch(request: request)
        var anchors: [DiscoveredWalkableAnchor] = []
        do {
            let response = try await search.start()
            var seenKeys = Set<String>()

            for item in response.mapItems {
                guard let name = item.name, !name.isEmpty else { continue }
                let coord = item.placemark.coordinate
                let slug = stableSlug(name: name, lat: coord.latitude, lon: coord.longitude)
                guard !seenKeys.contains(slug) else { continue }

                // Enforce at least 95m spacing between system anchors so corners feel distinct
                let tooClose = anchors.contains { existing in
                    let d = CLLocation(latitude: existing.latitude, longitude: existing.longitude)
                        .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                    return d < 95.0
                }
                if tooClose { continue }

                seenKeys.insert(slug)
                anchors.append(
                    DiscoveredWalkableAnchor(
                        siteID: "sys.poi.\(slug)",
                        label: name,
                        latitude: coord.latitude,
                        longitude: coord.longitude
                    )
                )
                if anchors.count >= 8 { break }
            }
        } catch {
            // Gracefully fall through to quiet residential corner fallback below
        }

        // 若為安靜住宅區（周邊少於 3 個地標），溫柔補上 3 個近距離散步轉角，確保隨處都能遇見小動物！
        if anchors.count < 3 {
            let fallbacks = quietNeighborhoodFallbackAnchors(around: center, existing: anchors)
            anchors.append(contentsOf: fallbacks)
        }
        return anchors
    }

    static func quietNeighborhoodFallbackAnchors(
        around center: CLLocationCoordinate2D,
        existing: [DiscoveredWalkableAnchor]
    ) -> [DiscoveredWalkableAnchor] {
        let presets: [(String, Double, Double)] = [
            ("林蔭轉角", 115, 35),
            ("靜謐巷口", 175, 160),
            ("微風花台", 230, 285)
        ]
        let latBucket = Int((center.latitude * 200).rounded())
        let lonBucket = Int((center.longitude * 200).rounded())
        var result: [DiscoveredWalkableAnchor] = []
        for (idx, preset) in presets.enumerated() {
            if existing.count + result.count >= 3 { break }
            let coord = AnchorRotationEngine.coordinateAhead(from: center, meters: preset.1, bearingDegrees: preset.2)
            let tooClose = (existing + result).contains { other in
                CLLocation(latitude: other.latitude, longitude: other.longitude)
                    .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) < 90.0
            }
            if !tooClose {
                result.append(
                    DiscoveredWalkableAnchor(
                        siteID: "sys.quiet.\(latBucket)_\(lonBucket)_\(idx)",
                        label: preset.0,
                        latitude: coord.latitude,
                        longitude: coord.longitude
                    )
                )
            }
        }
        return result
    }

    /// Assigns site regulars using the 'Carry Regulars Forward' Relocation Guarantee (Blueprint Chapter 4):
    /// Previously met friends automatically get priority as site regulars in a new city/neighborhood
    /// so no friendship is ever stranded when a player moves or a bakery closes.
    static func pickRegularPetID(
        forIndex index: Int,
        residents: [PetResidentState]
    ) -> String {
        let metRegulars = residents
            .filter { $0.inviteState != .unmet }
            .sorted { $0.sharedDaysCount > $1.sharedDaysCount }
            .map(\.petID)

        let fullRoster = PetCatalog.allPets.map(\.id)
        let prioritized = metRegulars + fullRoster.filter { !metRegulars.contains($0) }
        guard !prioritized.isEmpty else { return "pet.01" }
        return prioritized[index % prioritized.count]
    }

    private static func stableSlug(name: String, lat: Double, lon: Double) -> String {
        let clean = name.lowercased().filter { $0.isLetter || $0.isNumber }.prefix(14)
        let latBucket = Int((lat * 1000).rounded())
        let lonBucket = Int((lon * 1000).rounded())
        return "\(clean)_\(latBucket)_\(lonBucket)"
    }
}

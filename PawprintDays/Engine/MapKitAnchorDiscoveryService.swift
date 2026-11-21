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
        .park, .publicTransport, .library, .cafe, .bakery
    ]

    static func discoverNearbyWalkableAnchors(
        around center: CLLocationCoordinate2D,
        radiusMeters: CLLocationDistance = 700
    ) async -> [DiscoveredWalkableAnchor] {
        let request = MKLocalPointsOfInterestRequest(center: center, radius: radiusMeters)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: walkableCategories)

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            var seenKeys = Set<String>()
            var anchors: [DiscoveredWalkableAnchor] = []

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
                if anchors.count >= 6 { break }
            }
            return anchors
        } catch {
            return []
        }
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

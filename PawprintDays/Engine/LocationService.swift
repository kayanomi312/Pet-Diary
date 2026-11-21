import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    /// Default illustrative Luodong, Yilan neighborhood starting point (automatically adapts anywhere in the world once real GPS arrives)
    static let defaultNeighborhoodOrigin = CLLocationCoordinate2D(latitude: 24.6770, longitude: 121.7669)

    /// Speed caps from Blueprint Chapters 2, 3, and 8
    nonisolated static let maxPedestrianSpeedMPS: Double = 3.33 // 12 km/h (bus/car filter)
    nonisolated static let maxMobilityRollSpeedMPS: Double = 2.78 // 10 km/h (Mobility-Aid Roll Mode)

    private let manager = CLLocationManager()
    private var monitor: CLMonitor?
    private var monitorEventsTask: Task<Void, Never>?

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var useSimulatedPosition: Bool = true
    var currentLocation: CLLocation
    var liveTrail: [CoordinatePoint] = []
    var lastRangeCueSiteID: String?
    var isTravelingTooFastForPaws: Bool = false
    var recentVisitSummaries: [String] = []

    /// Callbacks for Coordinator integration
    var onRealLocationMoved: ((CLLocation, Double, TimeInterval) -> Void)?
    var onEnteredAnchorGeofence: ((String) -> Void)?
    var onBackgroundVisitRecorded: ((Double, Double) -> Void)?

    override init() {
        let initial = CLLocation(
            coordinate: Self.defaultNeighborhoodOrigin,
            altitude: 12,
            horizontalAccuracy: 8.0,
            verticalAccuracy: 8.0,
            timestamp: Date()
        )
        self.currentLocation = initial
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        authorizationStatus = manager.authorizationStatus
        seedInitialNeighborhoodTrail()
    }

    func requestForegroundLocation() {
        manager.requestWhenInUseAuthorization()
    }

    /// Progressive opt-in: only requested when user explicitly taps 'Remember my longer stops'
    func enableOptionalBackgroundVisits() {
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        } else if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startMonitoringVisits()
    }

    func disableBackgroundVisits() {
        manager.stopMonitoringVisits()
    }

    func startLiveUpdatesIfAuthorized() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            useSimulatedPosition = false
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    /// Registers up to 20 rolling CLCircularRegionCondition geofences (75m) via iOS 17 CLMonitor
    /// and observes enter events to play the 75m double-tap Core Haptics cue.
    func syncRollingGeofences(for anchors: [AnchorSiteRecord]) {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        let sorted = anchors
            .filter { !$0.isHiddenByUser }
            .sorted { a, b in
                let dA = currentLocation.distance(from: CLLocation(latitude: a.lat, longitude: a.lon))
                let dB = currentLocation.distance(from: CLLocation(latitude: b.lat, longitude: b.lon))
                return dA < dB
            }
            .prefix(20)
            .map { (id: $0.siteID, coord: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon), radius: min($0.radiusM, 75.0)) }

        Task {
            let activeMonitor: CLMonitor
            if let existing = self.monitor {
                activeMonitor = existing
            } else {
                let created = await CLMonitor("com.pawprintdays.geofences")
                self.monitor = created
                activeMonitor = created
                self.startListeningToMonitorEvents(created)
            }

            let existingIDs = await activeMonitor.identifiers
            for oldID in existingIDs {
                await activeMonitor.remove(oldID)
            }
            for item in sorted {
                let condition = CLMonitor.CircularGeographicCondition(center: item.coord, radius: item.radius)
                await activeMonitor.add(condition, identifier: item.id)
            }
        }
    }

    private func startListeningToMonitorEvents(_ monitor: CLMonitor) {
        monitorEventsTask?.cancel()
        monitorEventsTask = Task { [weak self] in
            do {
                for try await event in await monitor.events {
                    if event.state == .satisfied {
                        await MainActor.run {
                            guard let self else { return }
                            if self.lastRangeCueSiteID != event.identifier {
                                self.lastRangeCueSiteID = event.identifier
                                HapticsEngine.shared.playPawRangeCue()
                                self.onEnteredAnchorGeofence?(event.identifier)
                            }
                        }
                    }
                }
            } catch {
                // CLMonitor stream ended cleanly
            }
        }
    }

    /// Smoothly moves the simulated walker to a target coordinate while recording pedestrian trail points.
    func walkSimulated(to coordinate: CLLocationCoordinate2D, stepsSegments: Int = 5) {
        useSimulatedPosition = true
        isTravelingTooFastForPaws = false
        let start = currentLocation.coordinate
        let now = Date()
        for step in 1...max(1, stepsSegments) {
            let t = Double(step) / Double(max(1, stepsSegments))
            let lat = start.latitude + (coordinate.latitude - start.latitude) * t
            let lon = start.longitude + (coordinate.longitude - start.longitude) * t
            let pt = CoordinatePoint(latitude: lat, longitude: lon, timestamp: now.addingTimeInterval(Double(step)))
            liveTrail.append(pt)
        }
        currentLocation = CLLocation(
            coordinate: coordinate,
            altitude: 12,
            horizontalAccuracy: 6.0,
            verticalAccuracy: 6.0,
            timestamp: Date()
        )
    }

    func refreshFreshSimulatedFix() {
        guard useSimulatedPosition else { return }
        currentLocation = CLLocation(
            coordinate: currentLocation.coordinate,
            altitude: currentLocation.altitude,
            horizontalAccuracy: 6.0,
            verticalAccuracy: 6.0,
            timestamp: Date()
        )
    }

    func clearTrailForDay() {
        liveTrail = [
            CoordinatePoint(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude,
                timestamp: Date()
            )
        ]
    }

    func encodeTrailGeoJSON() -> String? {
        guard liveTrail.count >= 2 else { return nil }
        let coords = liveTrail.map { [$0.longitude, $0.latitude] }
        let obj: [String: Any] = [
            "type": "LineString",
            "coordinates": coords
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: obj),
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    static func decodeTrailGeoJSON(_ geoJSON: String?) -> [CoordinatePoint] {
        guard let geoJSON,
              let data = geoJSON.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let coords = obj["coordinates"] as? [[Double]] else {
            return []
        }
        let now = Date()
        return coords.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return CoordinatePoint(latitude: pair[1], longitude: pair[0], timestamp: now)
        }
    }

    private func seedInitialNeighborhoodTrail() {
        let base = Self.defaultNeighborhoodOrigin
        let now = Date()
        liveTrail = [
            CoordinatePoint(latitude: base.latitude - 0.00055, longitude: base.longitude - 0.00045, timestamp: now.addingTimeInterval(-240)),
            CoordinatePoint(latitude: base.latitude - 0.00038, longitude: base.longitude - 0.00028, timestamp: now.addingTimeInterval(-180)),
            CoordinatePoint(latitude: base.latitude - 0.00020, longitude: base.longitude - 0.00014, timestamp: now.addingTimeInterval(-120)),
            CoordinatePoint(latitude: base.latitude - 0.00008, longitude: base.longitude - 0.00005, timestamp: now.addingTimeInterval(-60)),
            CoordinatePoint(latitude: base.latitude, longitude: base.longitude, timestamp: now)
        ]
    }

    // MARK: - CLLocationManagerDelegate
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.useSimulatedPosition = false
                self.manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            guard !self.useSimulatedPosition else { return }
            let previous = self.currentLocation
            let deltaDist = previous.distance(from: latest)
            let deltaTime = max(0, latest.timestamp.timeIntervalSince(previous.timestamp))

            // Bus/car filter (> 12 km/h grants no street paw activation or trail line)
            let isTooFast = latest.speed > Self.maxPedestrianSpeedMPS
            self.isTravelingTooFastForPaws = isTooFast
            self.currentLocation = latest

            if !isTooFast && latest.horizontalAccuracy >= 0 && latest.horizontalAccuracy <= 40 {
                let pt = CoordinatePoint(
                    latitude: latest.coordinate.latitude,
                    longitude: latest.coordinate.longitude,
                    timestamp: latest.timestamp
                )
                if let last = self.liveTrail.last {
                    let dist = CLLocation(latitude: last.latitude, longitude: last.longitude)
                        .distance(from: latest)
                    if dist >= 6.0 && dist <= 300.0 {
                        self.liveTrail.append(pt)
                    } else if dist > 300.0 {
                        // Reset trail on teleport/city switch so disconnected stops never draw fake lines
                        self.liveTrail = [pt]
                    }
                } else {
                    self.liveTrail.append(pt)
                }

                // Notify coordinator for Mobility-Aid Roll Mode & real-world anchor discovery
                let isLowSpeedRoll = latest.speed < 0 || latest.speed <= Self.maxMobilityRollSpeedMPS
                self.onRealLocationMoved?(latest, isLowSpeedRoll ? min(deltaDist, 200) : 0, min(deltaTime, 120))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        let lat = visit.coordinate.latitude
        let lon = visit.coordinate.longitude
        Task { @MainActor in
            let summary = "Quiet stop recorded (\(lat.formatted(.number.precision(.fractionLength(3)))), \(lon.formatted(.number.precision(.fractionLength(3)))))"
            self.recentVisitSummaries.append(summary)
            self.onBackgroundVisitRecorded?(lat, lon)
        }
    }
}

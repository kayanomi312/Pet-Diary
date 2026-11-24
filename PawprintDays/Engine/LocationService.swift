import Foundation
import CoreLocation
import Observation

enum GPSSignalQuality: String, Sendable {
    case simulated = "等待定位"
    case acquiring = "定位中…"
    case high = "GPS 極精準"
    case good = "GPS 良好"
    case weak = "GPS 訊號較弱"
    case denied = "定位未開"

    var badgeColorHex: String {
        switch self {
        case .simulated: return "#8C7A68"
        case .acquiring: return "#D99B38"
        case .high:      return "#4E9A6F"
        case .good:      return "#5B8E94"
        case .weak:      return "#D96A52"
        case .denied:    return "#D96A52"
        }
    }
}

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    /// Default illustrative Luodong, Yilan neighborhood starting point (automatically adapts anywhere in the world once real GPS arrives)
    static let defaultNeighborhoodOrigin = CLLocationCoordinate2D(latitude: 24.6770, longitude: 121.7669)

    /// Speed caps from Blueprint Chapters 2, 3, and 8
    nonisolated static let maxPedestrianSpeedMPS: Double = 3.33 // 12 km/h (bus/car filter)
    nonisolated static let maxMobilityRollSpeedMPS: Double = 2.78 // 10 km/h (Mobility-Aid Roll Mode)

    private let manager = CLLocationManager()
    private var monitoredGeofences: [(id: String, lat: Double, lon: Double, radius: Double)] = []
    private var currentlyInsideGeofenceIDs: Set<String> = []

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    #if targetEnvironment(simulator)
    var useSimulatedPosition: Bool = true
    #else
    var useSimulatedPosition: Bool = false
    #endif
    var currentLocation: CLLocation
    var liveTrail: [CoordinatePoint] = []
    var lastRangeCueSiteID: String?
    var isTravelingTooFastForPaws: Bool = false
    var recentVisitSummaries: [String] = []

    // Accurate Real-World GPS Diagnostics & Compass Heading
    var hasReceivedRealGPSFix: Bool = false
    var gpsAccuracyMeters: Double? = nil
    var gpsSignalQuality: GPSSignalQuality = .acquiring
    var isReducedAccuracy: Bool = false
    var headingDegrees: Double? = nil
    var lastRealFixDate: Date? = nil
    var totalVerifiedGPSMeters: Double = 0

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
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 3.0
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
        isReducedAccuracy = (manager.accuracyAuthorization == .reducedAccuracy)
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            useSimulatedPosition = false
            gpsSignalQuality = .denied
        }
        seedInitialNeighborhoodTrail()
        startLiveUpdatesIfAuthorized()
    }

    func requestForegroundLocation() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            requestFreshAccurateFix()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    /// Requests an immediate high-accuracy GPS fix and prompts for temporary full accuracy if iOS Precise Location is off.
    func requestFreshAccurateFix() {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            useSimulatedPosition = false
            if !hasReceivedRealGPSFix {
                gpsSignalQuality = .acquiring
            }
            if manager.accuracyAuthorization == .reducedAccuracy {
                isReducedAccuracy = true
                Self.requestTempAccuracy(manager: manager, purposeKey: "PreciseNeighborhoodWalk") { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.isReducedAccuracy = (self.manager.accuracyAuthorization == .reducedAccuracy)
                        self.manager.startUpdatingLocation()
                    }
                }
            } else {
                isReducedAccuracy = false
                manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                manager.startUpdatingLocation()
            }
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
        } else {
            manager.requestWhenInUseAuthorization()
        }
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
            isReducedAccuracy = (manager.accuracyAuthorization == .reducedAccuracy)
            if !hasReceivedRealGPSFix {
                gpsSignalQuality = .acquiring
            }
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 3.0
            manager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
        default:
            break
        }
    }

    /// Maintains up to 20 closest rolling 75m geofence zones and evaluates entry live on every GPS update
    /// (zero CLMonitor init crash risk, instant 75m Core Haptics double-tap cue).
    func syncRollingGeofences(for anchors: [AnchorSiteRecord]) {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        monitoredGeofences = anchors
            .filter { !$0.isHiddenByUser }
            .sorted { a, b in
                let dA = currentLocation.distance(from: CLLocation(latitude: a.lat, longitude: a.lon))
                let dB = currentLocation.distance(from: CLLocation(latitude: b.lat, longitude: b.lon))
                return dA < dB
            }
            .prefix(20)
            .map { (id: $0.siteID, lat: $0.lat, lon: $0.lon, radius: min($0.radiusM, 75.0)) }

        evaluateRollingGeofences(at: currentLocation)
    }

    private func evaluateRollingGeofences(at location: CLLocation) {
        guard !isTravelingTooFastForPaws,
              location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= 40.0 else {
            return
        }
        var nowInside = Set<String>()
        for fence in monitoredGeofences {
            let dist = location.distance(from: CLLocation(latitude: fence.lat, longitude: fence.lon))
            if dist <= fence.radius {
                nowInside.insert(fence.id)
                if !currentlyInsideGeofenceIDs.contains(fence.id) && lastRangeCueSiteID != fence.id {
                    lastRangeCueSiteID = fence.id
                    HapticsEngine.shared.playPawRangeCue()
                    onEnteredAnchorGeofence?(fence.id)
                }
            }
        }
        currentlyInsideGeofenceIDs = nowInside
    }

    /// Smoothly moves the simulated walker to a target coordinate while recording pedestrian trail points.
    func walkSimulated(to coordinate: CLLocationCoordinate2D, stepsSegments: Int = 5) {
        useSimulatedPosition = true
        gpsSignalQuality = .simulated
        gpsAccuracyMeters = 6.0
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
        let reduced = (manager.accuracyAuthorization == .reducedAccuracy)
        Task { @MainActor in
            self.authorizationStatus = status
            self.isReducedAccuracy = reduced
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startLiveUpdatesIfAuthorized()
            } else if status == .denied || status == .restricted {
                self.useSimulatedPosition = false
                self.gpsSignalQuality = .denied
                self.gpsAccuracyMeters = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let deg = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        guard deg >= 0 else { return }
        Task { @MainActor in
            self.headingDegrees = deg
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Gracefully tolerate transient GPS signal loss while keeping last valid fix
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Pick the freshest, most accurate candidate in this batch
        let now = Date()
        let freshCandidates = locations.filter { loc in
            loc.horizontalAccuracy >= 0 &&
            loc.horizontalAccuracy <= 65.0 &&
            abs(now.timeIntervalSince(loc.timestamp)) <= 12.0
        }
        guard let bestFix = freshCandidates.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy }) ?? locations.last else {
            return
        }

        Task { @MainActor in
            guard !self.useSimulatedPosition else { return }
            let acc = bestFix.horizontalAccuracy
            guard acc >= 0 else { return }

            // Update live GPS signal diagnostics
            self.gpsAccuracyMeters = acc
            if acc <= 12.0 {
                self.gpsSignalQuality = .high
            } else if acc <= 25.0 {
                self.gpsSignalQuality = .good
            } else {
                self.gpsSignalQuality = .weak
            }

            // Reject stale (> 12s) or very noisy (> 65m) fixes once we already have a real fix
            let fixAge = abs(Date().timeIntervalSince(bestFix.timestamp))
            if self.hasReceivedRealGPSFix && (fixAge > 12.0 || acc > 65.0) {
                return
            }

            let previous = self.currentLocation
            let deltaDist = previous.distance(from: bestFix)
            let deltaTime = max(0.5, bestFix.timestamp.timeIntervalSince(previous.timestamp))
            let impliedSpeed = deltaDist / deltaTime

            // Reject impossible GPS jitter spikes (> 45 m/s with mediocre accuracy)
            if self.hasReceivedRealGPSFix && acc > 18.0 && impliedSpeed > 45.0 {
                return
            }

            // Accuracy-weighted smoothing for gentle pedestrian movement (< 35m delta)
            let acceptedLocation: CLLocation
            if self.hasReceivedRealGPSFix && deltaDist < 35.0 && deltaDist > 0.5 && acc > 8.0 {
                let alpha = max(0.35, min(0.88, 12.0 / max(acc, 12.0)))
                let smoothLat = previous.coordinate.latitude + (bestFix.coordinate.latitude - previous.coordinate.latitude) * alpha
                let smoothLon = previous.coordinate.longitude + (bestFix.coordinate.longitude - previous.coordinate.longitude) * alpha
                acceptedLocation = CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: smoothLat, longitude: smoothLon),
                    altitude: bestFix.altitude,
                    horizontalAccuracy: acc,
                    verticalAccuracy: bestFix.verticalAccuracy,
                    course: bestFix.course,
                    speed: bestFix.speed,
                    timestamp: bestFix.timestamp
                )
            } else {
                acceptedLocation = bestFix
            }

            // Bus/car filter (> 12 km/h grants no street paw activation or trail line)
            let effectiveSpeed = acceptedLocation.speed >= 0 ? acceptedLocation.speed : (deltaDist < 120 ? impliedSpeed : 0)
            let isTooFast = effectiveSpeed > Self.maxPedestrianSpeedMPS
            self.isTravelingTooFastForPaws = isTooFast

            let wasFirstRealFix = !self.hasReceivedRealGPSFix
            self.hasReceivedRealGPSFix = true
            self.lastRealFixDate = acceptedLocation.timestamp
            self.currentLocation = acceptedLocation

            if !isTooFast && acc <= 40.0 {
                let pt = CoordinatePoint(
                    latitude: acceptedLocation.coordinate.latitude,
                    longitude: acceptedLocation.coordinate.longitude,
                    timestamp: acceptedLocation.timestamp
                )
                if wasFirstRealFix {
                    // Replace Luodong sample trail cleanly with user's actual starting location
                    self.liveTrail = [pt]
                } else if let last = self.liveTrail.last {
                    let dist = CLLocation(latitude: last.latitude, longitude: last.longitude)
                        .distance(from: acceptedLocation)
                    if dist >= 4.0 && dist <= 300.0 {
                        self.liveTrail.append(pt)
                        self.totalVerifiedGPSMeters += dist
                    } else if dist > 300.0 {
                        self.liveTrail = [pt]
                    }
                } else {
                    self.liveTrail.append(pt)
                }

                // Evaluate 75m rolling geofence entry cues live
                self.evaluateRollingGeofences(at: acceptedLocation)

                // Notify coordinator for Mobility-Aid Roll Mode & real-world anchor discovery
                let isLowSpeedRoll = acceptedLocation.speed < 0 || acceptedLocation.speed <= Self.maxMobilityRollSpeedMPS
                self.onRealLocationMoved?(acceptedLocation, isLowSpeedRoll ? min(deltaDist, 200) : 0, min(deltaTime, 120))
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

    nonisolated private static func requestTempAccuracy(
        manager: CLLocationManager,
        purposeKey: String,
        onDone: @escaping @Sendable () -> Void
    ) {
        manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { _ in
            onDone()
        }
    }
}

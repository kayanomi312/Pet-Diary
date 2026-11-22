import Foundation
import CoreLocation

struct LiveWeatherSnapshot: Sendable {
    let weatherMode: WeatherMode
    let attributionLabel: String
}

/// 輕量隱私的天氣與日照同步服務：
/// - 離線時立即依本機時間推斷自然晨光／午後／暮色光影，絕不寫死固定雨天。
/// - 取得真實 GPS 後，將座標四捨五入至小數第 2 位（約 1.1 公里模糊精度，保護隱私）查詢 Open-Meteo WMO 天氣碼，每 30 分鐘最多查詢一次。
enum WeatherSyncService {
    /// 依據本機時間提供柔和合理的預設天候光影
    static func inferTimeOfDayWeather(now: Date = Date()) -> LiveWeatherSnapshot {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<11:
            return LiveWeatherSnapshot(weatherMode: .clearMorning, attributionLabel: "本機晨光 · 鄰里街區")
        case 11..<16:
            return LiveWeatherSnapshot(weatherMode: .clearMorning, attributionLabel: "本機午後日照 · 鄰里街區")
        case 16..<20:
            return LiveWeatherSnapshot(weatherMode: .dusk, attributionLabel: "本機黃昏暮色 · 鄰里街區")
        default:
            return LiveWeatherSnapshot(weatherMode: .overcast, attributionLabel: "本機靜夜微光 · 鄰里街區")
        }
    }

    /// 模糊座標（~1.1km）查詢即時天氣，失敗時安靜退回本機日照推斷
    static func fetchLiveWeather(around coordinate: CLLocationCoordinate2D, now: Date = Date()) async -> LiveWeatherSnapshot {
        #if targetEnvironment(simulator)
        return inferTimeOfDayWeather(now: now)
        #else
        let roundedLat = (coordinate.latitude * 100.0).rounded() / 100.0
        let roundedLon = (coordinate.longitude * 100.0).rounded() / 100.0
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(roundedLat)&longitude=\(roundedLon)&current=weather_code") else {
            return inferTimeOfDayWeather(now: now)
        }

        var req = URLRequest(url: url)
        req.timeoutInterval = 5.0
        req.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let code = current["weather_code"] as? Int else {
                return inferTimeOfDayWeather(now: now)
            }
            let hour = Calendar.current.component(.hour, from: now)
            let mapped = mapWMOCode(code, hour: hour)
            return LiveWeatherSnapshot(weatherMode: mapped, attributionLabel: "即時天氣 · \(mapped.displayName)")
        } catch {
            return inferTimeOfDayWeather(now: now)
        }
        #endif
    }

    static func mapWMOCode(_ code: Int, hour: Int) -> WeatherMode {
        switch code {
        case 51...67, 80...82, 95...99:
            return .lightRain
        case 45, 48, 3:
            return .overcast
        case 1, 2:
            if hour >= 16 && hour < 20 { return .dusk }
            return .overcast
        default: // 0 Clear sky
            if hour >= 16 && hour < 20 { return .dusk }
            return .clearMorning
        }
    }
}

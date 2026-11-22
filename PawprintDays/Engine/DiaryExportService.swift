import Foundation
import UIKit
import SwiftData

/// Local-only Diary Export & Backup Service:
/// 1. Printable Monthly Watercolor PDF Storybook (`UIGraphicsPDFRenderer`)
/// 2. Portable Local JSON Backup & Safe Restore (100% private on-device / user Files)
enum DiaryExportService {
    struct PortableDiaryBackup: Codable {
        let exportedAtISO: String
        let appVersion: String
        let coinBalance: Int
        let totalAcceptedStepsAllTime: Int
        let days: [BackupDay]
        let petNicknames: [String: String]

        struct BackupDay: Codable {
            let localDateISO: String
            let acceptedSteps: Int
            let weatherCode: String
            let personalNote: String
            let isStarredTradition: Bool
            let revisitNotes: [String]
        }
    }

    /// Generates a shareable temporary JSON backup URL for the user's Files / iCloud Drive.
    @MainActor
    static func exportJSONBackup(coordinator: GameCoordinator) -> URL? {
        let dayEntries = coordinator.diaryDays.map { day in
            PortableDiaryBackup.BackupDay(
                localDateISO: day.localDateISO,
                acceptedSteps: day.acceptedSteps,
                weatherCode: day.weatherCode,
                personalNote: day.personalNote,
                isStarredTradition: day.isStarredTradition,
                revisitNotes: day.revisitNotes
            )
        }
        var nicknames: [String: String] = [:]
        for pet in coordinator.residents {
            nicknames[pet.petID] = pet.nickname
        }
        let payload = PortableDiaryBackup(
            exportedAtISO: coordinator.currentLocalDateISO,
            appVersion: "0.2.0",
            coinBalance: coordinator.ledger.coinBalance,
            totalAcceptedStepsAllTime: coordinator.ledger.totalAcceptedStepsAllTime,
            days: dayEntries,
            petNicknames: nicknames
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload) else { return nil }
        let fileName = "足印日記備份_\(coordinator.currentLocalDateISO).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Safely restores personal notes, starred traditions & pet nicknames from a portable JSON backup.
    @MainActor
    static func restoreJSONBackup(from url: URL, coordinator: GameCoordinator) -> Int {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let backup = try? JSONDecoder().decode(PortableDiaryBackup.self, from: data) else {
            return 0
        }

        var restoredCount = 0
        for (petID, nick) in backup.petNicknames {
            if let resident = coordinator.resident(for: petID), !nick.isEmpty {
                resident.nickname = nick
            }
        }
        for item in backup.days {
            if let existing = coordinator.diaryDays.first(where: { $0.localDateISO == item.localDateISO }) {
                if existing.personalNote.isEmpty && !item.personalNote.isEmpty {
                    existing.personalNote = item.personalNote
                    restoredCount += 1
                }
                if item.isStarredTradition && !existing.isStarredTradition {
                    existing.isStarredTradition = true
                    restoredCount += 1
                }
                for note in item.revisitNotes where !existing.revisitNotes.contains(note) {
                    existing.revisitNotes.append(note)
                }
            } else {
                let created = DiaryDayRecord(
                    localDateISO: item.localDateISO,
                    acceptedSteps: item.acceptedSteps,
                    weatherCode: item.weatherCode,
                    personalNote: item.personalNote,
                    isStarredTradition: item.isStarredTradition
                )
                created.revisitNotes = item.revisitNotes
                coordinator.modelContext.insert(created)
                restoredCount += 1
            }
        }
        try? coordinator.modelContext.save()
        coordinator.reloadAll()
        return restoredCount
    }

    /// Renders a printable warm-paper Monthly Watercolor Storybook PDF Zine via UIGraphicsPDFRenderer.
    @MainActor
    static func exportMonthlyPDF(
        year: Int,
        month: Int,
        days: [DiaryDayRecord],
        encounters: [EncounterLog],
        curios: [ForagedCurioEntry]
    ) -> URL? {
        let monthPrefix = String(format: "%04d-%02d-", year, month)
        let monthDays = days
            .filter { $0.localDateISO.hasPrefix(monthPrefix) }
            .sorted { $0.localDateISO < $1.localDateISO }
        let monthSteps = monthDays.reduce(0) { $0 + $1.acceptedSteps }
        let monthCurios = curios.filter { $0.localDateISO.hasPrefix(monthPrefix) }

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 portrait
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            let paperBG = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
            let inkColor = UIColor(red: 0.17, green: 0.21, blue: 0.21, alpha: 1.0)
            let tealColor = UIColor(red: 0.16, green: 0.36, blue: 0.37, alpha: 1.0)
            let softInk = UIColor(red: 0.38, green: 0.36, blue: 0.33, alpha: 1.0)
            let borderCol = UIColor(red: 0.72, green: 0.60, blue: 0.45, alpha: 0.55)

            func beginWarmPage() {
                ctx.beginPage()
                paperBG.setFill()
                UIRectFill(pageRect)
                let frame = pageRect.insetBy(dx: 28, dy: 28)
                borderCol.setStroke()
                let borderPath = UIBezierPath(roundedRect: frame, cornerRadius: 12)
                borderPath.lineWidth = 1.2
                borderPath.stroke()
            }

            beginWarmPage()
            var cursorY: CGFloat = 54

            // Cover / Header Banner
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: inkColor
            ]
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: tealColor
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11.5, weight: .regular),
                .foregroundColor: inkColor
            ]
            let noteAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11.5),
                .foregroundColor: softInk
            ]

            NSString(string: "足印日記 · \(year)年\(month)月 散步繪本").draw(at: CGPoint(x: 48, y: cursorY), withAttributes: titleAttrs)
            cursorY += 34
            NSString(string: "本月共記錄 \(monthDays.count) 天 · 累積 \(monthSteps.formatted()) 步 · 收藏 \(monthCurios.count) 件街區拾遺")
                .draw(at: CGPoint(x: 48, y: cursorY), withAttributes: subtitleAttrs)
            cursorY += 28

            // Subtle divider
            borderCol.setFill()
            UIRectFill(CGRect(x: 48, y: cursorY, width: pageRect.width - 96, height: 1))
            cursorY += 18

            if monthDays.isEmpty {
                NSString(string: "這個月份還是一頁安靜留白的棉紙，等待下一次漫步落筆。")
                    .draw(at: CGPoint(x: 48, y: cursorY), withAttributes: noteAttrs)
            }

            for day in monthDays {
                let dayEncs = encounters.filter { $0.localDateISO == day.localDateISO }
                let estimatedHeight: CGFloat = 95 + (dayEncs.first?.bakedSnapshotPNGData != nil ? 130 : 0) + (day.photoJPEGData != nil ? 120 : 0)
                if cursorY + estimatedHeight > pageRect.height - 60 {
                    beginWarmPage()
                    cursorY = 52
                }

                // Day heading
                let heading = "\(CivilCalendarHelper.displayDate(from: day.localDateISO))  ·  \(day.weatherMode.displayName)  ·  \(day.acceptedSteps.formatted()) 步" + (day.isStarredTradition ? "  ★" : "")
                NSString(string: heading).draw(at: CGPoint(x: 48, y: cursorY), withAttributes: subtitleAttrs)
                cursorY += 20

                // Postcard + optional Polaroid photo side by side
                var imgRowMaxH: CGFloat = 0
                var imgX: CGFloat = 48
                if let png = dayEncs.first?.bakedSnapshotPNGData, let img = UIImage(data: png) {
                    let targetW: CGFloat = 210
                    let targetH = min(132, targetW * (img.size.height / max(1, img.size.width)))
                    img.draw(in: CGRect(x: imgX, y: cursorY, width: targetW, height: targetH))
                    imgX += targetW + 16
                    imgRowMaxH = max(imgRowMaxH, targetH)
                }
                if let photoData = day.photoJPEGData, let photo = UIImage(data: photoData) {
                    let frameW: CGFloat = 116
                    let frameH: CGFloat = 128
                    UIColor.white.setFill()
                    UIRectFill(CGRect(x: imgX, y: cursorY, width: frameW, height: frameH))
                    borderCol.setStroke()
                    UIBezierPath(rect: CGRect(x: imgX, y: cursorY, width: frameW, height: frameH)).stroke()
                    photo.draw(in: CGRect(x: imgX + 6, y: cursorY + 6, width: frameW - 12, height: frameH - 26))
                    imgRowMaxH = max(imgRowMaxH, frameH)
                }
                if imgRowMaxH > 0 {
                    cursorY += imgRowMaxH + 10
                }

                for enc in dayEncs {
                    let rect = CGRect(x: 48, y: cursorY, width: pageRect.width - 96, height: 34)
                    NSString(string: "• \(enc.narrativeLine)").draw(in: rect, withAttributes: bodyAttrs)
                    cursorY += 20
                }

                if !day.personalNote.isEmpty {
                    let rect = CGRect(x: 52, y: cursorY, width: pageRect.width - 104, height: 42)
                    NSString(string: "「\(day.personalNote)」").draw(in: rect, withAttributes: noteAttrs)
                    cursorY += 26
                }

                cursorY += 14
            }
        }

        let fileName = String(format: "足印日記_%04d年%02d月.pdf", year, month)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

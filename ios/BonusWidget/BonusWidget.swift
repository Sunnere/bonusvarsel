//
//  BonusWidget.swift
//  BonusWidget
//
//  Bonusvarsel hjemskjerm-widget
//

import WidgetKit
import SwiftUI

// ── App Group ID (må matche Flutter-siden) ──────────────────────────────────
private let appGroupID = "group.com.royrotvold.bonusvarsel"

// ── Data fra shared UserDefaults ─────────────────────────────────────────────
struct BonusData {
    var points: Int
    var goalPoints: Int
    var destination: String
    var monthsToGoal: Int
    var cardName: String
    var companionTicket: Bool

    static func load() -> BonusData {
        let defaults = UserDefaults(suiteName: appGroupID)
        return BonusData(
            points:          defaults?.integer(forKey: "widget_points")        ?? 0,
            goalPoints:      defaults?.integer(forKey: "widget_goal_points")   ?? 150000,
            destination:     defaults?.string(forKey: "widget_destination")    ?? "Bangkok",
            monthsToGoal:    defaults?.integer(forKey: "widget_months")        ?? 0,
            cardName:        defaults?.string(forKey: "widget_card")           ?? "Amex",
            companionTicket: defaults?.bool(forKey: "widget_companion_ticket") ?? false
        )
    }
}

// ── Timeline ─────────────────────────────────────────────────────────────────
struct BonusEntry: TimelineEntry {
    let date: Date
    let data: BonusData
}

struct BonusProvider: TimelineProvider {
    func placeholder(in context: Context) -> BonusEntry {
        BonusEntry(date: Date(), data: BonusData(
            points: 45000, goalPoints: 150000,
            destination: "Bangkok", monthsToGoal: 24,
            cardName: "Amex", companionTicket: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (BonusEntry) -> Void) {
        completion(BonusEntry(date: Date(), data: BonusData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BonusEntry>) -> Void) {
        let entry = BonusEntry(date: Date(), data: BonusData.load())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// ── Farger ────────────────────────────────────────────────────────────────────
private let bgColor    = Color(red: 0.024, green: 0.067, blue: 0.122) // #06111F
private let surfColor  = Color(red: 0.043, green: 0.090, blue: 0.157) // #0B1728
private let primColor  = Color(red: 0.376, green: 0.647, blue: 0.980) // #60A5FA
private let succColor  = Color(red: 0.204, green: 0.827, blue: 0.600) // #34D399
private let warnColor  = Color(red: 0.984, green: 0.749, blue: 0.141) // #FBBF24
private let textColor  = Color(red: 0.973, green: 0.980, blue: 0.988) // #F8FAFC
private let mutedColor = Color(red: 0.796, green: 0.835, blue: 0.882) // #CBD5E1

// ── Formatering ───────────────────────────────────────────────────────────────
private func fmt(_ n: Int) -> String {
    let s = String(n)
    var result = ""
    for (i, c) in s.reversed().enumerated() {
        if i > 0 && i % 3 == 0 { result = " " + result }
        result = String(c) + result
    }
    return result
}

// ── LITEN WIDGET (systemSmall) ────────────────────────────────────────────────
struct SmallWidgetView: View {
    let data: BonusData

    var progress: Double {
        guard data.goalPoints > 0 else { return 0 }
        return min(Double(data.points) / Double(data.goalPoints), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("✈️")
                    .font(.system(size: 14))
                Text("Bonusvarsel")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(primColor)
                Spacer()
            }

            Spacer()

            // Poeng
            Text(fmt(data.points))
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(textColor)
            Text("poeng")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(mutedColor)

            Spacer()

            // Progresjonslinje
            VStack(alignment: .leading, spacing: 3) {
                Text(data.destination)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(mutedColor)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(surfColor)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progress >= 1 ? succColor : primColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
                Text("\(Int(progress * 100))% av målet")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(mutedColor)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor)
    }
}

// ── MEDIUM WIDGET (systemMedium) ──────────────────────────────────────────────
struct MediumWidgetView: View {
    let data: BonusData

    var progress: Double {
        guard data.goalPoints > 0 else { return 0 }
        return min(Double(data.points) / Double(data.goalPoints), 1.0)
    }

    var missing: Int {
        max(data.goalPoints - data.points, 0)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Venstre kolonne
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("✈️")
                        .font(.system(size: 13))
                    Text("Bonusvarsel")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(primColor)
                }

                Spacer()

                Text(fmt(data.points))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(textColor)
                Text("EuroBonus-poeng")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(mutedColor)

                Spacer()

                // Progresjonslinje
                VStack(alignment: .leading, spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(surfColor)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(progress >= 1 ? succColor : primColor)
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("\(Int(progress * 100))% mot \(data.destination)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(mutedColor)
                }
            }

            // Divider
            Rectangle()
                .fill(surfColor)
                .frame(width: 1)

            // Høyre kolonne
            VStack(alignment: .leading, spacing: 8) {
                // Mål
                VStack(alignment: .leading, spacing: 2) {
                    Text("🎯 Mål")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(mutedColor)
                    Text(data.destination)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(textColor)
                    Text("\(fmt(data.goalPoints))p totalt")
                        .font(.system(size: 10))
                        .foregroundColor(mutedColor)
                }

                // Mangler
                VStack(alignment: .leading, spacing: 2) {
                    Text("📈 Mangler")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(mutedColor)
                    Text(missing == 0 ? "Nok poeng! ✅" : "\(fmt(missing))p")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(missing == 0 ? succColor : warnColor)
                    if data.monthsToGoal > 0 && missing > 0 {
                        Text("≈ \(data.monthsToGoal) mnd")
                            .font(.system(size: 10))
                            .foregroundColor(mutedColor)
                    }
                }

                // Companion Ticket
                if data.companionTicket {
                    HStack(spacing: 4) {
                        Text("🎟️")
                            .font(.system(size: 11))
                        Text("CT aktiv")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(warnColor)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor)
    }
}

// ── WIDGET ENTRY VIEW ─────────────────────────────────────────────────────────
struct BonusWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BonusEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        default:
            MediumWidgetView(data: entry.data)
        }
    }
}

// ── WIDGET CONFIG ─────────────────────────────────────────────────────────────
struct BonusWidget: Widget {
    let kind: String = "BonusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BonusProvider()) { entry in
            BonusWidgetEntryView(entry: entry)
                .containerBackground(bgColor, for: .widget)
        }
        .configurationDisplayName("Bonusvarsel")
        .description("Se EuroBonus-poeng og fremgang mot drømmereisen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── PREVIEW ───────────────────────────────────────────────────────────────────
#Preview(as: .systemSmall) {
    BonusWidget()
} timeline: {
    BonusEntry(date: .now, data: BonusData(
        points: 45000, goalPoints: 150000,
        destination: "Bangkok", monthsToGoal: 24,
        cardName: "Amex", companionTicket: true))
}

#Preview(as: .systemMedium) {
    BonusWidget()
} timeline: {
    BonusEntry(date: .now, data: BonusData(
        points: 45000, goalPoints: 150000,
        destination: "Bangkok", monthsToGoal: 24,
        cardName: "Amex", companionTicket: true))
}

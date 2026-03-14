import Foundation

extension Double {

    // MARK: - Number-only (no symbol) — used by SARText
    /// "15,000"
    var sarNumber: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        f.groupingSeparator = ","
        f.groupingSize = 3
        return f.string(from: NSNumber(value: abs(self))) ?? "0"
    }

    /// "15,000.50"
    var sarNumberDecimal: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.groupingSeparator = ","
        return f.string(from: NSNumber(value: abs(self))) ?? "0.00"
    }

    /// "15K" / "1.2M" (no symbol)
    var sarCompactNumber: String {
        switch abs(self) {
        case 1_000_000...: return String(format: "%.1fM", abs(self) / 1_000_000)
        case 1_000...:     return String(format: "%.0fK", abs(self) / 1_000)
        default:           return sarNumber
        }
    }

    // MARK: - String variants (symbol + number) — for non-SwiftUI contexts
    /// "﷼15,000"
    var sarFormatted: String { "﷼\(sarNumber)" }

    /// "﷼15,000.50"
    var sarFormattedDecimal: String { "﷼\(sarNumberDecimal)" }

    /// "﷼15K" / "﷼1.2M"
    var sarCompact: String {
        switch abs(self) {
        case 1_000_000...: return "﷼\(String(format: "%.1fM", abs(self) / 1_000_000))"
        case 1_000...:     return "﷼\(String(format: "%.0fK", abs(self) / 1_000))"
        default:           return sarFormatted
        }
    }

    var percentageFormatted: String { String(format: "%.1f%%", self) }
    var isNegative: Bool { self < 0 }
    var isPositive: Bool { self > 0 }
}

extension Date {
    var gregorianFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "en_SA")
        return f.string(from: self)
    }

    var hijriFormatted: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.dateStyle = .long
        f.locale = Locale(identifier: "ar_SA")
        return f.string(from: self)
    }

    var shortFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "en_SA")
        return f.string(from: self)
    }

    /// "٩ مارس ٢٠٢٦" — Gregorian day + month + year in Arabic
    var monthYearArabic: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ar")
        return f.string(from: self)
    }

    /// "٩ رمضان ١٤٤٧" — Hijri day + month + year
    var hijriMonthYear: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.locale = Locale(identifier: "ar_SA")
        return f.string(from: self)
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isThisMonth: Bool { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month) }
}

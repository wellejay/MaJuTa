import Foundation

extension String {
    /// Converts Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) and Arabic decimal separators
    /// to their Western equivalents, then parses as Double.
    /// Returns nil if the normalized string cannot be parsed.
    var arabicNormalizedDouble: Double? {
        let map: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "،": ".", "٫": "."   // Arabic comma / decimal separator
        ]
        let normalized = String(self.map { map[$0] ?? $0 })
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

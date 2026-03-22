import SwiftUI

struct PINPadView: View {
    @Binding var pin: String
    let maxDigits: Int
    let onComplete: () -> Void

    private let digits = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","⌫"]]

    var body: some View {
        VStack(spacing: MaJuTaSpacing.sm) {
            ForEach(digits, id: \.self) { row in
                HStack(spacing: MaJuTaSpacing.sm) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleKey(key)
                        } label: {
                            Text(key)
                                .font(.maJuTaTitle2)
                                .foregroundColor(.white)
                                .frame(width: MaJuTaSpacing.pinButtonSize, height: MaJuTaSpacing.pinButtonSize)
                                .background(key.isEmpty ? Color.clear : Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .disabled(key.isEmpty)
                        .accessibilityLabel(pinKeyLabel(key))
                        .accessibilityHint(pinKeyHint(key))
                        .accessibilityHidden(key.isEmpty)
                    }
                }
            }
        }
        .accessibilityLabel(L("لوحة أرقام رمز المرور"))
    }

    private func pinKeyLabel(_ key: String) -> String {
        switch key {
        case "⌫": return L("حذف")
        case "":  return ""
        default:  return L("رقم \(key)")
        }
    }

    private func pinKeyHint(_ key: String) -> String {
        switch key {
        case "⌫": return L("يحذف آخر رقم تم إدخاله")
        case "":  return ""
        default:  return L("انقر لإدخال الرقم \(key)")
        }
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
        } else if key != "" && pin.count < maxDigits {
            pin.append(key)
            if pin.count == maxDigits { onComplete() }
        }
    }
}

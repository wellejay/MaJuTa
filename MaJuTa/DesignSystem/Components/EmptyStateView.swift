import SwiftUI

/// Reusable empty-state placeholder for lists and content areas throughout MaJuTa.
/// Displays a system icon, a primary message, and an optional subtitle.
///
/// Usage:
///   EmptyStateView(icon: "tray.fill", title: L("لا توجد معاملات"))
///   EmptyStateView(icon: "checkmark.circle.fill", title: L("لا توجد فواتير"),
///                  subtitle: L("ستظهر فواتيرك القادمة هنا"))
struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = .maJuTaTextSecondary
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? MaJuTaSpacing.xs : MaJuTaSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: compact ? 28 : 44))
                .foregroundColor(iconColor.opacity(0.5))
            Text(title)
                .font(compact ? .maJuTaCaption : .maJuTaBodyMedium)
                .foregroundColor(.maJuTaTextSecondary)
                .multilineTextAlignment(.center)
            if let sub = subtitle {
                Text(sub)
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(compact ? MaJuTaSpacing.lg : MaJuTaSpacing.xxl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.map { "\(title). \($0)" } ?? title)
    }
}

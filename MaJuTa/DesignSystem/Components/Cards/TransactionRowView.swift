import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject var dataStore: DataStore

    var category: TransactionCategory? {
        dataStore.category(for: transaction.categoryId)
    }

    var isIncome: Bool { transaction.amount > 0 }

    var body: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                SARText.bodyBold(abs(transaction.amount),
                    color: isIncome ? .maJuTaPositive : .maJuTaNegative)
                Text(transaction.paymentMethod.displayName)
                    .font(.maJuTaLabel)
                    .foregroundColor(.maJuTaTextSecondary)
            }

            Spacer()

            // Merchant + Category
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.merchant.isEmpty ? category?.nameArabic ?? "" : transaction.merchant)
                    .font(.maJuTaBodyMedium)
                    .foregroundColor(.maJuTaTextPrimary)
                    .lineLimit(1)
                Text(transaction.date.shortFormatted)
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
            }

            // Category Icon
            categoryBadge
        }
        .padding(.horizontal, MaJuTaSpacing.md)
        .padding(.vertical, MaJuTaSpacing.sm)
        .background(Color.maJuTaCard)
    }

    private var categoryBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                .fill(Color(hex: category?.colorHex ?? "#6B7280").opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: category?.icon ?? "circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: category?.colorHex ?? "#6B7280"))
        }
    }
}

struct BillRowView: View {
    let bill: Bill
    var onPay: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            // Pay button (only for unpaid bills)
            if bill.status != .paid, let onPay {
                Button(action: onPay) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.maJuTaPositive)
                }
                .buttonStyle(.plain)
            }

            // Amount + Due date
            VStack(alignment: .trailing, spacing: 2) {
                SARText.bodyBold(bill.amount)
                Text(bill.dueDate.gregorianFormatted)
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
            }

            Spacer()

            // Bill info
            VStack(alignment: .trailing, spacing: 2) {
                Text(bill.nameArabic.isEmpty ? bill.name : bill.nameArabic)
                    .font(.maJuTaBodyMedium)
                    .foregroundColor(.maJuTaTextPrimary)
                if bill.isDueSoon && bill.status != .paid {
                    Text("خلال \(bill.daysUntilDue) أيام")
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaWarning)
                } else if bill.isOverdue {
                    Text("متأخرة")
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaNegative)
                } else {
                    Text(bill.provider.isEmpty ? bill.frequency.displayName : bill.provider)
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                }
            }

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: MaJuTaRadius.small)
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: bill.status == .paid ? "checkmark.circle.fill" : "bolt.horizontal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
            }
        }
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    var statusColor: Color {
        if bill.status == .paid  { return .maJuTaPositive }
        if bill.isOverdue        { return .maJuTaNegative }
        if bill.isDueSoon        { return .maJuTaWarning }
        return .maJuTaGold
    }
}

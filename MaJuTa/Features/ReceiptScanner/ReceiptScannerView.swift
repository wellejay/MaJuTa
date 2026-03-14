import SwiftUI

struct ReceiptScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore
    @State private var capturedImage: UIImage?
    @State private var extractedData: ExtractedReceiptData?
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if capturedImage != nil {
                    receiptReview
                } else {
                    cameraPlaceholder
                }
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("مسح الفاتورة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إلغاء") { dismiss() }.foregroundColor(.maJuTaTextSecondary)
                }
            }
        }
    }

    private var cameraPlaceholder: some View {
        VStack(spacing: MaJuTaSpacing.xl) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                    .strokeBorder(Color.maJuTaGold, style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .frame(width: 280, height: 380)
                VStack(spacing: MaJuTaSpacing.md) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 64)).foregroundColor(.maJuTaGold)
                    Text("وجّه الكاميرا نحو الفاتورة")
                        .font(.maJuTaBodyMedium).foregroundColor(.maJuTaTextPrimary).multilineTextAlignment(.center)
                    Text("سنستخرج بيانات التاجر والمبلغ وضريبة القيمة المضافة تلقائياً")
                        .font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }
            }
            Spacer()
            HStack(spacing: MaJuTaSpacing.md) {
                Button {
                    // Image picker placeholder
                } label: {
                    Label("من المكتبة", systemImage: "photo.on.rectangle")
                        .font(.maJuTaBodyMedium).foregroundColor(.maJuTaGold)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.maJuTaGold.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
                Button {
                    withAnimation { capturedImage = UIImage() }
                    simulateOCR()
                } label: {
                    Label("التقاط", systemImage: "camera.fill")
                        .font(.maJuTaBodyBold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.maJuTaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.bottom, MaJuTaSpacing.xxl)
        }
    }

    private var receiptReview: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.lg) {
                if isProcessing {
                    VStack(spacing: MaJuTaSpacing.md) {
                        ProgressView().scaleEffect(1.5).tint(Color.maJuTaGold)
                        Text("جاري استخراج البيانات...")
                            .font(.maJuTaBody).foregroundColor(.maJuTaTextSecondary)
                    }
                    .frame(maxWidth: .infinity).padding(MaJuTaSpacing.xxl)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                } else if let data = extractedData {
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
                        Label("تم استخراج البيانات بنجاح", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.maJuTaPositive).font(.maJuTaBodyMedium)

                        VStack(spacing: 1) {
                            extractedRow(label: "التاجر", value: data.merchant)
                            Divider()
                            extractedRow(label: "الإجمالي", value: data.total.sarFormattedDecimal)
                            Divider()
                            extractedRow(label: "ضريبة القيمة المضافة", value: data.vatAmount.sarFormattedDecimal)
                            Divider()
                            extractedRow(label: "التاريخ", value: data.date.gregorianFormatted)
                        }
                        .background(Color.maJuTaCard)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                        .maJuTaCardShadow()
                    }

                    Button("إنشاء معاملة") { createTransaction(from: data) }
                        .font(.maJuTaBodyBold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.maJuTaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))

                    Button("مسح فاتورة أخرى") {
                        capturedImage = nil; extractedData = nil
                    }
                    .font(.maJuTaBodyMedium).foregroundColor(.maJuTaTextSecondary)
                }
            }
            .padding(MaJuTaSpacing.horizontalPadding).padding(.vertical, MaJuTaSpacing.lg)
        }
    }

    private func extractedRow(label: String, value: String) -> some View {
        HStack {
            Text(value).font(.maJuTaBody).foregroundColor(.maJuTaTextPrimary)
            Spacer()
            Text(label).font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
        }.padding(MaJuTaSpacing.md)
    }

    private func createTransaction(from data: ExtractedReceiptData) {
        guard let user = UserService.shared.currentUser,
              let account = dataStore.visibleAccounts.first,
              let category = dataStore.categories.first(where: { $0.type == .expense }) else {
            dismiss()
            return
        }
        let tx = Transaction(
            amount: -abs(data.total),
            date: data.date,
            categoryId: category.id,
            accountId: account.id,
            merchant: data.merchant,
            paymentMethod: .mada,
            note: "مسح فاتورة",
            ownerUserId: user.id,
            createdByUserId: user.id
        )
        dataStore.addTransaction(tx)
        dismiss()
    }

    private func simulateOCR() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            extractedData = ExtractedReceiptData(merchant: "هايبر بنده", total: 287.50, vatAmount: 37.50, date: Date())
            isProcessing = false
        }
    }
}

struct ExtractedReceiptData {
    var merchant: String
    var total: Double
    var vatAmount: Double
    var date: Date
}

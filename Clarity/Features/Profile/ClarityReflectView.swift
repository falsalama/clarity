import SwiftUI
import StoreKit

struct ClarityReflectView: View {
    @EnvironmentObject private var reflectStore: ClarityReflectStore
    @Environment(\.dismiss) private var dismiss

    fileprivate enum AccountCardKind {
        case current
        case monthly
        case annual
        case support
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account")
                        .font(.title2.weight(.semibold))

                    Text("Core features stay free. Account manages paid Reflect tools and support.")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if reflectStore.hasPaidTier {
                        Label("Paid Reflect access is active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.footnote.weight(.semibold))
                    } else {
                        Text("The rest of Clarity stays available without a subscription. Perspective, Options, Questions, and Talk it through require Clarity Reflect or Support Clarity.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Current plan")

                    currentPlanCard
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Plans")

                    if reflectStore.isLoadingProducts && reflectStore.reflectProducts.isEmpty {
                        ProgressView("Loading plans…")
                    } else if reflectStore.reflectProducts.isEmpty {
                        placeholderPlanCard(
                            kind: .monthly,
                            title: "Monthly",
                            subtitle: monthlyDescription,
                            badge: nil,
                            price: plannedPrice(for: .monthly),
                            buttonTitle: "Coming soon"
                        )

                        placeholderPlanCard(
                            kind: .annual,
                            title: "Annual",
                            subtitle: annualDescription,
                            badge: nil,
                            price: plannedPrice(for: .annual),
                            buttonTitle: "Coming soon"
                        )
                    } else {
                        ForEach(reflectStore.reflectProducts, id: \.id) { product in
                            planRow(for: product)
                        }
                    }

                    Text("Perspective, Options, Questions, and Talk it through are paid Reflect tools. When you choose a Cloud Tap response, only the selected redacted text is sent. Audio and raw transcripts stay on this iPhone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

#if DEBUG
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Developer testing")

                    Toggle(
                        "Unlock Clarity Reflect on this device",
                        isOn: Binding(
                            get: { reflectStore.hasDebugReflectOverride },
                            set: { reflectStore.setDebugReflectOverride($0) }
                        )
                    )

                    Text("Debug only. This bypasses the subscription gate locally so you can test the premium flow before StoreKit products are live.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
#endif

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Support Clarity")

                    if let product = reflectStore.supportProduct {
                        supportRow(for: product)
                    } else if reflectStore.isLoadingProducts {
                        ProgressView("Loading support option…")
                    } else {
                        placeholderPlanCard(
                            kind: .support,
                            title: "Support Clarity",
                            subtitle: "A one-time contribution to help support ongoing work on the app.",
                            badge: nil,
                            price: plannedPrice(for: .support),
                            buttonTitle: "Coming soon"
                        )
                    }

                    Text("This is a one-time purchase. It also unlocks the paid Reflect tools on this Apple ID.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Already subscribed?")

                    Text("Use Restore Purchases only if you already subscribed on this Apple ID and the plan is not showing here yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Subscription management stays in your App Store account settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if reflectStore.isRefreshingEntitlements {
                        ProgressView("Refreshing purchases…")
                    }

                    Button("Restore Purchases") {
                        Task { await reflectStore.restorePurchases() }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Account")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            await reflectStore.prepare()
        }
        .alert("Purchase issue", isPresented: Binding(
            get: { reflectStore.lastError != nil },
            set: { if !$0 { reflectStore.lastError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reflectStore.lastError ?? "")
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private var currentPlanCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(currentPlanTitle)
                .font(.headline)

            Text(currentPlanSubtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !reflectStore.hasPaidTier {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Included with Free")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    benefitRow("Daily Practice")
                    benefitRow("Calendar")
                    benefitRow("Audio")
                    benefitRow("Meditation timer")
                    benefitRow("Learning")
                    benefitRow("Capsule")
                    benefitRow("Portrait")
                    benefitRow("Wisdom daily")
                    benefitRow("Compassion daily")
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Not included with Free")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    unavailableRow("Perspective")
                    unavailableRow("Options and Questions")
                    unavailableRow("Talk it through")
                    unavailableRow("Extended Buddhist responses")
                    unavailableRow("Expanded audio library")
                }
            }
        }
        .accountCardStyle(kind: currentCardKind, accent: cardAccent(for: currentCardKind))
    }

    private func planRow(for product: Product) -> some View {
        let kind = planKind(for: product)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName(for: product))
                        .font(.headline)

                    Text(planDescription(for: product))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.headline)

                    if let badge = badgeText(for: product) {
                        Text(badge)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(cardAccent(for: kind).opacity(0.12))
                            )
                            .foregroundStyle(cardAccent(for: kind))
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Included")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                benefitRow("Perspective")
                benefitRow("Options and Questions")
                benefitRow("Talk it through")
                benefitRow("Extended Buddhist responses")
                benefitRow("Expanded audio library")
            }

            Button {
                Task { await reflectStore.purchase(product) }
            } label: {
                Text(productButtonTitle(for: product))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(cardAccent(for: kind))
            .disabled(reflectStore.isPurchasing || isCurrentPlan(product))
        }
        .accountCardStyle(kind: kind, accent: cardAccent(for: kind))
    }

    private func placeholderPlanCard(
        kind: AccountCardKind,
        title: String,
        subtitle: String,
        badge: String?,
        price: String,
        buttonTitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(price)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if let badge {
                        Text(badge)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(cardAccent(for: kind).opacity(0.12))
                            )
                            .foregroundStyle(cardAccent(for: kind))
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Included")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                benefitRow("Perspective")
                benefitRow("Options and Questions")
                benefitRow("Talk it through")
                benefitRow("Extended Buddhist responses")
                benefitRow("Expanded audio library")
            }

            Button(buttonTitle) {}
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .tint(cardAccent(for: kind))
                .disabled(true)
        }
        .accountCardStyle(kind: kind, accent: cardAccent(for: kind))
    }

    private func supportRow(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support Clarity")
                        .font(.headline)

                    Text("A one-time purchase that supports the app and unlocks the paid Reflect tools.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Text(product.displayPrice)
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Included")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                benefitRow("Perspective")
                benefitRow("Options and Questions")
                benefitRow("Talk it through")
                benefitRow("Extended Buddhist responses")
                benefitRow("Expanded audio library")
            }

            if reflectStore.hasSupportedClarity {
                Label("Thank you for supporting Clarity", systemImage: "heart.fill")
                    .foregroundStyle(cardAccent(for: .support))
                    .font(.footnote.weight(.semibold))
            } else {
                Button {
                    Task { await reflectStore.purchase(product) }
                } label: {
                    Text("Support Clarity")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(cardAccent(for: .support))
                .disabled(reflectStore.isPurchasing)
            }
        }
        .accountCardStyle(kind: .support, accent: cardAccent(for: .support))
    }

    private func displayName(for product: Product) -> String {
        switch product.id {
        case ClarityReflectStore.monthlyProductID:
            return "Monthly"
        case ClarityReflectStore.annualProductID:
            return "Annual"
        default:
            return product.displayName
        }
    }

    private func planKind(for product: Product) -> AccountCardKind {
        switch product.id {
        case ClarityReflectStore.monthlyProductID:
            return .monthly
        case ClarityReflectStore.annualProductID:
            return .annual
        default:
            return .current
        }
    }

    private func planDescription(for product: Product) -> String {
        switch product.id {
        case ClarityReflectStore.monthlyProductID:
            return monthlyDescription
        case ClarityReflectStore.annualProductID:
            return annualDescription
        default:
            return product.description
        }
    }

    private func productButtonTitle(for product: Product) -> String {
        if isCurrentPlan(product) {
            return "Current plan"
        }

        if let current = reflectStore.currentReflectProductID {
            switch (current, product.id) {
            case (ClarityReflectStore.monthlyProductID, ClarityReflectStore.annualProductID):
                return "Upgrade to annual"
            case (ClarityReflectStore.annualProductID, ClarityReflectStore.monthlyProductID):
                return "Switch to monthly"
            default:
                break
            }
        }

        switch product.id {
        case ClarityReflectStore.monthlyProductID:
            return "Subscribe monthly"
        case ClarityReflectStore.annualProductID:
            return "Subscribe annually"
        default:
            return "Subscribe"
        }
    }

    private func badgeText(for product: Product) -> String? {
        if isCurrentPlan(product) {
            return "Current plan"
        }
        return nil
    }

    private func isCurrentPlan(_ product: Product) -> Bool {
        reflectStore.currentReflectProductID == product.id
    }

    private var currentCardKind: AccountCardKind {
        if reflectStore.currentReflectProductID == nil && reflectStore.hasSupportedClarity {
            return .support
        }
        guard let currentID = reflectStore.currentReflectProductID else { return .current }
        switch currentID {
        case ClarityReflectStore.monthlyProductID:
            return .monthly
        case ClarityReflectStore.annualProductID:
            return .annual
        default:
            return .current
        }
    }

    private var currentPlanTitle: String {
        reflectStore.accountTierTitle
    }

    private var currentPlanSubtitle: String {
#if DEBUG
        if reflectStore.hasDebugReflectOverride && !reflectStore.hasPaidTier {
            return "You are on the free plan. Perspective, Options, Questions, and Talk it through require Clarity Reflect or Support Clarity."
        }
#endif
        if reflectStore.isSupportOnlyActive {
            return "Support Clarity is active on this Apple ID. Paid Reflect tools are unlocked."
        }
        if reflectStore.hasPaidTier {
            return "Paid Reflect tools are unlocked on this Apple ID."
        }
        return "You are on the free plan. Perspective, Options, Questions, and Talk it through require Clarity Reflect or Support Clarity."
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func unavailableRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var monthlyDescription: String {
        "Unlocks Perspective, Options, Questions, and Talk it through in Reflect."
    }

    private var annualDescription: String {
        "The same paid Reflect tools, with a lower total over the year than monthly."
    }

    private func cardAccent(for kind: AccountCardKind) -> Color {
        switch kind {
        case .current:
            return Color(red: 0.31, green: 0.42, blue: 0.60)
        case .monthly:
            return Color(red: 0.08, green: 0.41, blue: 0.82)
        case .annual:
            return Color(red: 0.78, green: 0.52, blue: 0.08)
        case .support:
            return Color(red: 0.72, green: 0.22, blue: 0.32)
        }
    }

    private func plannedPrice(for kind: AccountCardKind) -> String {
        switch kind {
        case .monthly:
            return "4.99 / month"
        case .annual:
            return "49.99 / year"
        case .support:
            return "14.99 once"
        case .current:
            return ""
        }
    }
}

#Preview {
    NavigationStack {
        ClarityReflectView()
            .environmentObject(ClarityReflectStore())
    }
}

private struct AccountCardStyleModifier: ViewModifier {
    let kind: ClarityReflectView.AccountCardKind
    let accent: Color

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 4)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(kind == .current ? 0.10 : 0.16),
                                        accent.opacity(kind == .current ? 0.03 : 0.07)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(accent.opacity(0.42), lineWidth: 1.2)
                    }
                    .shadow(color: accent.opacity(0.10), radius: 14, y: 6)
            }
    }
}

private extension View {
    func accountCardStyle(kind: ClarityReflectView.AccountCardKind, accent: Color) -> some View {
        modifier(AccountCardStyleModifier(kind: kind, accent: accent))
    }
}

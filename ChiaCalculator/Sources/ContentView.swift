import SwiftUI

struct ContentView: View {
    @State private var model = ChiaCalculatorViewModel()
    @State private var showError = false
    @State private var hasAppeared = false
    @State private var sliderValue: Double = 0
    @State private var refreshTapCount = 0
    @State private var refreshSpinAngle: Double = 0
    @State private var isSliderEditing = false
    @State private var plotUpdateFromSlider = false
    @FocusState private var isPlotFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        @Bindable var model = model

        ZStack {
            BackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    inputSection
                    resultsSection
                    lastUpdatedView
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .opacity(hasAppeared ? 1 : 0)
                .animation(reduceMotion ? .none : .easeOut(duration: 0.6), value: hasAppeared)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isPlotFieldFocused = false
        }
        .task {
            hasAppeared = true
            sliderValue = sliderPosition(for: model.plotCount)
            await model.loadIfNeeded()
        }
        .onChange(of: model.errorMessage) {
            showError = model.errorMessage != nil
        }
        .alert(String(localized: "error_title"), isPresented: $showError) {
            Button(String(localized: "error_ok")) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .overlay {
            if model.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "keyboard_done")) {
                    isPlotFieldFocused = false
                }
            }
        }
    }

    private var heroSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(String(localized: "app_title"))
                        .font(.system(size: 33, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .shadow(color: Theme.glow.opacity(0.35), radius: 12, x: 0, y: 6)
                    Spacer()
                    refreshButton
                }

                Text(String(localized: "hero_subtitle"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(alignment: .bottom, spacing: 12) {
                    HeroChip(title: String(localized: "owned_space_label"), value: ownedSpaceText)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(1)
                    HeroChip(title: String(localized: "xch_price_label"), value: priceOrPlaceholder)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(1)
                }
                .frame(height: 64)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(HeroMesh(), alignment: .topTrailing)
        .accessibilityElement(children: .combine)
    }

    private var inputSection: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: String(localized: "input_section_title"))

                HStack(alignment: .center, spacing: 12) {
                    Slider(value: Binding(
                        get: { sliderValue },
                        set: { newValue in
                            sliderValue = newValue
                            plotUpdateFromSlider = true
                            model.plotCount = plotsForSlider(newValue)
                        }
                    ), in: 0...1, onEditingChanged: { editing in
                        isSliderEditing = editing
                    })
                    .tint(Theme.accent)
                    .sensoryFeedback(.selection, trigger: model.plotCount)

                    TextField("10", value: $model.plotCount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 90)
                        .accessibilityLabel(String(localized: "plots_label"))
                        .focused($isPlotFieldFocused)
                        .onChange(of: model.plotCount) {
                            guard !isSliderEditing, !plotUpdateFromSlider else { return }
                            sliderValue = sliderPosition(for: model.plotCount)
                        }

                    StepperControl(
                        onDecrease: { adjustPlots(by: -10) },
                        onIncrease: { adjustPlots(by: 10) }
                    )
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )

                HStack(spacing: 12) {
                    Picker(String(localized: "k_size_label"), selection: $model.selectedKSize) {
                        ForEach(KSize.allCases) { size in
                            Text(size.label).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(String(localized: "compression_label"), selection: $model.selectedCompression) {
                        ForEach(CompressionLevel.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                }

                Text(String(format: String(localized: "plot_hint_dynamic"), model.plotSizeGiB))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .modifier(CardEntrance(delay: 0.05, reduceMotion: reduceMotion))
    }

    private var resultsSection: some View {
        VStack(spacing: 16) {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: String(localized: "network_section_title"))
                    ResultRow(title: String(localized: "netspace_label"), value: netspaceText)
                    ResultRow(title: String(localized: "owned_space_percent_label"), value: ownedSpacePercentText)
                    ResultRow(title: String(localized: "block_reward_label"), value: blockRewardText)
                    ResultRow(title: String(localized: "expected_time_label"), value: expectedTimeText)
                }
            }
            .modifier(CardEntrance(delay: 0.1, reduceMotion: reduceMotion))

            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: String(localized: "earnings_section_title"))
                    ResultRow(title: String(localized: "hourly_label"), value: earningsText(model.earningsHourlyXCH), secondary: earningsUSDText(model.earningsHourlyXCH))
                    ResultRow(title: String(localized: "daily_label"), value: earningsText(model.earningsDailyXCH), secondary: earningsUSDText(model.earningsDailyXCH))
                    ResultRow(title: String(localized: "monthly_label"), value: earningsText(model.earningsMonthlyXCH), secondary: earningsUSDText(model.earningsMonthlyXCH))
                }
            }
            .modifier(CardEntrance(delay: 0.15, reduceMotion: reduceMotion))

            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: String(localized: "chances_section_title"))
                    ResultRow(title: String(localized: "hourly_label"), value: chanceText(hours: 1))
                    ResultRow(title: String(localized: "daily_label"), value: chanceText(hours: 24))
                    ResultRow(title: String(localized: "monthly_label"), value: chanceText(hours: 24 * 30))
                }
            }
            .modifier(CardEntrance(delay: 0.2, reduceMotion: reduceMotion))
        }
    }

    private var exchangeRateBadge: some View {
        Group {
            if let price = model.xchPriceUSD {
                GlassBadge(label: "XCH", value: priceText(price))
                .accessibilityLabel(String(localized: "exchange_rate_label"))
                .accessibilityValue(priceText(price))
            }
        }
    }

    private var lastUpdatedView: some View {
        Group {
            if let lastUpdated = model.lastUpdated {
                Text(String(localized: "last_updated_label"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .overlay(alignment: .trailing) {
                        Text(lastUpdated, style: .time)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 6)
                    }
            }
        }
        .accessibilityLabel(String(localized: "last_updated_label"))
    }

    private var refreshButton: some View {
        Button {
            refreshTapCount += 1
            spinOnce()
            Task { await model.refresh(showSpinner: false) }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .bold))
                .modifier(RefreshSpin(isRefreshing: model.isRefreshing, reduceMotion: reduceMotion, manualAngle: refreshSpinAngle))
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(String(localized: "refresh_label"))
        .sensoryFeedback(.impact(flexibility: .soft), trigger: refreshTapCount)
    }

    private var ownedSpaceText: String {
        let formatter = ChiaFormatters.bytesFormatter()
        return formatter.string(fromByteCount: safeByteCount(model.ownedSpaceBytes))
    }

    private var netspaceText: String {
        guard let netspaceBytes = model.netspaceBytes else { return String(localized: "loading_placeholder") }
        let formatter = ChiaFormatters.bytesFormatter()
        return formatter.string(fromByteCount: safeByteCount(netspaceBytes))
    }

    private var ownedSpacePercentText: String {
        guard let percent = model.ownedSpacePercent else { return String(localized: "loading_placeholder") }
        return ChiaFormatters.percent.string(from: NSNumber(value: percent)) ?? "-"
    }

    private var expectedTimeText: String {
        guard let days = model.expectedTimeToWinDays else { return String(localized: "loading_placeholder") }
        let hours = days * 24
        if hours < 48 {
            return String(format: String(localized: "hours_format"), hours)
        }
        return String(format: String(localized: "days_format"), days)
    }

    private var priceOrPlaceholder: String {
        guard let price = model.xchPriceUSD else { return String(localized: "loading_placeholder") }
        return priceText(price)
    }

    private func earningsText(_ xch: Double?) -> String {
        guard let xch else { return String(localized: "loading_placeholder") }
        return (ChiaFormatters.xch.string(from: NSNumber(value: xch)) ?? "-") + " XCH"
    }

    private func earningsUSDText(_ xch: Double?) -> String? {
        guard let usd = model.earningsUSD(xch) else { return nil }
        return ChiaFormatters.currencyUSD.string(from: NSNumber(value: usd))
    }

    private func chanceText(hours: Double) -> String {
        guard let chance = model.chanceToWin(hours: hours) else { return String(localized: "loading_placeholder") }
        return ChiaFormatters.percent.string(from: NSNumber(value: chance)) ?? "-"
    }

    private func plotsForSlider(_ value: Double) -> Int {
        let minPlots = 1.0
        let maxPlots = 200_000.0
        let exponent = 4.0
        let scaled = pow(value, exponent)
        return Int((minPlots + (maxPlots - minPlots) * scaled).rounded())
    }

    private func sliderPosition(for plots: Int) -> Double {
        let minPlots = 1.0
        let maxPlots = 200_000.0
        let exponent = 4.0
        let clamped = min(max(Double(plots), minPlots), maxPlots)
        let normalized = (clamped - minPlots) / (maxPlots - minPlots)
        return pow(normalized, 1.0 / exponent)
    }

    private func adjustPlots(by delta: Int) {
        let next = max(1, model.plotCount + delta)
        model.plotCount = next
        sliderValue = sliderPosition(for: next)
    }

    private var blockRewardText: String {
        guard let reward = model.rewardPerBlock else { return String(localized: "loading_placeholder") }
        return (ChiaFormatters.xch.string(from: NSNumber(value: reward)) ?? "-") + " XCH"
    }

    private func priceText(_ value: Double) -> String {
        ChiaFormatters.currencyUSD.string(from: NSNumber(value: value)) ?? "-"
    }

    private func safeByteCount(_ value: Double) -> Int64 {
        if value.isNaN || value.isInfinite { return 0 }
        let clamped = min(value, Double(Int64.max))
        return Int64(clamped)
    }

    private func spinOnce() {
        guard !reduceMotion else { return }
        refreshSpinAngle += 360
    }

    private var contentMaxWidth: CGFloat? {
        horizontalSizeClass == .regular ? 540 : nil
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
    }
}

private struct ResultRow: View {
    let title: String
    let value: String
    var secondary: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                if let secondary {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct HeroChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct GlassBadge: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Theme.accent.opacity(0.2), in: Capsule())

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }
}

private struct StepperControl: View {
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onDecrease) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(String(localized: "decrease_plots_label"))

            Button(action: onIncrease) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(String(localized: "increase_plots_label"))
        }
    }
}

private struct RefreshSpin: ViewModifier {
    let isRefreshing: Bool
    let reduceMotion: Bool
    let manualAngle: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees((isRefreshing ? 360 : 0) + manualAngle))
            .animation(
                reduceMotion
                ? .default
                : (isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default),
                value: isRefreshing
            )
            .animation(reduceMotion ? .default : .easeOut(duration: 0.5), value: manualAngle)
    }
}

private struct LiquidGlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(liquidGlassBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Theme.shadow, radius: 24, x: 0, y: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .modifier(LiquidGlassHighlight())
            .modifier(EdgeGlow())
    }

    @ViewBuilder
    private var liquidGlassBackground: some View {
        if #available(iOS 26, *) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.glow.opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.accent.opacity(0.16),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 10,
                            endRadius: 220
                        )
                    )
            }
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.thinMaterial)
        }
    }
}

private struct BackgroundView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(
                    colors: [
                        Theme.backgroundTop,
                        Theme.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Theme.glow.opacity(0.18))
                    .frame(width: size.width * 0.9)
                    .blur(radius: 60)
                    .offset(x: -size.width * 0.35, y: -size.height * 0.3)

                Circle()
                    .fill(Theme.glow.opacity(0.14))
                    .frame(width: size.width * 0.8)
                    .blur(radius: 80)
                    .offset(x: size.width * 0.4, y: -size.height * 0.4)

                if #available(iOS 26, *) {
                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: size.width * 0.9, height: size.height * 0.4)
                        .offset(y: -size.height * 0.15)
                        .blur(radius: 20)
                        .opacity(0.6)
                }
            }
        }
    }
}

private enum Theme {
    static let accent = Color(red: 0.28, green: 0.96, blue: 0.78)
    static let glow = Color(red: 0.55, green: 1.0, blue: 0.9)
    static let backgroundTop = Color(red: 0.04, green: 0.5, blue: 0.4)
    static let backgroundBottom = Color(red: 0.03, green: 0.12, blue: 0.2)
    static let shadow = Color.black.opacity(0.28)
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct LiquidGlassHighlight: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.screen)
                    .opacity(reduceMotion ? 0.5 : 0.8)
                    .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                        .blur(radius: 1.2)
                        .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .allowsHitTesting(false)
                )
        } else {
            content
        }
    }
}

private struct EdgeGlow: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .overlay(
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let phase = sin(time * 0.6) * 0.5 + 0.5
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Theme.accent.opacity(0.15 + phase * 0.25),
                                        Theme.glow.opacity(0.2 + phase * 0.3),
                                        Theme.accent.opacity(0.1 + phase * 0.2)
                                    ],
                                    center: .center
                                ),
                                lineWidth: 1.2
                            )
                            .blur(radius: 0.8)
                            .opacity(reduceMotion ? 0.4 : 0.8)
                            .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .allowsHitTesting(false)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.glow.opacity(0.25), lineWidth: 4)
                        .blur(radius: 8)
                        .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .allowsHitTesting(false)
                )
        } else {
            content
        }
    }
}

private struct CardEntrance: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.55).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

private struct HeroMesh: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.glow.opacity(0.25))
                .frame(width: 120, height: 120)
                .blur(radius: 18)
                .offset(x: 20, y: -18)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.accent.opacity(0.3),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 90)
                .rotationEffect(.degrees(12))
                .blur(radius: 2)
        }
        .allowsHitTesting(false)
        .padding(.top, 8)
        .padding(.trailing, 8)
    }
}

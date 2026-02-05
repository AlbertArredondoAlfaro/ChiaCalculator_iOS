import SwiftUI

@main
struct ChiaCalculatorApp: App {
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some Scene {
        WindowGroup {
            ZStack {
                NavigationStack {
                    ContentView()
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .zIndex(1)
                        .allowsHitTesting(true)
                }
            }
            .task {
                guard showSplash else { return }
                let delay: UInt64 = reduceMotion ? 500_000_000 : 900_000_000
                try? await Task.sleep(nanoseconds: delay)
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.6)) {
                    showSplash = false
                }
            }
        }
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.5, blue: 0.4),
                    Color(red: 0.03, green: 0.12, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.white.opacity(0.2), radius: 16, x: 0, y: 8)

                Text(String(localized: "app_title"))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.95))
            }
        }
    }
}

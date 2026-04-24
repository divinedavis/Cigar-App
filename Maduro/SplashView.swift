import SwiftUI

/// Splash entry shown while the user is signed out. Animated cigar-
/// smoke background, logo + wordmark + tagline, and two Continue
/// buttons at the bottom that route directly into the auth flow
/// (email form or Apple stub) — no intermediate screen.
struct SplashView: View {
    @EnvironmentObject var session: SessionStore
    @State private var path: [AuthRoute] = []
    @State private var showAppleSoon = false
    @State private var titleAppeared = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AnimatedSmokeBackground()

                // Top status-bar-area dim so signal/battery icons stay legible.
                VStack {
                    LinearGradient(
                        colors: [.black.opacity(0.45), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 140)
                    Spacer()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Bottom dim so the buttons always pop even when embers are bright.
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.75)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 380)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Logo + tagline — sits roughly in the upper third.
                VStack(spacing: 18) {
                    Spacer().frame(height: 90)

                    Image("MaduroLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: .black.opacity(0.5), radius: 14, y: 4)
                        .opacity(titleAppeared ? 1 : 0)
                        .scaleEffect(titleAppeared ? 1 : 0.92)

                    Text("M A D U R O")
                        .font(.system(size: 32, weight: .light, design: .default))
                        .tracking(10)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 8, y: 2)
                        .opacity(titleAppeared ? 1 : 0)
                        .offset(y: titleAppeared ? 0 : 10)

                    Text("A community for cigar lovers —\nshare, savor, discover.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                        .opacity(titleAppeared ? 1 : 0)

                    Spacer()
                }

                // Bottom auth CTAs.
                VStack(spacing: 12) {
                    Spacer()
                    Button { path.append(.email) } label: {
                        ContinueWithRow(icon: "envelope", title: "Continue with email")
                    }
                    Button { showAppleSoon = true } label: {
                        ContinueWithRow(icon: "applelogo", title: "Continue with Apple")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .email:
                    EmailAuthView(path: $path)
                case .ageGate(let method, let identifier, let displayName):
                    AgeGateView(method: method, identifier: identifier, displayName: displayName)
                }
            }
            .alert("Apple sign-in coming soon", isPresented: $showAppleSoon) {
                Button("OK") {}
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                titleAppeared = true
            }
        }
    }
}

// MARK: - Background

/// Animated cigar-smoke / ember atmosphere built entirely in SwiftUI.
///
/// Three layers:
///   1. A dark base gradient (black → tobacco brown).
///   2. A slowly drifting radial "ember glow" that simulates the
///      orange tip of a cigar warming the room.
///   3. A particle field of small orange embers that rise from bottom
///      to top, jitter horizontally, fade in and out.
struct AnimatedSmokeBackground: View {
    private let embers: [Ember]

    init() {
        embers = (0..<22).map { i in
            Ember(
                index: i,
                xFraction: Double.random(in: 0.05...0.95),
                durationSeconds: Double.random(in: 7...14),
                size: CGFloat.random(in: 2...5),
                hue: Double.random(in: 0.03...0.10),
                phaseOffset: Double.random(in: 0...1)
            )
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .black,
                    Color(red: 0.12, green: 0.06, blue: 0.02),
                    .black
                ],
                startPoint: .top, endPoint: .bottom
            )

            DriftingGlow()
                .blendMode(.screen)
                .opacity(0.85)

            EmberField(embers: embers)

            // Subtle vignette around the edges.
            RadialGradient(
                colors: [.clear, .black.opacity(0.55)],
                center: .center,
                startRadius: 220,
                endRadius: 700
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

private struct DriftingGlow: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let cx = 0.5 + 0.18 * sin(t / 7)
            let cy = 0.7 + 0.12 * cos(t / 9)
            RadialGradient(
                colors: [
                    Color.orange.opacity(0.22),
                    Color.orange.opacity(0.06),
                    .clear
                ],
                center: UnitPoint(x: cx, y: cy),
                startRadius: 30,
                endRadius: 360
            )
        }
    }
}

private struct EmberField: View {
    let embers: [Ember]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(embers) { ember in
                        emberView(ember, t: t, in: geo.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func emberView(_ ember: Ember, t: TimeInterval, in size: CGSize) -> some View {
        let raw = (t / ember.durationSeconds + ember.phaseOffset)
        let phase = raw - floor(raw)            // 0...1
        let yFraction = 1.0 - phase             // start near bottom, drift up
        let opacity = sin(phase * .pi) * 0.85   // fade in then out
        let xJitter = sin((t + Double(ember.index) * 1.3) * 0.6) * 0.025

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hue: ember.hue, saturation: 0.9, brightness: 1.0),
                        Color(hue: ember.hue, saturation: 0.9, brightness: 0.5).opacity(0.5),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: ember.size * 2
                )
            )
            .frame(width: ember.size * 4, height: ember.size * 4)
            .position(
                x: size.width * (ember.xFraction + xJitter),
                y: size.height * yFraction
            )
            .opacity(opacity)
            .blur(radius: 0.5)
    }
}

private struct Ember: Identifiable {
    let id = UUID()
    let index: Int
    let xFraction: Double
    let durationSeconds: Double
    let size: CGFloat
    let hue: Double
    let phaseOffset: Double
}

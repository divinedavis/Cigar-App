import SwiftUI

/// Splash entry shown while the user is signed out. Mirrors the TIDE
/// app layout: animated background, centered title, tagline, big white
/// pill button, plain "Log in" text below.
///
/// Both Start and Log in present the same AuthView (phone-first sign
/// up / sign in). We keep them as separate buttons so the entry point
/// reads naturally; if we later want to default Log in to a different
/// auth mode we can pass a hint into AuthView.
struct SplashView: View {
    @State private var showAuth = false
    @State private var titleAppeared = false

    var body: some View {
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

            // Bottom dim so the white button + Log in text always pop
            // even when the embers are bright.
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 360)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Title + tagline — sits roughly in the upper third.
            VStack(spacing: 22) {
                Spacer().frame(height: 130)

                Text("S T O G I E")
                    .font(.system(size: 38, weight: .light, design: .default))
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

            // Bottom CTAs.
            VStack(spacing: 18) {
                Spacer()
                Button {
                    showAuth = true
                } label: {
                    Text("Start")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.white, in: .capsule)
                        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.horizontal, 24)

                Button {
                    showAuth = true
                } label: {
                    Text("Log in")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                }
                .padding(.bottom, 18)
            }
        }
        .fullScreenCover(isPresented: $showAuth) {
            AuthView()
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

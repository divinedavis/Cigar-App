import SwiftUI

// MARK: - Routing

enum AuthRoute: Hashable {
    case email
    case ageGate(method: String, identifier: String, displayName: String)
}

// MARK: - Secondary method row (used by splash Continue buttons)

struct ContinueWithRow: View {
    let icon: String
    let title: String
    var iconColor: Color = .white

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 22)
                .foregroundStyle(iconColor)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        )
    }
}

// MARK: - Email path

/// Sign-in / sign-up form with a ShypQuick-style layout: small eyebrow
/// label, big bold two-line title, subtitle, underline fields, and a
/// full-width white pill primary button. Toggling between modes
/// animates the title, subtitle, the extra fields (Full name, Confirm
/// password), and the button label.
struct EmailAuthView: View {
    @Binding var path: [AuthRoute]
    @State private var isCreating: Bool = true
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var error: String?

    private let transitionAnimation: Animation = .spring(response: 0.42, dampingFraction: 0.88)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.18, green: 0.10, blue: 0.04)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    fields
                    errorRow
                    primaryButton
                    toggleLink
                        .padding(.top, 4)
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(isCreating ? "Let's get started." : "Welcome back.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .contentTransition(.opacity)

            Text(isCreating ? "Create your\nMaduro account." : "Sign in to\nyour humidor.")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(.white)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)

            Text(isCreating
                 ? "Share what you smoke, find what's next."
                 : "Your lounge, cigars, and pairings are waiting.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Fields

    private var fields: some View {
        VStack(spacing: 18) {
            if isCreating {
                UnderlineField(placeholder: "Full name", text: $name)
                    .transition(fieldTransition)
            }

            UnderlineField(placeholder: "Email", text: $email, keyboard: .emailAddress)

            UnderlineField(placeholder: "Password", text: $password, isSecure: true)

            if isCreating {
                UnderlineField(placeholder: "Confirm password",
                               text: $confirmPassword,
                               isSecure: true)
                    .transition(fieldTransition)
            }
        }
    }

    private var fieldTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: -12)),
            removal: .opacity.combined(with: .offset(y: -12))
        )
    }

    // MARK: Error row

    @ViewBuilder
    private var errorRow: some View {
        if let error {
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.red)
                .transition(.opacity)
        }
    }

    // MARK: Primary button

    private var primaryButton: some View {
        Button {
            submit()
        } label: {
            Text(isCreating ? "Create Account" : "Sign In")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.white, in: .capsule)
                .contentTransition(.opacity)
        }
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }

    // MARK: Toggle link

    private var toggleLink: some View {
        Button {
            withAnimation(transitionAnimation) {
                isCreating.toggle()
                error = nil
            }
        } label: {
            Text(isCreating
                 ? "Already have an account? Sign in"
                 : "Don't have an account? Sign up")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .underline()
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Submit

    private func submit() {
        error = nil

        let emailTrim = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !emailTrim.isEmpty, emailTrim.contains("@") else {
            withAnimation { error = "Enter a valid email." }
            return
        }
        guard password.count >= 6 else {
            withAnimation { error = "Password must be at least 6 characters." }
            return
        }

        if isCreating {
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            guard !trimmedName.isEmpty else {
                withAnimation { error = "Enter your name." }
                return
            }
            guard password == confirmPassword else {
                withAnimation { error = "Passwords don't match." }
                return
            }
            path.append(.ageGate(method: "email",
                                 identifier: emailTrim,
                                 displayName: trimmedName))
        } else {
            // Stub sign-in path — still goes through age gate until we wire
            // Supabase auth + profile fetch for returning users.
            let prefill = emailTrim.components(separatedBy: "@").first ?? "user"
            path.append(.ageGate(method: "email",
                                 identifier: emailTrim,
                                 displayName: prefill))
        }
    }
}

// MARK: - Underline field

private struct UnderlineField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if isSecure {
                    SecureField("", text: $text, prompt:
                        Text(placeholder).foregroundStyle(.white.opacity(0.45))
                    )
                } else {
                    TextField("", text: $text, prompt:
                        Text(placeholder).foregroundStyle(.white.opacity(0.45))
                    )
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                }
            }
            .font(.body)
            .foregroundStyle(.white)
            .padding(.vertical, 8)

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(height: 1)
        }
    }
}

// MARK: - Age gate

struct AgeGateView: View {
    let method: String
    let identifier: String
    let displayName: String

    @EnvironmentObject var session: SessionStore
    @State private var dob: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var name: String = ""
    @State private var accountType: AppUser.AccountType = .personal
    @State private var error: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.18, green: 0.10, blue: 0.04)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("One last thing")
                            .font(.title2).bold()
                            .foregroundStyle(.white)
                        Text("Maduro is for adults 21 and over.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    MaduroField("Display name", text: $name)

                    DatePicker("Date of birth",
                               selection: $dob,
                               in: ...Date(),
                               displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(14)
                        .background(.white.opacity(0.08),
                                    in: .rect(cornerRadius: 12))
                        .colorScheme(.dark)

                    Picker("Account type", selection: $accountType) {
                        Text("Personal").tag(AppUser.AccountType.personal)
                        Text("Business").tag(AppUser.AccountType.business)
                    }
                    .pickerStyle(.segmented)

                    if let error {
                        Text(error)
                            .font(.footnote).foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        create()
                    } label: {
                        Text("Create account")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Color.orange, in: .rect(cornerRadius: 12))

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        .navigationTitle("Almost there")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black.opacity(0.6), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { if name.isEmpty { name = displayName } }
    }

    private func create() {
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        guard age >= 21 else {
            error = "You must be 21 or older to use Maduro."
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            error = "Display name is required."
            return
        }
        let username = trimmed
            .lowercased()
            .components(separatedBy: .whitespaces)
            .joined(separator: "_")
        let user = AppUser(
            id: UUID(),
            username: username.isEmpty ? "maduro_user" : username,
            displayName: trimmed,
            bio: "",
            avatarURL: nil,
            dateOfBirth: dob,
            accountType: accountType,
            isVerified: false
        )
        // TODO: replace with real Supabase signUp/signIn keyed by `method` + `identifier`.
        session.signIn(as: user)
    }
}

// MARK: - Field primitives

struct MaduroField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    init(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) {
        self.label = label
        self._text = text
        self.keyboard = keyboard
    }

    var body: some View {
        TextField("", text: $text, prompt:
            Text(label).foregroundStyle(.white.opacity(0.55))
        )
        .textInputAutocapitalization(.never)
        .keyboardType(keyboard)
        .padding(14)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: 12))
        .foregroundStyle(.white)
    }
}

struct MaduroSecureField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        SecureField("", text: $text, prompt:
            Text(label).foregroundStyle(.white.opacity(0.55))
        )
        .padding(14)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: 12))
        .foregroundStyle(.white)
    }
}

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

struct EmailAuthView: View {
    @Binding var path: [AuthRoute]
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isCreating: Bool = true
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
                    Text(isCreating ? "Create your account" : "Welcome back")
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    MaduroField("Email", text: $email, keyboard: .emailAddress)
                    MaduroSecureField("Password", text: $password)

                    if let error {
                        Text(error)
                            .font(.footnote).foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        submit()
                    } label: {
                        Text(isCreating ? "Continue" : "Sign in")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Color.orange, in: .rect(cornerRadius: 12))

                    Button(isCreating ? "I already have an account"
                                      : "Create new account") {
                        isCreating.toggle()
                        error = nil
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        .navigationTitle(isCreating ? "Sign up" : "Log in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black.opacity(0.6), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            error = "Enter a valid email."
            return
        }
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters."
            return
        }
        let prefill = trimmedEmail.components(separatedBy: "@").first ?? "user"
        path.append(.ageGate(method: "email", identifier: trimmedEmail, displayName: prefill))
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

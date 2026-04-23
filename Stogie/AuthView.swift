import SwiftUI

struct AuthView: View {
    @EnvironmentObject var session: SessionStore
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var dob = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var accountType: AppUser.AccountType = .personal
    @State private var error: String?

    enum Mode { case signIn, signUp }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.black, Color(red: 0.25, green: 0.12, blue: 0.04)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header

                        VStack(spacing: 14) {
                            if mode == .signUp {
                                field("Username", text: $username)
                                field("Display name", text: $displayName)
                            }
                            field("Email", text: $email, keyboard: .emailAddress)
                            secureField("Password", text: $password)

                            if mode == .signUp {
                                DatePicker("Date of birth",
                                           selection: $dob,
                                           in: ...Date(),
                                           displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding(14)
                                    .background(.white.opacity(0.08), in: .rect(cornerRadius: 12))

                                Picker("Account type", selection: $accountType) {
                                    Text("Personal").tag(AppUser.AccountType.personal)
                                    Text("Business").tag(AppUser.AccountType.business)
                                }
                                .pickerStyle(.segmented)
                            }

                            if let error {
                                Text(error).font(.footnote).foregroundStyle(.red)
                            }

                            Button(mode == .signIn ? "Sign in" : "Create account") {
                                submit()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .frame(maxWidth: .infinity)
                            .controlSize(.large)

                            Button(mode == .signIn ? "Create an account" : "I already have an account") {
                                withAnimation { mode = (mode == .signIn ? .signUp : .signIn) }
                                error = nil
                            }
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(20)
                        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20))
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Stogie")
                .font(.system(size: 44, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
            Text("Cigars, shared.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(label, text: text)
            .textInputAutocapitalization(.never)
            .keyboardType(keyboard)
            .padding(14)
            .background(.white.opacity(0.08), in: .rect(cornerRadius: 12))
            .foregroundStyle(.white)
    }

    private func secureField(_ label: String, text: Binding<String>) -> some View {
        SecureField(label, text: text)
            .padding(14)
            .background(.white.opacity(0.08), in: .rect(cornerRadius: 12))
            .foregroundStyle(.white)
    }

    private func submit() {
        if mode == .signUp {
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            guard age >= 21 else {
                error = "You must be 21 or older to use Stogie."
                return
            }
            guard !username.isEmpty, !displayName.isEmpty else {
                error = "Username and display name are required."
                return
            }
        }
        guard !email.isEmpty, !password.isEmpty else {
            error = "Email and password are required."
            return
        }

        // TODO: hook up Supabase auth. For the scaffold we sign in with a stub user.
        let user = AppUser(
            id: UUID(),
            username: username.isEmpty ? email.components(separatedBy: "@").first ?? "user" : username,
            displayName: displayName.isEmpty ? "You" : displayName,
            bio: "",
            avatarURL: nil,
            dateOfBirth: dob,
            accountType: accountType,
            isVerified: accountType == .business ? false : false
        )
        session.signIn(as: user)
    }
}

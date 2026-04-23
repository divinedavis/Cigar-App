import SwiftUI

// MARK: - Routing

enum AuthRoute: Hashable {
    case email
    case ageGate(method: String, identifier: String, displayName: String)
}

// MARK: - Root

struct AuthView: View {
    @EnvironmentObject var session: SessionStore
    @State private var path: [AuthRoute] = []
    @State private var country: PhoneCountry = .us
    @State private var phone: String = ""
    @State private var showAppleSoon = false
    @State private var showFacebookSoon = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(
                    colors: [.black, Color(red: 0.18, green: 0.10, blue: 0.04)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        phoneCard
                        disclaimer
                        continueButton
                        orDivider
                        secondaryMethods
                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                }
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .email:
                    EmailAuthView(path: $path)
                case .ageGate(let method, let identifier, let displayName):
                    AgeGateView(method: method, identifier: identifier, displayName: displayName)
                }
            }
            .alert("Apple sign-in coming soon",
                   isPresented: $showAppleSoon) {
                Button("OK") {}
            }
            .alert("Facebook sign-in coming soon",
                   isPresented: $showFacebookSoon) {
                Button("OK") {}
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Pieces

    private var header: some View {
        ZStack {
            Text("Log in or sign up")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                Spacer()
                Button { } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                        .background(.white.opacity(0.08), in: .circle)
                }
                .opacity(0)
                .accessibilityHidden(true)
            }
        }
        .padding(.bottom, 4)
    }

    private var phoneCard: some View {
        VStack(spacing: 0) {
            Menu {
                ForEach(PhoneCountry.list) { c in
                    Button("\(c.name) (+\(c.code))") { country = c }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Country/Region")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(country.name) (+\(country.code))")
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }

            Divider().background(.white.opacity(0.12))

            TextField("", text: $phone, prompt:
                Text("Phone number").foregroundStyle(.white.opacity(0.55))
            )
            .keyboardType(.phonePad)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
        }
        .background(.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var disclaimer: some View {
        Text("We'll call or text to confirm your number. Standard message and data rates apply.")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.65))
    }

    private var continueButton: some View {
        Button {
            let trimmed = phone.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            path.append(.ageGate(
                method: "phone",
                identifier: "+\(country.code)\(trimmed)",
                displayName: ""
            ))
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(Color.orange, in: .rect(cornerRadius: 12))
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(.white.opacity(0.18)).frame(height: 1)
            Text("or")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
            Rectangle().fill(.white.opacity(0.18)).frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private var secondaryMethods: some View {
        VStack(spacing: 12) {
            Button { path.append(.email) } label: {
                ContinueWithRow(icon: "envelope", title: "Continue with email")
            }
            Button { showAppleSoon = true } label: {
                ContinueWithRow(icon: "applelogo", title: "Continue with Apple")
            }
            Button { showFacebookSoon = true } label: {
                ContinueWithRow(icon: "f.circle.fill",
                                title: "Continue with Facebook",
                                iconColor: Color(red: 0.23, green: 0.35, blue: 0.60))
            }
        }
    }
}

// MARK: - Secondary method row

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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Phone country

struct PhoneCountry: Identifiable, Hashable {
    let id: String
    let name: String
    let code: Int

    static let us  = PhoneCountry(id: "us",  name: "United States",       code: 1)
    static let ca  = PhoneCountry(id: "ca",  name: "Canada",              code: 1)
    static let uk  = PhoneCountry(id: "uk",  name: "United Kingdom",      code: 44)
    static let mx  = PhoneCountry(id: "mx",  name: "Mexico",              code: 52)
    static let dor = PhoneCountry(id: "do",  name: "Dominican Republic",  code: 1)
    static let cub = PhoneCountry(id: "cu",  name: "Cuba",                code: 53)
    static let nic = PhoneCountry(id: "ni",  name: "Nicaragua",           code: 505)
    static let hon = PhoneCountry(id: "hn",  name: "Honduras",            code: 504)

    static let list: [PhoneCountry] = [.us, .ca, .uk, .mx, .dor, .cub, .nic, .hon]
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

                    StogieField("Email", text: $email, keyboard: .emailAddress)
                    StogieSecureField("Password", text: $password)

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
                        Text("Stogie is for adults 21 and over.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    StogieField("Display name", text: $name)

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
            error = "You must be 21 or older to use Stogie."
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
            username: username.isEmpty ? "stogie_user" : username,
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

struct StogieField: View {
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

struct StogieSecureField: View {
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

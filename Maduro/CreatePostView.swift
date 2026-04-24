import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    @StateObject private var location = LocationManager()

    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedData: Data?
    @State private var caption: String = ""
    @State private var selectedCigar: Cigar?
    @State private var selectedStore: CigarStore?
    @State private var showingCigarPicker = false
    @State private var showingStorePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Media") {
                    PhotosPicker(selection: $pickedItem, matching: .any(of: [.images, .videos])) {
                        if pickedData != nil {
                            Label("Media selected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Choose photo or video", systemImage: "photo.on.rectangle.angled")
                        }
                    }
                    .onChange(of: pickedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                pickedData = data
                            }
                        }
                    }
                }

                Section("Caption") {
                    TextField("Say something about this smoke…", text: $caption, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Tag your cigar") {
                    Button {
                        showingCigarPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text(selectedCigar?.displayName ?? "Pick a cigar")
                                .foregroundStyle(selectedCigar == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Location") {
                    if location.authorizationStatus == .notDetermined {
                        Button("Enable location to auto-detect your cigar lounge") {
                            location.requestAuthorization()
                        }
                    } else if location.authorizationStatus == .denied || location.authorizationStatus == .restricted {
                        Text("Location denied — tag your store manually below.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }

                    if location.isSearching {
                        HStack { ProgressView(); Text("Looking for cigar lounges nearby…") }
                    }

                    if !location.nearbyStores.isEmpty && selectedStore == nil {
                        ForEach(location.nearbyStores.prefix(3)) { store in
                            Button {
                                selectedStore = store
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(store.name).foregroundStyle(.primary)
                                    Text(store.address).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Button {
                        showingStorePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(.orange)
                            Text(selectedStore?.name ?? "Tag a different store")
                                .foregroundStyle(selectedStore == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Post") { post() }
                        .disabled(pickedData == nil)
                }
            }
            .sheet(isPresented: $showingCigarPicker) {
                CigarPickerView(selection: $selectedCigar)
            }
            .sheet(isPresented: $showingStorePicker) {
                StorePickerView(selection: $selectedStore, nearby: location.nearbyStores)
            }
            .task {
                if location.authorizationStatus == .authorizedWhenInUse
                    || location.authorizationStatus == .authorizedAlways {
                    await location.refreshNearbyCigarStores()
                }
            }
        }
    }

    private func post() {
        // TODO: upload media to Supabase Storage, insert Post row, attach cigarID + storeID.
        dismiss()
    }
}

struct CigarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Cigar?
    @State private var query: String = ""

    var filtered: [Cigar] {
        guard !query.isEmpty else { return CigarCatalog.all }
        return CigarCatalog.all.filter {
            $0.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { cigar in
                Button {
                    selection = cigar
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(cigar.brand).font(.caption).foregroundStyle(.secondary)
                        Text(cigar.line).font(.body)
                        if let vitola = cigar.vitola {
                            Text(vitola).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search cigars")
            .navigationTitle("Cigars")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StorePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: CigarStore?
    let nearby: [CigarStore]

    var body: some View {
        NavigationStack {
            List {
                if !nearby.isEmpty {
                    Section("Nearby cigar lounges") {
                        ForEach(nearby) { store in
                            Button { selection = store; dismiss() } label: {
                                VStack(alignment: .leading) {
                                    Text(store.name)
                                    Text(store.address).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Text("No cigar lounges found near you.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Tag a store")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

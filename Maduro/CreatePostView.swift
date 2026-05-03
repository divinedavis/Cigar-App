import SwiftUI
import PhotosUI
import AVFoundation
import Supabase

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    @StateObject private var location = LocationManager()

    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedData: Data?
    @State private var pickedKind: Post.MediaKind?
    @State private var pickedFileExtension: String = "jpg"
    @State private var pickedContentType: String = "image/jpeg"
    @State private var caption: String = ""
    @State private var selectedCigar: Cigar?
    @State private var selectedStore: CigarStore?
    @State private var showingCigarPicker = false
    @State private var showingStorePicker = false
    @State private var mediaError: String?
    @State private var isUploading = false
    @State private var uploadError: String?

    private static let maxVideoSeconds: Double = 60

    var body: some View {
        NavigationStack {
            Form {
                Section("Media") {
                    PhotosPicker(selection: $pickedItem, matching: .any(of: [.images, .videos])) {
                        if pickedData != nil, let kind = pickedKind {
                            Label(kind == .video ? "Video selected" : "Photo selected",
                                  systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Choose photo or video (videos < 60s)",
                                  systemImage: "photo.on.rectangle.angled")
                        }
                    }
                    .onChange(of: pickedItem) { _, newItem in
                        Task { await loadPicked(newItem) }
                    }
                    if let mediaError {
                        Text(mediaError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("Caption") {
                    TextField("Say something about this smoke…", text: $caption, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let uploadError {
                    Section {
                        Text(uploadError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
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
                    if isUploading {
                        ProgressView()
                    } else {
                        Button("Post") { Task { await post() } }
                            .disabled(pickedData == nil || pickedKind == nil)
                    }
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

    private func loadPicked(_ item: PhotosPickerItem?) async {
        mediaError = nil
        pickedData = nil
        pickedKind = nil
        guard let item else { return }

        let supportedTypes = item.supportedContentTypes
        let isVideo = supportedTypes.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) })

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            mediaError = "Couldn't read that file. Try another."
            return
        }

        if isVideo {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("maduro-pick-\(UUID().uuidString).mov")
            do {
                try data.write(to: tempURL)
            } catch {
                mediaError = "Couldn't read that video. Try another."
                return
            }
            defer { try? FileManager.default.removeItem(at: tempURL) }

            let asset = AVURLAsset(url: tempURL)
            let durationSeconds: Double
            do {
                let duration = try await asset.load(.duration)
                durationSeconds = CMTimeGetSeconds(duration)
            } catch {
                mediaError = "Couldn't read that video's duration. Try another."
                return
            }
            guard durationSeconds.isFinite, durationSeconds > 0 else {
                mediaError = "That video looks empty. Try another."
                return
            }
            if durationSeconds > Self.maxVideoSeconds {
                let secs = Int(durationSeconds.rounded())
                mediaError = "Videos must be under 60s — that one is \(secs)s. Trim it and try again."
                return
            }

            pickedData = data
            pickedKind = .video
            pickedFileExtension = "mov"
            pickedContentType = "video/quicktime"
        } else {
            pickedData = data
            pickedKind = .photo
            pickedFileExtension = "jpg"
            pickedContentType = "image/jpeg"
        }
    }

    private func post() async {
        guard let data = pickedData,
              let kind = pickedKind,
              let user = session.currentUser else { return }
        isUploading = true
        uploadError = nil
        defer { isUploading = false }

        let postID = UUID()
        let path = "\(user.id.uuidString.lowercased())/\(postID.uuidString.lowercased()).\(pickedFileExtension)"
        let bucket = supabase.storage.from("posts")

        do {
            _ = try await bucket.upload(
                path,
                data: data,
                options: FileOptions(contentType: pickedContentType, upsert: false)
            )
            let publicURL = try bucket.getPublicURL(path: path)

            let row = NewPostRow(
                id: postID,
                author_id: user.id,
                media_url: publicURL.absoluteString,
                media_kind: kind == .video ? "video" : "photo",
                caption: caption,
                cigar_id: selectedCigar?.id,
                store_id: selectedStore?.id
            )
            try await supabase.from("posts").insert(row).execute()
            dismiss()
        } catch {
            uploadError = "Upload failed: \(error.localizedDescription)"
        }
    }
}

private struct NewPostRow: Encodable {
    let id: UUID
    let author_id: UUID
    let media_url: String
    let media_kind: String
    let caption: String
    let cigar_id: UUID?
    let store_id: UUID?
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

import SwiftUI

struct MessagesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var threads: [MessageThread] = MessageThread.seed()

    var body: some View {
        NavigationStack {
            List(threads) { thread in
                HStack(spacing: 12) {
                    Circle()
                        .fill(.brown.gradient)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(thread.username.prefix(1)).uppercased())
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("@\(thread.username)").font(.subheadline.bold())
                            if thread.unread {
                                Circle().fill(.orange).frame(width: 8, height: 8)
                            }
                            Spacer()
                            Text(thread.timeAgo)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(thread.lastMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

struct MessageThread: Identifiable {
    let id = UUID()
    let username: String
    let lastMessage: String
    let timeAgo: String
    let unread: Bool

    static func seed() -> [MessageThread] {
        [
            .init(username: "padron_pete", lastMessage: "where'd you grab that 1964?", timeAgo: "2h", unread: true),
            .init(username: "humidor_hannah", lastMessage: "lounge night Saturday?", timeAgo: "5h", unread: true),
            .init(username: "ash_axel", lastMessage: "the Lagavulin pairing changed my life", timeAgo: "1d", unread: false),
            .init(username: "brooklyn_bryant", lastMessage: "swung by your spot, killer humidor", timeAgo: "2d", unread: false),
            .init(username: "nicaragua_nadia", lastMessage: "🔥🔥🔥", timeAgo: "3d", unread: false)
        ]
    }
}

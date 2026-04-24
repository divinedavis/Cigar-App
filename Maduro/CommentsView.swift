import SwiftUI

/// Comments sheet for a Post or AdCreative.
///
/// Backed by stub data for now — wire to Supabase once auth is live.
struct CommentsView: View {
    let title: String
    let initialCount: Int

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""
    @State private var comments: [StubComment] = StubComment.seed()

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            List(comments) { comment in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(.brown.gradient)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(comment.username.prefix(1)).uppercased())
                                .font(.caption).bold().foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("@\(comment.username)").font(.subheadline).bold()
                            Text(comment.timeAgo)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(comment.body).font(.subheadline)
                        HStack(spacing: 14) {
                            Label("\(comment.reactions)", systemImage: "flame")
                                .font(.caption2).foregroundStyle(.secondary)
                            Button("Reply") {}
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)

            Divider()

            composer
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// Three-column header so the title sits in the true horizontal
    /// center even with a single trailing button. The leading and
    /// trailing slots have equal width.
    private var header: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 60, height: 1)
            Spacer()
            Text("\(comments.count) comments")
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Button("Done") { dismiss() }
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Add a comment…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.gray.opacity(0.15), in: .rect(cornerRadius: 18))
                .frame(maxWidth: .infinity)
            Button {
                send()
            } label: {
                Image(systemName: "paperplane.fill")
                    .padding(8)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func send() {
        let body = draft.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return }
        // TODO: insert into Supabase comments table.
        comments.insert(
            StubComment(id: UUID(), username: "you", body: body, timeAgo: "now", reactions: 0),
            at: 0
        )
        draft = ""
    }
}

struct StubComment: Identifiable {
    let id: UUID
    let username: String
    let body: String
    let timeAgo: String
    let reactions: Int

    static func seed() -> [StubComment] {
        [
            .init(id: UUID(), username: "padron_pete", body: "1964 Anniversary is the GOAT.", timeAgo: "2h", reactions: 24),
            .init(id: UUID(), username: "humidor_hannah", body: "Where'd you grab that one?", timeAgo: "1h", reactions: 8),
            .init(id: UUID(), username: "ash_axel", body: "Pairs perfect with a Lagavulin 16.", timeAgo: "45m", reactions: 17),
            .init(id: UUID(), username: "brooklyn_bryant", body: "I need to make it to your lounge.", timeAgo: "30m", reactions: 3),
            .init(id: UUID(), username: "nicaragua_nadia", body: "That ash hold tho 🔥", timeAgo: "12m", reactions: 41)
        ]
    }
}

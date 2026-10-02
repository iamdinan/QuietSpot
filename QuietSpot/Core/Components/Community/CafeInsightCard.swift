import SwiftUI

struct CafeInsightCard: View {
    let insight: CafeInsight
    let cafe: CafeSnapshot
    let profile: UserProfile
    let onToggleLike: () -> Void
    var isLikeEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: cafe.id) {
                HStack(spacing: 12) {
                    CafeThumbnail(cafe: cafe, size: 56)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(cafe.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(cafe.area)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.primary.opacity(0.035))
            .accessibilityHint("Opens café details")

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ProfileAvatar(photoData: insight.authorID == profile.id ? profile.photoData : insight.authorPhotoData, size: 28)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            authorName
                            Text("·").foregroundStyle(.secondary).accessibilityHidden(true)
                            timestamp
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            authorName
                            timestamp
                        }
                    }
                }
                .accessibilityElement(children: .combine)

                Text(insight.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            Button(action: onToggleLike) {
                HStack(spacing: 8) {
                    Label(insight.isLiked ? "Liked" : "Like", systemImage: insight.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    Text(insight.likeCount, format: .number)
                        .monospacedDigit()
                }
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(!isLikeEnabled)
            .tint(insight.isLiked ? AppColor.accent : Color.secondary)
            .accessibilityLabel(insight.isLiked ? "Unlike insight" : "Like insight")
            .accessibilityValue("\(insight.likeCount) \(insight.likeCount == 1 ? "like" : "likes")")
            .accessibilityHint(insight.isLiked ? "Removes your like" : "Adds your like")
            .accessibilityAddTraits(insight.isLiked ? [.isSelected] : [])
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var authorName: some View {
        Text(insight.authorID == profile.id ? profile.displayName : insight.authorName)
            .font(.caption.weight(.semibold))
    }

    private var timestamp: some View {
        Text(insight.createdAt, format: .relative(presentation: .named))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

import FirebaseFirestore
import Foundation
import Observation

@MainActor
@Observable
final class CommunityViewModel {
    private(set) var insights: [CafeInsight] = []
    private(set) var isLoading = false
    private(set) var loadingError: String?
    var actionError: String?
    private(set) var savingLikeIDs: Set<String> = []
    private(set) var loadedLikeIDs: Set<String> = []
    @ObservationIgnored private var userID: String?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private let service = CommunityService()
    @ObservationIgnored private let users = UserDataService()
    @ObservationIgnored private var postsListener: ListenerRegistration?
    @ObservationIgnored private var likeListeners: [String: ListenerRegistration] = [:]
    @ObservationIgnored private var authorListeners: [String: ListenerRegistration] = [:]
    @ObservationIgnored private var profiles: [String: UserProfile] = [:]
    @ObservationIgnored private var likedPostIDs: Set<String> = []

    deinit {
        postsListener?.remove()
        for listener in likeListeners.values { listener.remove() }
        for listener in authorListeners.values { listener.remove() }
    }

    func start(userID: String) {
        postsListener?.remove()
        for listener in likeListeners.values { listener.remove() }
        for listener in authorListeners.values { listener.remove() }
        likeListeners.removeAll()
        authorListeners.removeAll()
        profiles.removeAll()
        likedPostIDs.removeAll()
        loadedLikeIDs.removeAll()
        savingLikeIDs.removeAll()
        if self.userID != userID { insights = [] }
        self.userID = userID
        generation = UUID()
        let generation = generation
        isLoading = true
        loadingError = nil
        postsListener = service.observePosts { [weak self] result in
            guard let self, self.generation == generation else { return }
            self.isLoading = false
            switch result {
            case .success(let posts):
                self.loadingError = nil
                self.insights = posts.map { post in
                    var post = post
                    post.isLiked = self.likedPostIDs.contains(post.id)
                    if let profile = self.profiles[post.authorID] {
                        post.authorName = profile.displayName
                        post.authorPhotoData = profile.photoData
                    }
                    return post
                }
                self.observeRelatedData(userID: userID, generation: generation)
            case .failure(let error):
                self.loadingError = "Couldn’t load community posts. \(error.localizedDescription)"
            }
        }
    }

    func retry() {
        if let userID { start(userID: userID) }
    }

    func share(cafeID: String, text: String) async throws {
        guard let userID else { throw CocoaError(.userCancelled) }
        try await service.share(cafeID: cafeID, text: text, userID: userID)
    }

    func toggleLike(_ insight: CafeInsight) async {
        guard let userID, loadedLikeIDs.contains(insight.id), !savingLikeIDs.contains(insight.id) else { return }
        let generation = generation
        savingLikeIDs.insert(insight.id)
        defer { if self.generation == generation { savingLikeIDs.remove(insight.id) } }
        do {
            try await service.setLiked(postID: insight.id, userID: userID, liked: !insight.isLiked)
        } catch {
            guard self.generation == generation else { return }
            actionError = "Couldn’t update your like. \(error.localizedDescription)"
        }
    }

    private func observeRelatedData(userID: String, generation: UUID) {
        let postIDs = Set(insights.map(\.id))
        let authorIDs = Set(insights.map(\.authorID))
        for id in Array(likeListeners.keys) where !postIDs.contains(id) {
            likeListeners.removeValue(forKey: id)?.remove()
            loadedLikeIDs.remove(id)
            likedPostIDs.remove(id)
        }
        for id in Array(authorListeners.keys) where !authorIDs.contains(id) {
            authorListeners.removeValue(forKey: id)?.remove()
            profiles[id] = nil
        }
        for postID in postIDs where likeListeners[postID] == nil {
            likeListeners[postID] = service.observeLike(postID: postID, userID: userID) { [weak self] result in
                guard let self, self.generation == generation else { return }
                switch result {
                case .success(let liked):
                    self.loadedLikeIDs.insert(postID)
                    if liked { self.likedPostIDs.insert(postID) } else { self.likedPostIDs.remove(postID) }
                    if let index = self.insights.firstIndex(where: { $0.id == postID }) {
                        self.insights[index].isLiked = liked
                    }
                case .failure(let error):
                    self.loadedLikeIDs.remove(postID)
                    self.actionError = "Couldn’t load your likes. \(error.localizedDescription)"
                }
            }
        }
        for authorID in authorIDs where authorListeners[authorID] == nil {
            authorListeners[authorID] = users.observeProfile(userID: authorID) { [weak self] result in
                guard let self, self.generation == generation else { return }
                switch result {
                case .success(let profile):
                    self.profiles[authorID] = profile
                    for index in self.insights.indices where self.insights[index].authorID == authorID {
                        self.insights[index].authorName = profile.displayName
                        self.insights[index].authorPhotoData = profile.photoData
                    }
                case .failure(let error):
                    self.actionError = "Couldn’t load a post’s author. \(error.localizedDescription)"
                }
            }
        }
    }
}

import Foundation

protocol NewsAggregatorServiceProtocol {
    func fetchAggregatedNews(category: NewsCategory?, useLocationBased: Bool) async throws -> [EnhancedArticle]
}

protocol NewsAPIServiceProtocol {
    func fetchTopHeadlines(category: NewsCategory?, page: Int, pageSize: Int) async throws -> [Article]
    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> [Article]
}

protocol NewsCacheProtocol: Actor {
    func get(forKey key: String) -> [Article]?
    func set(articles: [Article], forKey key: String)
    func clear(forKey key: String)
    func clear(forCategory category: NewsCategory)
}

protocol BookmarkServiceProtocol: AnyObject {
    var bookmarks: [Article] { get }
    func addBookmark(_ article: Article)
    func removeBookmark(_ article: Article)
    func isBookmarked(_ article: Article) -> Bool
}

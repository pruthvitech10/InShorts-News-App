import Foundation

protocol NewsAggregatorServiceProtocol {
    func fetchAggregatedNews(category: NewsCategory?, useLocationBased: Bool) async throws -> [Article]
}

protocol NewsAPIServiceProtocol {
    func fetchTopHeadlines(category: NewsCategory?, page: Int, pageSize: Int) async throws -> [Article]
    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> [Article]
}

protocol BookmarkServiceProtocol: AnyObject {
    var bookmarks: [Article] { get }
    func addBookmark(_ article: Article)
    func removeBookmark(_ article: Article)
    func isBookmarked(_ article: Article) -> Bool
}

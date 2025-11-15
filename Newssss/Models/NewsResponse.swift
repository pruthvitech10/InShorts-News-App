//
//  NewsResponse.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation


// MARK: - News API Response
struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [Article]
}

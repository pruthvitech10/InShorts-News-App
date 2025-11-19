/**
 * ========================================
 * SHUFFLED NEWS ENDPOINT
 * ========================================
 * 
 * Returns shuffled articles so each user sees different order
 * Even users sitting next to each other get different news!
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface Article {
  title: string;
  url: string;
  summary: string;
  image: string | null;
  published_at: string;
  source: string; // Publisher name
}

interface CategoryJSON {
  category: string;
  updated_at: string;
  articles: Article[];
}

/**
 * Fisher-Yates shuffle algorithm
 * Randomizes array in-place for true randomness
 */
function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array]; // Create copy to avoid mutating original
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

/**
 * Get shuffled articles for a category
 * Each request returns a different random order
 * 
 * URL: https://[region]-[project].cloudfunctions.net/getShuffledNews?category=politics
 */
export const getShuffledNews = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    // Enable CORS
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      // Get category from query parameter
      const category = req.query.category as string || "general";
      
      console.log(`📱 User requested shuffled ${category} news`);

      // Validate category
      const validCategories = [
        "general", "politics", "sports", "technology", 
        "entertainment", "business", "world", "crime", 
        "automotive", "lifestyle"
      ];

      if (!validCategories.includes(category)) {
        res.status(400).json({
          error: "Invalid category",
          validCategories: validCategories,
        });
        return;
      }

      // Read articles from Firebase Storage
      const bucket = admin.storage().bucket();
      const file = bucket.file(`news/news_${category}.json`);

      const [exists] = await file.exists();
      if (!exists) {
        res.status(404).json({
          error: `No articles found for category: ${category}`,
        });
        return;
      }

      // Download and parse JSON
      const [data] = await file.download();
      const categoryData: CategoryJSON = JSON.parse(data.toString());

      // Shuffle articles - EVERY USER GETS DIFFERENT ORDER!
      const shuffledArticles = shuffleArray(categoryData.articles);

      console.log(`✅ Shuffled ${shuffledArticles.length} articles for ${category}`);

      // Return shuffled data
      res.status(200).json({
        category: categoryData.category,
        updated_at: categoryData.updated_at,
        articles: shuffledArticles,
        total: shuffledArticles.length,
        shuffled: true,
        timestamp: new Date().toISOString(),
      });

    } catch (error) {
      console.error("❌ Shuffle endpoint error:", error);
      res.status(500).json({
        error: "Internal server error",
        message: error instanceof Error ? error.message : String(error),
      });
    }
  });

/**
 * Get shuffled articles with pagination
 * For better performance with 800 articles
 * 
 * URL: https://[region]-[project].cloudfunctions.net/getShuffledNewsPaginated?category=politics&page=1&limit=50
 */
export const getShuffledNewsPaginated = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    // Enable CORS
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    try {
      // Get parameters
      const category = req.query.category as string || "general";
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 50;
      
      console.log(`📱 User requested shuffled ${category} news (page ${page}, limit ${limit})`);

      // Validate category
      const validCategories = [
        "general", "politics", "sports", "technology", 
        "entertainment", "business", "world", "crime", 
        "automotive", "lifestyle"
      ];

      if (!validCategories.includes(category)) {
        res.status(400).json({
          error: "Invalid category",
          validCategories: validCategories,
        });
        return;
      }

      // Validate pagination
      if (page < 1 || limit < 1 || limit > 800) {
        res.status(400).json({
          error: "Invalid pagination parameters",
          message: "page must be >= 1, limit must be 1-800",
        });
        return;
      }

      // Read articles from Firebase Storage
      const bucket = admin.storage().bucket();
      const file = bucket.file(`news/news_${category}.json`);

      const [exists] = await file.exists();
      if (!exists) {
        res.status(404).json({
          error: `No articles found for category: ${category}`,
        });
        return;
      }

      // Download and parse JSON
      const [data] = await file.download();
      const categoryData: CategoryJSON = JSON.parse(data.toString());

      // Shuffle articles - EVERY USER GETS DIFFERENT ORDER!
      const shuffledArticles = shuffleArray(categoryData.articles);

      // Paginate
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedArticles = shuffledArticles.slice(startIndex, endIndex);

      const totalPages = Math.ceil(shuffledArticles.length / limit);

      console.log(`✅ Shuffled ${shuffledArticles.length} articles, returning page ${page}/${totalPages}`);

      // Return paginated shuffled data
      res.status(200).json({
        category: categoryData.category,
        updated_at: categoryData.updated_at,
        articles: paginatedArticles,
        pagination: {
          page: page,
          limit: limit,
          total_articles: shuffledArticles.length,
          total_pages: totalPages,
          has_next: page < totalPages,
          has_prev: page > 1,
        },
        shuffled: true,
        timestamp: new Date().toISOString(),
      });

    } catch (error) {
      console.error("❌ Shuffle endpoint error:", error);
      res.status(500).json({
        error: "Internal server error",
        message: error instanceof Error ? error.message : String(error),
      });
    }
  });

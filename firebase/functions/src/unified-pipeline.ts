/**
 * ========================================
 * UNIFIED NEWS PIPELINE - ALL IN ONE
 * ========================================
 * 
 * Complete production-ready pipeline that runs every 10 minutes
 * 
 * Features:
 * 1. Fetches articles from 27 RSS sources
 * 2. Extracts full article text
 * 3. Generates 30-40 word summaries
 * 4. Deduplicates by URL
 * 5. Keeps last 24 hours only
 * 6. Categorizes articles (9 categories)
 * 7. Generates JSON per category
 * 8. Uploads to Firebase Storage
 * 9. Verifies with getMetadata()
 * 10. Logs everything clearly
 */

import * as admin from "firebase-admin";
import axios from "axios";
import {XMLParser} from "fast-xml-parser";
import * as cheerio from "cheerio";

// ==================== CONFIGURATION ====================

// RETENTION_HOURS is DISABLED - keeping ALL articles for maximum content
// const RETENTION_HOURS = 168; // 7 days (24 hours was too restrictive)

// RSS Sources by category - EXPANDED FOR RICHER CONTENT
const RSS_SOURCES: Record<string, Array<{url: string; name: string}>> = {
  politics: [
    {url: "https://www.ansa.it/sito/notizie/politica/politica_rss.xml", name: "ANSA Politics"},
    {url: "https://www.repubblica.it/rss/politica/rss2.0.xml", name: "La Repubblica Politics"},
    {url: "https://xml2.corriereobjects.it/rss/politica.xml", name: "Corriere Politica"},
    {url: "https://www.lastampa.it/rss/politica", name: "La Stampa Politics"},
    {url: "https://www.ilsole24ore.com/rss/italia.xml", name: "Il Sole 24 Ore Italia"},
    {url: "https://www.agi.it/politica/rss", name: "AGI Politics"},
    {url: "https://www.adnkronos.com/rss/politica.xml", name: "Adnkronos Politics"},
    {url: "https://www.rainews.it/rss/politica.xml", name: "RaiNews Politics"},
    {url: "https://tg24.sky.it/politica/rss", name: "Sky TG24 Politics"},
    {url: "https://www.fanpage.it/politica/feed/", name: "Fanpage Politics"},
  ],
  sports: [
    {url: "https://www.gazzetta.it/rss/calcio.xml", name: "Gazzetta Sport"},
    {url: "https://www.corrieredellosport.it/rss/home.xml", name: "Corriere Sport"},
    {url: "https://www.ansa.it/sito/notizie/sport/sport_rss.xml", name: "ANSA Sport"},
    {url: "https://www.tuttosport.com/rss/", name: "Tuttosport"},
    {url: "https://www.calciomercato.com/rss/", name: "Calciomercato"},
    {url: "https://sport.sky.it/rss/homepage.xml", name: "Sky Sport"},
    {url: "https://www.sportmediaset.mediaset.it/rss/homepage.xml", name: "Sport Mediaset"},
    {url: "https://www.rainews.it/rss/sport.xml", name: "RaiNews Sport"},
    {url: "https://tg24.sky.it/sport/rss", name: "Sky TG24 Sport"},
    {url: "https://www.fanpage.it/sport/feed/", name: "Fanpage Sport"},
  ],
  technology: [
    {url: "https://www.ansa.it/sito/notizie/tecnologia/tecnologia_rss.xml", name: "ANSA Tech"},
    {url: "https://www.hwupgrade.it/rss/news.xml", name: "HWUpgrade"},
    {url: "https://www.tomshw.it/feed", name: "Tom's Hardware"},
   
    {url: "https://www.punto-informatico.it/feed/", name: "Punto Informatico"},
    {url: "https://www.agi.it/innovazione/rss", name: "AGI Tech"},
    {url: "https://www.rainews.it/rss/tecnologia.xml", name: "RaiNews Tech"},
  ],
  entertainment: [
    {url: "https://www.ansa.it/sito/notizie/cultura/cultura_rss.xml", name: "ANSA Culture"},
    {url: "https://www.repubblica.it/rss/spettacoli/rss2.0.xml", name: "La Repubblica Entertainment"},
    {url: "https://www.cinematographe.it/feed/", name: "Cinematographe"},
    {url: "https://www.comingsoon.it/rss/cinema.rss", name: "Coming Soon Cinema"},
    {url: "https://www.agi.it/cultura/rss", name: "AGI Culture"},
    {url: "https://www.fanpage.it/spettacolo/feed/", name: "Fanpage Entertainment"},
  ],
  business: [
    {url: "https://www.ilsole24ore.com/rss/economia.xml", name: "Il Sole 24 Ore"},
    {url: "https://www.ansa.it/sito/notizie/economia/economia_rss.xml", name: "ANSA Business"},
    {url: "https://www.repubblica.it/rss/economia/rss2.0.xml", name: "La Repubblica Economy"},
    {url: "https://www.corriere.it/rss/economia.xml", name: "Corriere Economia"},
    {url: "https://www.agi.it/economia/rss", name: "AGI Business"},
    {url: "https://www.adnkronos.com/rss/economia.xml", name: "Adnkronos Business"},
    {url: "https://tg24.sky.it/economia/rss", name: "Sky TG24 Business"},
  ],
  world: [
    {url: "https://www.ansa.it/sito/notizie/mondo/mondo_rss.xml", name: "ANSA World"},
    {url: "https://www.repubblica.it/rss/esteri/rss2.0.xml", name: "La Repubblica World"},
    {url: "https://www.corriere.it/rss/esteri.xml", name: "Corriere Esteri"},
    {url: "https://www.ilpost.it/feed/", name: "Il Post International"},
    {url: "https://www.lastampa.it/rss/esteri", name: "La Stampa World"},
    {url: "https://www.ilfattoquotidiano.it/feed/", name: "Il Fatto World"},
    {url: "https://www.agi.it/estero/rss", name: "AGI World"},
    {url: "https://www.adnkronos.com/rss/esteri.xml", name: "Adnkronos World"},
    {url: "https://www.rainews.it/rss/mondo.xml", name: "RaiNews World"},
    {url: "https://tg24.sky.it/mondo/rss", name: "Sky TG24 World"},
  ],
  crime: [
    {url: "https://www.ansa.it/sito/notizie/cronaca/cronaca_rss.xml", name: "ANSA Crime"},
    {url: "https://www.repubblica.it/rss/cronaca/rss2.0.xml", name: "La Repubblica Crime"},
    {url: "https://www.corriere.it/rss/cronache.xml", name: "Corriere Cronache"},
    {url: "https://www.agi.it/cronaca/rss", name: "AGI Crime"},
    {url: "https://www.adnkronos.com/rss/cronaca.xml", name: "Adnkronos Crime"},
    {url: "https://www.fanpage.it/cronaca/feed/", name: "Fanpage Crime"},
    {url: "https://www.rainews.it/rss/cronaca.xml", name: "RaiNews Crime"},
  ],
  automotive: [
    {url: "https://www.quattroruote.it/rss/news.xml", name: "Quattroruote"},
    {url: "https://www.autoblog.it/feed/", name: "Autoblog"},
    {url: "https://www.omniauto.it/feed/", name: "OmniAuto"},
    {url: "https://www.alvolante.it/rss", name: "Al Volante"},
    {url: "https://www.automoto.it/feed", name: "AutoMoto"},
    {url: "https://www.auto.it/rss/news", name: "Auto.it"},
    {url: "https://motori.corriere.it/rss/home.xml", name: "Corriere Motori"},
  ],
  lifestyle: [
    {url: "https://www.lacucinaitaliana.it/rss", name: "La Cucina Italiana"},
    {url: "https://www.dissapore.com/feed/", name: "Dissapore"},
    {url: "https://www.donnamoderna.com/rss/", name: "Donna Moderna"},
    {url: "https://www.elle.com/it/rss/", name: "Elle Italia"},
    {url: "https://www.grazia.it/rss/", name: "Grazia"},
    {url: "https://www.marieclaire.com/it/rss/", name: "Marie Claire Italia"},
    {url: "https://www.vanityfair.it/feed", name: "Vanity Fair Italia"},
    {url: "https://www.vogue.it/feed", name: "Vogue Italia"},
    {url: "https://www.gamberorosso.it/feed/", name: "Gambero Rosso"},
  ],
};

// ==================== TYPES ====================

interface Article {
  title: string;
  url: string;
  summary: string;
  image: string | null;
  published_at: string;
}

interface CategoryJSON {
  category: string;
  updated_at: string;
  articles: Article[];
}

interface PipelineResult {
  category: string;
  success: boolean;
  total_articles: number;
  new_articles: number;
  removed_articles: number;
  local_path: string;
  firebase_url: string;
  verified: boolean;
  error?: string;
}

// ==================== LOGGER ====================

class Logger {
  private category: string;

  constructor(category: string) {
    this.category = category;
  }

  step(stepNum: number, message: string) {
    console.log(`[${this.category}] 📍 STEP ${stepNum}: ${message}`);
  }

  info(message: string) {
    console.log(`[${this.category}] ℹ️  ${message}`);
  }

  success(message: string) {
    console.log(`[${this.category}] ✅ ${message}`);
  }

  error(message: string, error?: any) {
    console.error(`[${this.category}] ❌ ${message}`);
    if (error) {
      console.error(`[${this.category}]    ${error.message || error}`);
    }
  }
}

// ==================== STEP 1: FETCH ARTICLES ====================

async function fetchArticlesFromRSS(url: string, sourceName: string, logger: Logger): Promise<Article[]> {
  try {
    logger.info(`Fetching from ${sourceName}...`);

    const response = await axios.get(url, {
      timeout: 10000,
      headers: {"User-Agent": "Mozilla/5.0 (compatible; NewsAggregator/1.0)"},
    });

    const parser = new XMLParser({
      ignoreAttributes: false,
      attributeNamePrefix: "@_",
    });

    const result = parser.parse(response.data);
    const items = result.rss?.channel?.item || result.feed?.entry || [];
    const itemsArray = Array.isArray(items) ? items : [items];

    const articles: Article[] = [];

    // NO LIMIT - fetch all articles from RSS feed
    for (const item of itemsArray) {
      const title = item.title || "";
      const articleUrl = item.link?.["@_href"] || item.link || item.guid || "";
      const publishedAt = item.pubDate || item.published || item.updated || new Date().toISOString();

      // Extract image from RSS - try multiple fields
      let image = null;
      
      // Try media:content
      if (item["media:content"]?.["@_url"]) {
        image = item["media:content"]["@_url"];
      } 
      // Try enclosure
      else if (item.enclosure?.["@_url"]) {
        image = item.enclosure["@_url"];
      } 
      // Try media:thumbnail
      else if (item["media:thumbnail"]?.["@_url"]) {
        image = item["media:thumbnail"]["@_url"];
      }
      // Try description for img tags
      else if (item.description) {
        const imgMatch = item.description.match(/<img[^>]+src="([^">]+)"/);
        if (imgMatch) {
          image = imgMatch[1];
        }
      }
      // Try content:encoded for img tags
      else if (item["content:encoded"]) {
        const imgMatch = item["content:encoded"].match(/<img[^>]+src="([^">]+)"/);
        if (imgMatch) {
          image = imgMatch[1];
        }
      }

      if (title && articleUrl) {
        articles.push({
          title: title.trim(),
          url: articleUrl.trim(),
          summary: "", // Will be filled in step 2
          image: image,
          published_at: publishedAt,
        });
      }
    }

    logger.info(`Fetched ${articles.length} articles from ${sourceName}`);
    return articles;
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    logger.error(`Failed to fetch from ${sourceName}: ${errorMsg}`);
    console.error(`❌ RSS Fetch Error [${sourceName}]:`, {
      url: url.substring(0, 100),
      error: errorMsg,
      timestamp: new Date().toISOString()
    });
    return [];
  }
}

// ==================== STEP 2: EXTRACT FULL TEXT & GENERATE SUMMARY ====================

async function extractArticleText(url: string, retries = 2): Promise<{text: string; image: string | null}> {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const response = await axios.get(url, {
        timeout: 8000,
        headers: {"User-Agent": "Mozilla/5.0 (compatible; NewsAggregator/1.0)"},
      });

      const $ = cheerio.load(response.data);

      // Extract image from article page
      let image: string | null = null;
      const imageSelectors = [
        "meta[property='og:image']",
        "meta[name='twitter:image']",
        "article img",
        ".article-image img",
        ".featured-image img",
        "img[class*='article']",
        "img[class*='hero']"
      ];
      
      for (const selector of imageSelectors) {
        const element = $(selector).first();
        if (element.length > 0) {
          image = element.attr("content") || element.attr("src") || null;
          if (image) break;
        }
      }

      // Remove unwanted elements
      $("script, style, nav, header, footer, aside, .ad, .advertisement, .comments").remove();

      // Try common article selectors
      const selectors = ["article", ".article-content", ".article-body", ".post-content", ".entry-content", "main", ".content"];

      let content = "";
      for (const selector of selectors) {
        const element = $(selector);
        if (element.length > 0) {
          content = element.text();
          break;
        }
      }

      // Fallback: get all paragraphs
      if (!content || content.length < 100) {
        content = $("p").text();
      }

      // Clean and limit
      const cleanContent = content.replace(/\s+/g, " ").trim().substring(0, 3000);
      
      if (cleanContent.length > 50) {
        return {text: cleanContent, image};
      }
      
      // Content too short, log warning
      console.warn(`⚠️  Short content (${cleanContent.length} chars) from ${url.substring(0, 50)}...`);
      return {text: cleanContent, image};
      
    } catch (error) {
      if (attempt < retries) {
        console.warn(`⚠️  Retry ${attempt + 1}/${retries} for ${url.substring(0, 50)}...`);
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1s before retry
      } else {
        console.error(`❌ Failed to extract from ${url.substring(0, 50)}...: ${error instanceof Error ? error.message : 'Unknown error'}`);
        return {text: "", image: null};
      }
    }
  }
  return {text: "", image: null};
}

/**
 * Generate smart 30-40 word summary
 * This is the modular summarization function
 */
function generateSmartSummary(fullText: string): string {
  if (!fullText || fullText.length < 50) {
    return "No summary available.";
  }

  // Split into sentences
  const sentences = fullText
    .split(/[.!?]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 20);

  if (sentences.length === 0) {
    return "No summary available.";
  }

  // Score sentences
  const scored = sentences.map((sentence, index) => {
    const words = sentence.split(/\s+/).filter((w) => w.length > 0);
    
    // Position score (earlier = more important)
    const positionScore = 1.0 - (index / sentences.length);
    
    // Length score (prefer 10-30 words)
    let lengthScore = 0.5;
    if (words.length >= 10 && words.length <= 30) {
      lengthScore = 1.0;
    } else if (words.length < 10) {
      lengthScore = words.length / 10;
    } else {
      lengthScore = 30 / words.length;
    }
    
    // Keyword score
    const importantWords = ["announced", "revealed", "confirmed", "new", "first", "major", "government", "team", "victory"];
    const keywordScore = importantWords.filter((kw) => sentence.toLowerCase().includes(kw)).length * 0.1;
    
    const totalScore = (positionScore * 0.4) + (lengthScore * 0.4) + (keywordScore * 0.2);
    
    return {sentence, score: totalScore, words: words.length};
  });

  // Sort by score
  scored.sort((a, b) => b.score - a.score);

  // Build summary (30-40 words)
  let summary = "";
  let wordCount = 0;

  for (const item of scored) {
    if (wordCount + item.words <= 40) {
      if (summary) summary += " ";
      summary += item.sentence + ".";
      wordCount += item.words;
      
      if (wordCount >= 30) break;
    }
  }

  // Ensure we have something
  if (!summary) {
    summary = scored[0].sentence + ".";
    wordCount = scored[0].words;
  }

  // Validate and enforce 30-40 word range
  const finalWords = summary.split(/\s+/).filter(w => w.length > 0);
  
  if (finalWords.length < 30) {
    // Too short - add more sentences
    for (const item of scored.slice(1)) {
      if (wordCount + item.words <= 40) {
        summary += " " + item.sentence + ".";
        wordCount += item.words;
        if (wordCount >= 30) break;
      }
    }
  } else if (finalWords.length > 40) {
    // Too long - trim to 40 words
    summary = finalWords.slice(0, 40).join(" ") + "...";
  }

  return summary.trim();
}

async function processArticleWithSummary(article: Article, logger: Logger): Promise<Article> {
  // Extract full text and image
  const {text: fullText, image: pageImage} = await extractArticleText(article.url);
  
  // Generate summary
  const summary = generateSmartSummary(fullText || article.title);
  
  // Use page image if RSS didn't provide one
  const finalImage = article.image || pageImage;
  
  return {
    ...article,
    summary: summary,
    image: finalImage,
  };
}

// ==================== STEP 3: DEDUPLICATE BY URL ====================

function deduplicateArticles(articles: Article[]): Article[] {
  const seen = new Set<string>();
  return articles.filter((article) => {
    if (seen.has(article.url)) {
      return false;
    }
    seen.add(article.url);
    return true;
  });
}

// ==================== STEP 4: TIME FILTER (DISABLED) ====================
// Time filter is DISABLED to maximize article count (200-400+ per category)

/*
function filterLast24Hours(articles: Article[]): Article[] {
  const cutoff = Date.now() - (RETENTION_HOURS * 60 * 60 * 1000);
  
  return articles.filter((article) => {
    try {
      const time = new Date(article.published_at).getTime();
      return time > cutoff;
    } catch {
      return false;
    }
  });
}
*/

// ==================== STEP 5: CATEGORIZE (Already done by source) ====================
// Articles are already categorized by RSS source

// ==================== STEP 6: GENERATE CATEGORY JSON ====================

function generateCategoryJSON(category: string, articles: Article[]): CategoryJSON {
  // Sort by date (newest first)
  const sorted = articles.sort((a, b) => {
    try {
      return new Date(b.published_at).getTime() - new Date(a.published_at).getTime();
    } catch {
      return 0;
    }
  });

  return {
    category: category,
    updated_at: new Date().toISOString(),
    articles: sorted,
  };
}

// ==================== STEP 7 & 8: UPLOAD TO FIREBASE (MERGE WITH EXISTING) ====================

async function uploadToFirebase(category: string, data: CategoryJSON, logger: Logger): Promise<string> {
  try {
    // Use default bucket (firebasestorage.app)
    const bucket = admin.storage().bucket();
    const fileName = `news/news_${category}.json`;
    const file = bucket.file(fileName);

    // CRITICAL: Download existing articles first and merge
    let existingArticles: Article[] = [];
    try {
      const [exists] = await file.exists();
      if (exists) {
        const [fileData] = await file.download();
        const existingJSON: CategoryJSON = JSON.parse(fileData.toString());
        existingArticles = existingJSON.articles || [];
        logger.info(`Found ${existingArticles.length} existing articles`);
      }
    } catch (err) {
      logger.info(`No existing file, starting fresh`);
    }

    // Merge new + existing articles
    const allArticles = [...data.articles, ...existingArticles];
    
    // Deduplicate by URL (keep newer version)
    const seenUrls = new Map<string, Article>();
    for (const article of allArticles) {
      const existing = seenUrls.get(article.url);
      if (!existing || new Date(article.published_at) > new Date(existing.published_at)) {
        seenUrls.set(article.url, article);
      }
    }
    const mergedArticles = Array.from(seenUrls.values());
    
    // Sort by date (newest first)
    mergedArticles.sort((a, b) => 
      new Date(b.published_at).getTime() - new Date(a.published_at).getTime()
    );
    
    // Cap at 700 articles per category (6,300 total across 9 categories)
    const MAX_ARTICLES = 700;
    let finalArticles = mergedArticles;
    let removedOld = 0;
    
    if (mergedArticles.length > MAX_ARTICLES) {
      removedOld = mergedArticles.length - MAX_ARTICLES;
      finalArticles = mergedArticles.slice(0, MAX_ARTICLES); // Keep newest 700
      logger.info(`⚠️ Exceeded ${MAX_ARTICLES} limit - removed ${removedOld} oldest articles`);
    }
    
    logger.success(`Merged: ${data.articles.length} new + ${existingArticles.length} existing = ${finalArticles.length} total (removed ${removedOld} old)`);

    // Create merged JSON
    const mergedData: CategoryJSON = {
      category: category,
      updated_at: new Date().toISOString(),
      articles: finalArticles,
    };

    // Upload merged result
    await file.save(JSON.stringify(mergedData, null, 2), {
      contentType: "application/json",
      metadata: {
        cacheControl: "public, max-age=300",
      },
    });

    // Make public
    await file.makePublic();

    const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(fileName)}?alt=media`;
    
    logger.success(`Uploaded to Firebase: ${fileName} with ${finalArticles.length} total articles`);
    return publicUrl;
  } catch (error) {
    logger.error(`Failed to upload to Firebase`, error);
    throw error;
  }
}

// ==================== STEP 10: VERIFY WITH getMetadata() ====================

async function verifyUpload(category: string, expectedCount: number, logger: Logger): Promise<boolean> {
  try {
    // Use default bucket (firebasestorage.app)
    const bucket = admin.storage().bucket();
    const file = bucket.file(`news/news_${category}.json`);

    // Get metadata
    const [metadata] = await file.getMetadata();
    
    logger.info(`Metadata - Size: ${metadata.size} bytes, Updated: ${metadata.updated}`);

    // Verify content
    const [data] = await file.download();
    const parsed: CategoryJSON = JSON.parse(data.toString());

    if (parsed.articles.length !== expectedCount) {
      logger.error(`Verification failed: Expected ${expectedCount}, got ${parsed.articles.length}`);
      return false;
    }

    logger.success(`Verification passed: ${parsed.articles.length} articles`);
    return true;
  } catch (error) {
    logger.error(`Verification failed`, error);
    return false;
  }
}

// ==================== STEP 11 & 12: MAIN PIPELINE (MODULAR) ====================

async function processCategoryPipeline(
  category: string,
  sources: Array<{url: string; name: string}>,
  globalSeenUrls?: Set<string>
): Promise<PipelineResult> {
  const logger = new Logger(category);

  console.log("\n" + "=".repeat(60));
  console.log(`🔄 PROCESSING CATEGORY: ${category.toUpperCase()}`);
  console.log("=".repeat(60));

  try {
    // STEP 1: Fetch articles from RSS
    logger.step(1, "Fetching articles from RSS");
    const allArticles: Article[] = [];
    for (const source of sources) {
      const articles = await fetchArticlesFromRSS(source.url, source.name, logger);
      allArticles.push(...articles);
    }
    logger.success(`Fetched ${allArticles.length} total articles`);

    // STEP 2: Deduplicate by URL (BEFORE summary generation to save time)
    logger.step(2, "Deduplicating by URL");
    let unique = deduplicateArticles(allArticles);
    const duplicatesRemoved = allArticles.length - unique.length;
    
    // Global deduplication across categories
    if (globalSeenUrls) {
      const beforeGlobal = unique.length;
      unique = unique.filter(article => {
        if (globalSeenUrls.has(article.url)) {
          return false;
        }
        globalSeenUrls.add(article.url);
        return true;
      });
      const globalDuplicates = beforeGlobal - unique.length;
      if (globalDuplicates > 0) {
        logger.info(`Removed ${globalDuplicates} cross-category duplicates`);
      }
    }
    
    logger.success(`Removed ${duplicatesRemoved} duplicates`);

    // STEP 3: NO TIME FILTER - Keep ALL articles to maximize content
    logger.step(3, "Keeping all articles (no time filter)");
    const recent = unique; // Keep ALL articles, don't filter by time
    const oldRemoved = 0; // Not filtering by time, so 0 removed
    logger.success(`Keeping all ${recent.length} articles`);

    // STEP 4: Extract text and generate summaries (ONLY for unique, recent articles)
    logger.step(4, "Extracting text and generating summaries");
    
    // Process in batches of 5 to avoid overwhelming servers
    const BATCH_SIZE = 5;
    const articlesWithSummaries: Article[] = [];
    
    for (let i = 0; i < recent.length; i += BATCH_SIZE) {
      const batch = recent.slice(i, i + BATCH_SIZE);
      const batchResults = await Promise.all(
        batch.map(article => processArticleWithSummary(article, logger))
      );
      articlesWithSummaries.push(...batchResults);
      
      // Log progress
      logger.info(`Processed ${Math.min(i + BATCH_SIZE, recent.length)}/${recent.length} articles`);
    }
    
    logger.success(`Generated ${articlesWithSummaries.length} summaries`);

    // Clear intermediate arrays to free memory
    allArticles.length = 0;
    unique.length = 0;
    recent.length = 0;

    // STEP 5: Generate JSON
    logger.step(5, "Generating category JSON");
    const categoryJSON = generateCategoryJSON(category, articlesWithSummaries);
    logger.success(`Generated JSON with ${categoryJSON.articles.length} articles`);

    // STEP 6: Upload to Firebase (replaces old)
    logger.step(6, "Uploading to Firebase Storage");
    const firebaseUrl = await uploadToFirebase(category, categoryJSON, logger);

    // STEP 7: Verify with getMetadata()
    logger.step(7, "Verifying upload with getMetadata()");
    const verified = await verifyUpload(category, categoryJSON.articles.length, logger);

    // STEP 8: Log success
    console.log("\n" + "-".repeat(60));
    console.log(`✅ SUCCESS: ${category.toUpperCase()}`);
    console.log(`   Total articles: ${categoryJSON.articles.length}`);
    console.log(`   New articles: ${allArticles.length}`);
    console.log(`   Removed: ${oldRemoved}`);
    console.log(`   Firebase: ${firebaseUrl}`);
    console.log(`   Verified: ${verified ? "YES" : "NO"}`);
    console.log("-".repeat(60));

    return {
      category: category,
      success: true,
      total_articles: categoryJSON.articles.length,
      new_articles: allArticles.length,
      removed_articles: oldRemoved,
      local_path: "",
      firebase_url: firebaseUrl,
      verified: verified,
    };
  } catch (error) {
    logger.error("Pipeline failed", error);

    console.log("\n" + "-".repeat(60));
    console.log(`❌ FAILED: ${category.toUpperCase()}`);
    console.log(`   Error: ${error instanceof Error ? error.message : String(error)}`);
    console.log("-".repeat(60));

    return {
      category: category,
      success: false,
      total_articles: 0,
      new_articles: 0,
      removed_articles: 0,
      local_path: "",
      firebase_url: "",
      verified: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

// ==================== RUN COMPLETE PIPELINE ====================

export async function runUnifiedPipeline(): Promise<PipelineResult[]> {
  console.log("\n" + "=".repeat(60));
  console.log("🚀 UNIFIED NEWS PIPELINE STARTED");
  console.log(`⏰ Time: ${new Date().toISOString()}`);
  console.log(`🔄 Processing ${Object.keys(RSS_SOURCES).length} categories`);
  console.log("=".repeat(60));

  const startTime = Date.now();

  // Global deduplication tracker to prevent same article in multiple categories
  const globalSeenUrls = new Set<string>();

  // Process all categories sequentially
  const results: PipelineResult[] = [];
  for (const [category, sources] of Object.entries(RSS_SOURCES)) {
    const result = await processCategoryPipeline(category, sources, globalSeenUrls);
    results.push(result);
  }

  // Final summary
  const successful = results.filter((r) => r.success).length;
  const failed = results.filter((r) => !r.success).length;
  const totalArticles = results.reduce((sum, r) => sum + r.total_articles, 0);
  const duration = ((Date.now() - startTime) / 1000).toFixed(2);

  console.log("\n" + "=".repeat(60));
  console.log("✅ UNIFIED PIPELINE COMPLETE");
  console.log(`⏱️  Duration: ${duration}s`);
  console.log(`📊 Successful: ${successful}/${results.length}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📰 Total articles: ${totalArticles}`);
  console.log("=".repeat(60));

  // List all files
  console.log("\n📂 Uploaded files:");
  results.forEach((r) => {
    if (r.success) {
      console.log(`   ✅ ${r.category}.json (${r.total_articles} articles)`);
      console.log(`      Firebase: ${r.firebase_url}`);
      console.log(`      Verified: ${r.verified ? "YES" : "NO"}`);
    } else {
      console.log(`   ❌ ${r.category}.json - FAILED: ${r.error}`);
    }
  });

  return results;
}

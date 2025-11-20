import * as admin from "firebase-admin";
import axios from "axios";
import {XMLParser} from "fast-xml-parser";
import * as cheerio from "cheerio";

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
    {url: "https://www.ilpost.it/feed/", name: "Il Post"},
    {url: "https://www.ilfattoquotidiano.it/feed/", name: "Il Fatto Quotidiano"},
    {url: "https://www.huffingtonpost.it/rss/", name: "Huffington Post Italia"},
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
    {url: "https://www.repubblica.it/rss/sport/rss2.0.xml", name: "La Repubblica Sport"},
    {url: "https://www.eurosport.it/rss.xml", name: "Eurosport Italia"},
  ],
  technology: [
    {url: "https://www.ansa.it/sito/notizie/tecnologia/tecnologia_rss.xml", name: "ANSA Tech"},
    {url: "https://www.hwupgrade.it/rss/news.xml", name: "HWUpgrade"},
    {url: "https://www.tomshw.it/feed", name: "Tom's Hardware"},
    {url: "https://www.punto-informatico.it/feed/", name: "Punto Informatico"},
    {url: "https://www.agi.it/innovazione/rss", name: "AGI Tech"},
    {url: "https://www.rainews.it/rss/tecnologia.xml", name: "RaiNews Tech"},
    {url: "https://www.wired.it/feed/rss", name: "Wired Italia"},
    {url: "https://www.dday.it/rss", name: "DDay.it"},
  ],
  entertainment: [
    {url: "https://www.ansa.it/sito/notizie/cultura/cultura_rss.xml", name: "ANSA Culture"},
    {url: "https://www.repubblica.it/rss/spettacoli/rss2.0.xml", name: "La Repubblica Entertainment"},
    {url: "https://www.cinematographe.it/feed/", name: "Cinematographe"},
    {url: "https://www.comingsoon.it/rss/cinema.rss", name: "Coming Soon Cinema"},
    {url: "https://www.agi.it/cultura/rss", name: "AGI Culture"},
    {url: "https://www.fanpage.it/spettacolo/feed/", name: "Fanpage Entertainment"},
    {url: "https://www.mymovies.it/rss/", name: "MyMovies"},
    {url: "https://www.rockol.it/rss", name: "Rockol Music"},
  ],
  business: [
    {url: "https://www.ilsole24ore.com/rss/economia.xml", name: "Il Sole 24 Ore"},
    {url: "https://www.ansa.it/sito/notizie/economia/economia_rss.xml", name: "ANSA Business"},
    {url: "https://www.repubblica.it/rss/economia/rss2.0.xml", name: "La Repubblica Economy"},
    {url: "https://www.corriere.it/rss/economia.xml", name: "Corriere Economia"},
    {url: "https://www.agi.it/economia/rss", name: "AGI Business"},
    {url: "https://www.adnkronos.com/rss/economia.xml", name: "Adnkronos Business"},
    {url: "https://tg24.sky.it/economia/rss", name: "Sky TG24 Business"},
    {url: "https://www.milanofinanza.it/rss", name: "Milano Finanza"},
    {url: "https://www.startmag.it/feed/", name: "StartMag"},
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

interface Article {
  title: string;
  url: string;
  summary: string;
  image: string | null;
  published_at: string;
  source: string;
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

class Logger {
  private category: string;

  constructor(category: string) {
    this.category = category;
  }

  step(stepNum: number, message: string) {
    console.log(`[${this.category}] Step ${stepNum}: ${message}`);
  }

  info(message: string) {
    console.log(`[${this.category}] ${message}`);
  }

  success(message: string) {
    console.log(`[${this.category}] ${message}`);
  }

  error(message: string, error?: any) {
    console.error(`[${this.category}] ${message}`);
    if (error) {
      console.error(`[${this.category}] ${error.message || error}`);
    }
  }
}

function decodeHTMLEntities(text: string): string {
  if (!text) return text;
  
  return text
    .replace(/&#(\d+);/g, (match, dec) => String.fromCharCode(dec))
    .replace(/&#x([0-9a-fA-F]+);/g, (match, hex) => String.fromCharCode(parseInt(hex, 16)))
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&');
}

function cleanTextForReadability(text: string): string {
  if (!text) return text;
  
  return text
    .replace(/<[^>]*>/g, '')
    .replace(/https?:\/\/[^\s]+/g, '')
    .replace(/[\w.-]+@[\w.-]+\.\w+/g, '')
    .replace(/^[\[\(]\d+[\]\)]\s*/g, '')
    .replace(/\.{2,}/g, '.')
    .replace(/\s+/g, ' ')
    .replace(/\s+([.,!?;:])/g, '$1')
    .trim();
}

async function fetchArticlesFromRSS(url: string, sourceName: string, logger: Logger): Promise<Article[]> {
  try {
    logger.info(`Fetching from ${sourceName}...`);

    const response = await axios.get(url, {
      timeout: 10000,
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/rss+xml, application/xml, text/xml, */*",
        "Accept-Language": "it-IT,it;q=0.9,en;q=0.8",
      },
    });

    const parser = new XMLParser({
      ignoreAttributes: false,
      attributeNamePrefix: "@_",
    });

    const result = parser.parse(response.data);
    const items = result.rss?.channel?.item || result.feed?.entry || [];
    const itemsArray = Array.isArray(items) ? items : [items];

    const articles: Article[] = [];

    for (const item of itemsArray) {
      const title = item.title || "";
      const articleUrl = item.link?.["@_href"] || item.link || item.guid || "";
      const publishedAt = item.pubDate || item.published || item.updated || new Date().toISOString();

      let image = null;
      
      // Try multiple RSS image sources
      if (item["media:content"]?.["@_url"]) {
        image = item["media:content"]["@_url"];
      } else if (item.enclosure?.["@_url"]) {
        image = item.enclosure["@_url"];
      } else if (item["media:thumbnail"]?.["@_url"]) {
        image = item["media:thumbnail"]["@_url"];
      } else if (item.image) {
        // Some feeds have direct image field
        image = typeof item.image === 'string' ? item.image : item.image?.url || item.image?.["@_url"];
      } else if (item.thumbnail) {
        image = typeof item.thumbnail === 'string' ? item.thumbnail : item.thumbnail?.url || item.thumbnail?.["@_url"];
      } else if (item.description) {
        // Try to extract from description HTML
        const imgMatch = item.description.match(/<img[^>]+src=["']([^"'>]+)["']/);
        if (imgMatch) {
          image = imgMatch[1];
        }
      } else if (item["content:encoded"]) {
        // Try to extract from content:encoded HTML
        const imgMatch = item["content:encoded"].match(/<img[^>]+src=["']([^"'>]+)["']/);
        if (imgMatch) {
          image = imgMatch[1];
        }
      }
      
      // Clean up image URL (remove query params that might break loading)
      if (image && typeof image === 'string') {
        image = image.trim();
        // Ensure it's a valid URL
        if (!image.startsWith('http')) {
          image = null;
        }
      }

      if (title && articleUrl) {
        articles.push({
          title: cleanTextForReadability(decodeHTMLEntities(title.trim())),
          url: articleUrl.trim(),
          summary: "",
          image: image,
          published_at: publishedAt,
          source: sourceName
        });
      }
    }

    logger.info(`Fetched ${articles.length} articles from ${sourceName}`);
    return articles;
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    logger.error(`Failed to fetch from ${sourceName}: ${errorMsg}`);
    console.error(`RSS Fetch Error [${sourceName}]:`, {
      url: url.substring(0, 100),
      error: errorMsg,
      timestamp: new Date().toISOString()
    });
    return [];
  }
}

async function extractArticleText(url: string, retries = 2): Promise<{text: string; image: string | null}> {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const response = await axios.get(url, {
        timeout: 5000,
        headers: {
          "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Accept-Language": "it-IT,it;q=0.9,en;q=0.8",
        },
      });

      const $ = cheerio.load(response.data);

      let image: string | null = null;
      const imageSelectors = [
        "meta[property='og:image']",
        "meta[name='twitter:image']",
        "meta[property='og:image:secure_url']",
        "link[rel='image_src']",
        "article img",
        ".article-image img",
        ".featured-image img",
        ".wp-post-image",
        ".entry-content img",
        ".post-thumbnail img",
        "img[class*='article']",
        "img[class*='hero']",
        "img[class*='featured']",
        "img[class*='cover']",
        "figure img",
        ".main-image img",
        "#main-image"
      ];
      
      for (const selector of imageSelectors) {
        const element = $(selector).first();
        if (element.length > 0) {
          image = element.attr("content") || element.attr("src") || element.attr("data-src") || element.attr("href") || null;
          if (image) {
            // Clean and validate image URL
            image = image.trim();
            if (image.startsWith('//')) {
              image = 'https:' + image;
            } else if (image.startsWith('/')) {
              // Relative URL - skip for now
              image = null;
              continue;
            }
            if (image && image.startsWith('http')) {
              break;
            }
          }
        }
      }

      $("script, style, nav, header, footer, aside, .ad, .advertisement, .comments").remove();


      const selectors = ["article", ".article-content", ".article-body", ".post-content", ".entry-content", "main", ".content"];

      let content = "";
      for (const selector of selectors) {
        const element = $(selector);
        if (element.length > 0) {
          content = element.text();
          break;
        }
      }

      if (!content || content.length < 100) {
        content = $("p").text();
      }

      const cleanContent = content.replace(/\s+/g, " ").trim().substring(0, 3000);
      
      if (cleanContent.length > 50) {
        return {text: cleanContent, image};
      }
      
      console.warn(`Short content (${cleanContent.length} chars) from ${url.substring(0, 50)}...`);
      return {text: cleanContent, image};
      
    } catch (error) {
      // Skip retries for 403/401 errors (access denied)
      const isAuthError = error instanceof Error && 
        (error.message.includes('403') || error.message.includes('401') || error.message.includes('status code 403'));
      
      if (isAuthError) {
        console.warn(`Access denied for ${url.substring(0, 50)}... - skipping`);
        return {text: "", image: null};
      }
      
      if (attempt < retries) {
        console.warn(`Retry ${attempt + 1}/${retries} for ${url.substring(0, 50)}...`);
        await new Promise(resolve => setTimeout(resolve, 500)); // Reduced from 1000ms
      } else {
        console.error(`Failed to extract from ${url.substring(0, 50)}...: ${error instanceof Error ? error.message : 'Unknown error'}`);
        return {text: "", image: null};
      }
    }
  }
  return {text: "", image: null};
}

async function generateSmartSummary(fullText: string): Promise<string> {
  if (!fullText || fullText.length < 50) {
    return "No summary available.";
  }

  const decodedText = decodeHTMLEntities(fullText);
  
  try {
    const response = await axios.post('https://api-inference.huggingface.co/models/facebook/bart-large-cnn', {
      inputs: decodedText.substring(0, 1024),
      parameters: {
        max_length: 60,
        min_length: 30,
        do_sample: false
      }
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.HUGGINGFACE_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    if (response.data && response.data[0] && response.data[0].summary_text) {
      return cleanTextForReadability(response.data[0].summary_text);
    }
  } catch (error) {
    // Silent fallback
  }


  const sentences = decodedText
    .split(/[.!?]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 20);

  if (sentences.length === 0) {
    return "No summary available.";
  }

  const scored = sentences.map((sentence, index) => {
    const words = sentence.split(/\s+/).filter((w) => w.length > 0);
    
    const positionScore = 1.0 - (index / sentences.length);
    
    let lengthScore = 0.5;
    if (words.length >= 10 && words.length <= 30) {
      lengthScore = 1.0;
    } else if (words.length < 10) {
      lengthScore = words.length / 10;
    } else {
      lengthScore = 30 / words.length;
    }
    
    const importantWords = ["announced", "revealed", "confirmed", "new", "first", "major", "government", "team", "victory"];
    const keywordScore = importantWords.filter((kw) => sentence.toLowerCase().includes(kw)).length * 0.1;
    
    const totalScore = (positionScore * 0.4) + (lengthScore * 0.4) + (keywordScore * 0.2);
    
    return {sentence, score: totalScore, words: words.length};
  });

  scored.sort((a, b) => b.score - a.score);


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

  if (!summary) {
    summary = scored[0].sentence + ".";
    wordCount = scored[0].words;
  }

  const finalWords = summary.split(/\s+/).filter(w => w.length > 0);
  
  if (finalWords.length < 30) {
    for (const item of scored.slice(1)) {
      if (wordCount + item.words <= 40) {
        summary += " " + item.sentence + ".";
        wordCount += item.words;
        if (wordCount >= 30) break;
      }
    }
  } else if (finalWords.length > 40) {
    summary = finalWords.slice(0, 40).join(" ") + "...";
  }

  return cleanTextForReadability(summary.trim());
}

function getPublisherFavicon(url: string): string {
  try {
    const domain = new URL(url).hostname;
    return `https://www.google.com/s2/favicons?domain=${domain}&sz=256`;
  } catch {
    return "";
  }
}

async function processArticleWithSummary(article: Article, logger: Logger): Promise<Article> {
  const {text: fullText, image: pageImage} = await extractArticleText(article.url);
  
  const summary = await generateSmartSummary(fullText || article.title);
  
  let finalImage = article.image || pageImage || getPublisherFavicon(article.url);
  
  if (!finalImage || finalImage.trim() === "") {
    finalImage = `https://via.placeholder.com/800x450/4A90E2/FFFFFF?text=News`;
  }
  
  return {
    ...article,
    summary: summary,
    image: finalImage,
  };
}

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

function generateCategoryJSON(category: string, articles: Article[]): CategoryJSON {
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

async function uploadToFirebase(category: string, data: CategoryJSON, logger: Logger): Promise<string> {
  try {
    const bucket = admin.storage().bucket();
    const fileName = `news/news_${category}.json`;
    const file = bucket.file(fileName);


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

    const allArticles = [...data.articles, ...existingArticles];
    

    const seenUrls = new Map<string, Article>();
    for (const article of allArticles) {
      const existing = seenUrls.get(article.url);
      if (!existing || new Date(article.published_at) > new Date(existing.published_at)) {
        seenUrls.set(article.url, article);
      }
    }
    const mergedArticles = Array.from(seenUrls.values());
    
    // Filter articles to only include those from last 72 hours (3 days)
    const now = new Date().getTime();
    const seventyTwoHoursAgo = now - (72 * 60 * 60 * 1000);
    const recentArticles = mergedArticles.filter(article => {
      try {
        const publishedTime = new Date(article.published_at).getTime();
        return publishedTime >= seventyTwoHoursAgo;
      } catch {
        return false;
      }
    });
    
    recentArticles.sort((a, b) => 
      new Date(b.published_at).getTime() - new Date(a.published_at).getTime()
    );
    
    const MAX_ARTICLES = 350;
    let finalArticles = recentArticles;
    let removedOld = 0;
    
    if (recentArticles.length > MAX_ARTICLES) {
      removedOld = recentArticles.length - MAX_ARTICLES;
      finalArticles = recentArticles.slice(0, MAX_ARTICLES);
      logger.info(`Exceeded ${MAX_ARTICLES} limit - removed ${removedOld} oldest articles`);
    }
    
    logger.success(`Merged: ${data.articles.length} new + ${existingArticles.length} existing = ${finalArticles.length} total (removed ${removedOld} old)`);


    const mergedData: CategoryJSON = {
      category: category,
      updated_at: new Date().toISOString(),
      articles: finalArticles,
    };

    await file.save(JSON.stringify(mergedData, null, 2), {
      contentType: "application/json",
      metadata: {
        cacheControl: "public, max-age=300",
      },
    });

    await file.makePublic();

    const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(fileName)}?alt=media`;
    
    logger.success(`Uploaded to Firebase: ${fileName} with ${finalArticles.length} total articles`);
    return publicUrl;
  } catch (error) {
    logger.error(`Failed to upload to Firebase`, error);
    throw error;
  }
}

async function verifyUpload(category: string, expectedCount: number, logger: Logger): Promise<boolean> {
  try {
    const bucket = admin.storage().bucket();
    const file = bucket.file(`news/news_${category}.json`);

    const [metadata] = await file.getMetadata();
    
    logger.info(`Metadata - Size: ${metadata.size} bytes, Updated: ${metadata.updated}`);

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

async function processCategoryPipeline(
  category: string,
  sources: Array<{url: string; name: string}>,
  globalSeenUrls?: Set<string>
): Promise<PipelineResult> {
  const logger = new Logger(category);

  console.log("\n" + "=".repeat(60));
  console.log(`Processing category: ${category.toUpperCase()}`);
  console.log("=".repeat(60));

  try {
    logger.step(1, "Fetching articles from RSS");
    const allArticles: Article[] = [];
    for (const source of sources) {
      const articles = await fetchArticlesFromRSS(source.url, source.name, logger);
      allArticles.push(...articles);
    }
    logger.success(`Fetched ${allArticles.length} total articles`);

    logger.step(2, "Deduplicating by URL");
    let unique = deduplicateArticles(allArticles);
    const duplicatesRemoved = allArticles.length - unique.length;
    
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

    logger.step(3, "Keeping all articles (no time filter)");
    const recent = unique;
    const oldRemoved = 0;
    logger.success(`Keeping all ${recent.length} articles`);

    logger.step(4, "Extracting text and generating summaries");
    
    const BATCH_SIZE = 10;
    const articlesWithSummaries: Article[] = [];
    
    for (let i = 0; i < recent.length; i += BATCH_SIZE) {
      const batch = recent.slice(i, i + BATCH_SIZE);
      const batchResults = await Promise.all(
        batch.map(article => processArticleWithSummary(article, logger))
      );
      articlesWithSummaries.push(...batchResults);
      
      logger.info(`Processed ${Math.min(i + BATCH_SIZE, recent.length)}/${recent.length} articles`);
    }
    
    logger.success(`Generated ${articlesWithSummaries.length} summaries`);

    allArticles.length = 0;
    unique.length = 0;
    recent.length = 0;


    logger.step(5, "Generating category JSON");
    const categoryJSON = generateCategoryJSON(category, articlesWithSummaries);
    logger.success(`Generated JSON with ${categoryJSON.articles.length} articles`);

    logger.step(6, "Uploading to Firebase Storage");
    const firebaseUrl = await uploadToFirebase(category, categoryJSON, logger);

    logger.step(7, "Verifying upload with getMetadata()");
    const verified = await verifyUpload(category, categoryJSON.articles.length, logger);

    console.log("\n" + "-".repeat(60));
    console.log(`Success: ${category.toUpperCase()}`);
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
    console.log(`Failed: ${category.toUpperCase()}`);
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

export async function runUnifiedPipeline(): Promise<PipelineResult[]> {
  console.log("\n" + "=".repeat(60));
  console.log("Unified news pipeline started");
  console.log(`Time: ${new Date().toISOString()}`);
  console.log(`Processing ${Object.keys(RSS_SOURCES).length} categories`);
  console.log("=".repeat(60));

  const startTime = Date.now();

  const globalSeenUrls = new Set<string>();


  const results: PipelineResult[] = [];
  for (const [category, sources] of Object.entries(RSS_SOURCES)) {
    const result = await processCategoryPipeline(category, sources, globalSeenUrls);
    results.push(result);
  }

  console.log("\n" + "=".repeat(60));
  console.log("Creating 'general' category (all articles combined)");
  console.log("=".repeat(60));
  
  try {
    const generalLogger = new Logger("general");
    const bucket = admin.storage().bucket();
    
    const allCategoryArticles: Article[] = [];
    
    for (const [category, _] of Object.entries(RSS_SOURCES)) {
      try {
        const file = bucket.file(`news/news_${category}.json`);
        const [exists] = await file.exists();
        
        if (exists) {
          const [data] = await file.download();
          const categoryJSON: CategoryJSON = JSON.parse(data.toString());
          allCategoryArticles.push(...categoryJSON.articles);
          generalLogger.info(`Added ${categoryJSON.articles.length} articles from ${category}`);
        }
      } catch (err) {
        generalLogger.error(`Failed to load ${category}`, err);
      }
    }
    
    generalLogger.info(`Collected ${allCategoryArticles.length} total articles from all categories`);
    
    const seenUrls = new Map<string, Article>();
    for (const article of allCategoryArticles) {
      const existing = seenUrls.get(article.url);
      if (!existing || new Date(article.published_at) > new Date(existing.published_at)) {
        seenUrls.set(article.url, article);
      }
    }
    const uniqueArticles = Array.from(seenUrls.values());
    
    // Filter articles to only include those from last 72 hours (3 days)
    const now = new Date().getTime();
    const seventyTwoHoursAgo = now - (72 * 60 * 60 * 1000);
    const recentArticles = uniqueArticles.filter(article => {
      try {
        const publishedTime = new Date(article.published_at).getTime();
        return publishedTime >= seventyTwoHoursAgo;
      } catch {
        return false;
      }
    });
    
    recentArticles.sort((a, b) => 
      new Date(b.published_at).getTime() - new Date(a.published_at).getTime()
    );
    
    generalLogger.success(`Filtered to ${recentArticles.length} articles from last 72 hours (from ${uniqueArticles.length} total)`);
    
    const generalJSON: CategoryJSON = {
      category: "general",
      updated_at: new Date().toISOString(),
      articles: recentArticles.slice(0, 800),
    };
    
    const generalFile = bucket.file("news/news_general.json");
    await generalFile.save(JSON.stringify(generalJSON, null, 2), {
      contentType: "application/json",
      metadata: {
        cacheControl: "public, max-age=300",
      },
    });
    
    await generalFile.makePublic();
    
    const generalUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/news%2Fnews_general.json?alt=media`;
    
    generalLogger.success(`Uploaded general category with ${generalJSON.articles.length} articles`);
    
    results.push({
      category: "general",
      success: true,
      total_articles: generalJSON.articles.length,
      new_articles: generalJSON.articles.length,
      removed_articles: 0,
      local_path: "",
      firebase_url: generalUrl,
      verified: true,
    });
    
    console.log("General category created successfully");
  } catch (error) {
    console.error("Failed to create general category:", error);
    results.push({
      category: "general",
      success: false,
      total_articles: 0,
      new_articles: 0,
      removed_articles: 0,
      local_path: "",
      firebase_url: "",
      verified: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }

  const successful = results.filter((r) => r.success).length;
  const failed = results.filter((r) => !r.success).length;
  const totalArticles = results.reduce((sum, r) => sum + r.total_articles, 0);
  const duration = ((Date.now() - startTime) / 1000).toFixed(2);

  console.log("\n" + "=".repeat(60));
  console.log("Unified pipeline complete");
  console.log(`Duration: ${duration}s`);
  console.log(`Successful: ${successful}/${results.length}`);
  console.log(`Failed: ${failed}`);
  console.log(`Total articles: ${totalArticles}`);
  console.log("=".repeat(60));

  console.log("\nUploaded files:");
  results.forEach((r) => {
    if (r.success) {
      console.log(`   ${r.category}.json (${r.total_articles} articles)`);
      console.log(`      Firebase: ${r.firebase_url}`);
      console.log(`      Verified: ${r.verified ? "YES" : "NO"}`);
    } else {
      console.log(`   ${r.category}.json - FAILED: ${r.error}`);
    }
  });

  return results;
}

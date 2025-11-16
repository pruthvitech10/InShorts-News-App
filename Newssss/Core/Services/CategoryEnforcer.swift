//
//  CategoryEnforcer.swift
//  Newssss
//
//  STRICT CATEGORY ENFORCEMENT
//  Ensures articles ONLY appear in their correct category
//  NO cross-contamination allowed!
//

import Foundation

class CategoryEnforcer {
    static let shared = CategoryEnforcer()
    
    private init() {}
    
    /// Enforce strict category separation - remove duplicates and assign to ONLY ONE category
    func enforceStrictCategories(categories: [String: [Article]]) -> [String: [Article]] {
        Logger.debug("🔒 Enforcing STRICT category separation...", category: .network)
        
        var seenURLs = Set<String>()
        var cleanedCategories: [String: [Article]] = [:]
        
        // Priority order: Most specific to least specific
        let categoryPriority = [
            "politics",      // 1. Politics (most specific)
            "crime",         // 2. Crime (specific)
            "automotive",    // 3. Automotive (specific)
            "sports",        // 4. Sports (specific)
            "technology",    // 5. Technology (specific)
            "entertainment", // 6. Entertainment (specific)
            "business",      // 7. Business (can overlap)
            "world",         // 8. World (broad)
            "lifestyle",     // 9. Lifestyle (broad)
            "general"        // 10. General (catch-all)
        ]
        
        // Process categories in priority order
        for category in categoryPriority {
            guard let articles = categories[category] else { continue }
            
            var uniqueArticles: [Article] = []
            
            for article in articles {
                // Only add if not seen before
                if !seenURLs.contains(article.url) {
                    // Validate article belongs to this category
                    if validateArticleCategory(article: article, category: category) {
                        uniqueArticles.append(article)
                        seenURLs.insert(article.url)
                    }
                }
            }
            
            cleanedCategories[category] = uniqueArticles
            Logger.debug("✅ \(category): \(uniqueArticles.count) unique articles (removed \(articles.count - uniqueArticles.count) duplicates)", category: .network)
        }
        
        let totalBefore = categories.values.reduce(0) { $0 + $1.count }
        let totalAfter = cleanedCategories.values.reduce(0) { $0 + $1.count }
        Logger.debug("🔒 Category enforcement complete: \(totalBefore) → \(totalAfter) articles (removed \(totalBefore - totalAfter) duplicates)", category: .network)
        
        return cleanedCategories
    }
    
    /// Validate if article truly belongs to category using keyword matching
    private func validateArticleCategory(article: Article, category: String) -> Bool {
        let text = "\(article.title) \(article.description ?? "") \(article.content ?? "")".lowercased()
        
        switch category {
        case "politics":
            // 100+ Politics keywords (Italian + English)
            let keywords = [
                // Italian political terms
                "governo", "parlamento", "politica", "elezioni", "ministro", "premier", "senato", "camera", "deputati", "legge", "decreto", "presidente", "consiglio", "ministri", "voto", "referendum", "partito", "coalizione", "opposizione", "maggioranza", "costituzione", "repubblica", "stato", "regione", "comune", "sindaco", "assessore", "giunta", "consiglio comunale", "provincia", "prefetto", "quirinale", "palazzo chigi", "montecitorio", "madama", "commissione", "emendamento", "mozione", "fiducia", "crisi", "dimissioni", "nomina", "incarico", "deleghe", "sottosegretario", "capogruppo", "segretario", "leader", "candidato", "elettore", "scheda", "urne", "seggio", "scrutinio", "ballottaggio", "affluenza", "astensione", "bianco", "nullo", "preferenza", "lista", "simbolo", "programma", "alleanza", "accordo", "patto", "intesa", "trattativa", "negoziato", "vertice", "summit", "g7", "g20", "ue", "unione europea", "bruxelles", "strasburgo", "europarlamento", "commissione europea", "consiglio europeo", "nato", "onu", "diplomazia", "ambasciatore", "console", "trattato", "sanzioni", "embargo",
                // English political terms
                "politics", "government", "election", "minister", "parliament", "senate", "congress", "vote", "referendum", "party", "coalition", "opposition", "majority", "constitution", "republic", "state", "president", "prime minister", "cabinet", "legislation", "law", "decree", "bill", "amendment", "motion", "crisis", "resignation", "appointment", "delegation", "secretary", "leader", "candidate", "voter", "ballot", "polling", "campaign"
            ]
            return keywords.contains { text.contains($0) }
            
        case "sports":
            // 100+ Sports keywords (Italian + English)
            let keywords = [
                // Italian sports terms
                "calcio", "serie a", "serie b", "champions", "europa league", "coppa italia", "football", "sport", "partita", "gol", "goal", "allenatore", "squadra", "campionato", "giocatore", "calciatore", "portiere", "difensore", "centrocampista", "attaccante", "arbitro", "fallo", "rigore", "penalty", "cartellino", "rosso", "giallo", "fuorigioco", "corner", "tiro", "parata", "vittoria", "sconfitta", "pareggio", "classifica", "punti", "scudetto", "coppa", "trofeo", "finale", "semifinale", "quarti", "ottavi", "girone", "eliminatoria", "qualificazione", "juventus", "inter", "milan", "roma", "napoli", "lazio", "fiorentina", "atalanta", "torino", "bologna", "tennis", "formula 1", "f1", "motogp", "gp", "gran premio", "circuito", "pilota", "scuderia", "ferrari", "mercedes", "red bull", "pole position", "podio", "basket", "pallavolo", "volley", "rugby", "ciclismo", "giro d'italia", "tour", "tappa", "maglia rosa", "nuoto", "atletica", "olimpiadi", "mondiali", "europei", "medaglia", "oro", "argento", "bronzo", "record", "vittoria", "sconfitta",
                // English sports terms  
                "sports", "football", "soccer", "match", "game", "player", "team", "coach", "trainer", "championship", "league", "cup", "trophy", "win", "loss", "draw", "score", "goal", "penalty", "referee", "foul", "yellow card", "red card", "offside", "corner", "kick", "save", "victory", "defeat", "standings", "points", "final", "semifinal", "quarter", "round", "qualification", "tennis", "basketball", "volleyball", "rugby", "cycling", "swimming", "athletics", "olympics", "world cup", "medal", "gold", "silver", "bronze", "record"
            ]
            return keywords.contains { text.contains($0) }
            
        case "technology":
            // 100+ Technology keywords (Italian + English)
            let keywords = [
                // Italian tech terms
                "tecnologia", "tech", "smartphone", "cellulare", "telefono", "iphone", "android", "samsung", "apple", "google", "microsoft", "computer", "pc", "laptop", "tablet", "ipad", "software", "app", "applicazione", "programma", "sistema operativo", "windows", "macos", "linux", "ios", "digital", "digitale", "internet", "web", "online", "sito", "website", "browser", "chrome", "firefox", "safari", "social", "facebook", "instagram", "twitter", "tiktok", "youtube", "whatsapp", "telegram", "ai", "intelligenza artificiale", "machine learning", "algoritmo", "robot", "automazione", "cloud", "server", "database", "dati", "data", "big data", "cybersecurity", "sicurezza", "hacker", "virus", "malware", "antivirus", "password", "crittografia", "blockchain", "bitcoin", "criptovaluta", "crypto", "nft", "metaverso", "realtà virtuale", "vr", "ar", "realtà aumentata", "5g", "rete", "connessione", "wifi", "fibra", "banda larga", "streaming", "video", "gaming", "videogiochi", "console", "playstation", "xbox", "nintendo", "innovation", "innovazione", "startup", "silicon valley", "venture capital", "investimento", "tech company", "gigante tech",
                // English tech terms
                "technology", "tech", "smartphone", "mobile", "phone", "computer", "laptop", "tablet", "software", "hardware", "app", "application", "program", "operating system", "digital", "internet", "web", "online", "website", "browser", "social media", "artificial intelligence", "machine learning", "algorithm", "robot", "automation", "cloud", "server", "database", "data", "cybersecurity", "security", "hacker", "virus", "malware", "password", "encryption", "blockchain", "cryptocurrency", "bitcoin", "nft", "metaverse", "virtual reality", "augmented reality", "5g", "network", "wifi", "fiber", "broadband", "streaming", "gaming", "console", "innovation", "startup", "silicon", "venture", "investment"
            ]
            return keywords.contains { text.contains($0) }
            
        case "entertainment":
            // 100+ Entertainment keywords (Italian + English)
            let keywords = [
                // Italian entertainment terms
                "cinema", "film", "movie", "pellicola", "regista", "attore", "attrice", "protagonista", "cast", "produzione", "distribuzione", "box office", "incasso", "oscar", "festival", "mostra", "venezia", "cannes", "berlino", "premio", "nomination", "vincitore", "musica", "music", "canzone", "song", "album", "disco", "singolo", "artista", "cantante", "singer", "band", "gruppo", "concerto", "live", "tour", "tournée", "festival musicale", "sanremo", "eurovision", "spotify", "apple music", "streaming musicale", "spettacolo", "show", "teatro", "commedia", "dramma", "opera", "musical", "balletto", "danza", "tv", "televisione", "serie", "serie tv", "fiction", "programma", "trasmissione", "conduttore", "presentatore", "reality", "talent", "quiz", "talk show", "rai", "mediaset", "sky", "netflix", "amazon prime", "disney+", "streaming", "piattaforma", "episodio", "stagione", "season", "finale", "celebrity", "vip", "star", "divo", "diva", "gossip", "paparazzi", "red carpet", "premiere", "anteprima", "uscita", "release", "trailer", "teaser", "clip", "video", "youtube", "influencer", "tiktoker", "youtuber", "social",
                // English entertainment terms
                "entertainment", "cinema", "movie", "film", "director", "actor", "actress", "cast", "production", "box office", "oscar", "award", "festival", "music", "song", "album", "artist", "singer", "band", "concert", "tour", "show", "theater", "theatre", "comedy", "drama", "opera", "musical", "dance", "tv", "television", "series", "program", "host", "reality", "talent", "streaming", "netflix", "episode", "season", "celebrity", "star", "gossip", "premiere", "release", "trailer", "video", "influencer"
            ]
            return keywords.contains { text.contains($0) }
            
        case "business":
            // 100+ Business keywords (Italian + English)
            let keywords = [
                // Italian business terms
                "economia", "business", "azienda", "impresa", "società", "company", "corporation", "mercato", "market", "borsa", "stock", "azioni", "shares", "titoli", "quotazione", "listing", "indice", "ftse", "mib", "dow jones", "nasdaq", "s&p", "finanza", "finance", "investimenti", "investment", "investitore", "investor", "fondo", "fund", "hedge fund", "private equity", "venture capital", "startup", "unicorno", "unicorn", "ipo", "fusione", "merger", "acquisizione", "acquisition", "deal", "accordo", "contratto", "partnership", "alleanza", "joint venture", "bilancio", "fatturato", "revenue", "utile", "profit", "perdita", "loss", "trimestre", "quarter", "risultati", "earnings", "dividendo", "dividend", "ceo", "amministratore delegato", "presidente", "consiglio amministrazione", "cda", "board", "azionista", "shareholder", "stakeholder", "industria", "industry", "settore", "sector", "manifattura", "manufacturing", "produzione", "production", "export", "import", "commercio", "trade", "scambio", "exchange", "valuta", "currency", "euro", "dollaro", "sterlina", "yen", "cambio", "forex", "banca", "bank", "credito", "credit", "prestito", "loan", "mutuo", "mortgage", "interesse", "interest", "tasso", "rate", "inflazione", "inflation", "deflazione", "pil", "gdp", "crescita", "growth", "recessione", "recession", "crisi", "crisis",
                // English business terms
                "economy", "business", "company", "corporation", "market", "stock", "shares", "finance", "investment", "investor", "fund", "startup", "merger", "acquisition", "deal", "contract", "partnership", "revenue", "profit", "loss", "earnings", "dividend", "ceo", "president", "board", "shareholder", "industry", "sector", "manufacturing", "production", "export", "import", "trade", "exchange", "currency", "bank", "credit", "loan", "interest", "rate", "inflation", "gdp", "growth", "recession", "crisis"
            ]
            return keywords.contains { text.contains($0) }
            
        case "crime":
            // 100+ Crime keywords (Italian + English)
            let keywords = [
                // Italian crime terms
                "cronaca", "crimine", "crime", "reato", "delitto", "omicidio", "murder", "assassinio", "uccisione", "morte", "morto", "vittima", "victim", "cadavere", "corpo", "polizia", "police", "carabinieri", "guardia di finanza", "questura", "commissariato", "agente", "officer", "ispettore", "detective", "investigatore", "indagine", "investigation", "inchiesta", "inquiry", "arresto", "arrest", "fermo", "cattura", "capture", "latitante", "fugitive", "ricercato", "wanted", "mandato", "warrant", "perquisizione", "search", "sequestro", "seizure", "confisca", "processo", "trial", "tribunale", "court", "giudice", "judge", "pm", "procuratore", "prosecutor", "avvocato", "lawyer", "difesa", "defense", "accusa", "accusation", "imputato", "defendant", "testimone", "witness", "prova", "evidence", "perizia", "expertise", "sentenza", "sentence", "verdict", "condanna", "conviction", "assoluzione", "acquittal", "pena", "punishment", "carcere", "prison", "galera", "jail", "detenuto", "inmate", "ergastolo", "life sentence", "reclusione", "furto", "theft", "rapina", "robbery", "truffa", "fraud", "estorsione", "extortion", "sequestro persona", "kidnapping", "stupro", "rape", "violenza", "violence", "aggressione", "assault", "droga", "drug", "spaccio", "trafficking", "mafia", "camorra", "ndrangheta", "clan", "boss", "pentito", "collaboratore giustizia", "intercettazione", "wiretap", "blitz", "raid", "operazione", "operation",
                // English crime terms
                "crime", "murder", "homicide", "killing", "death", "victim", "body", "police", "officer", "detective", "investigation", "arrest", "capture", "fugitive", "warrant", "search", "seizure", "trial", "court", "judge", "prosecutor", "lawyer", "defense", "accusation", "defendant", "witness", "evidence", "sentence", "verdict", "conviction", "acquittal", "punishment", "prison", "jail", "inmate", "theft", "robbery", "fraud", "extortion", "kidnapping", "rape", "violence", "assault", "drug", "trafficking", "mafia", "gang", "operation"
            ]
            return keywords.contains { text.contains($0) }
            
        case "automotive":
            // 100+ Automotive keywords (Italian + English)
            let keywords = [
                // Italian automotive terms
                "auto", "automobile", "car", "macchina", "veicolo", "vehicle", "moto", "motocicletta", "motorcycle", "scooter", "motorino", "motore", "engine", "motor", "cilindrata", "cavalli", "hp", "potenza", "power", "velocità", "speed", "accelerazione", "acceleration", "freni", "brakes", "sospensioni", "suspension", "cambio", "gearbox", "trasmissione", "transmission", "trazione", "drive", "4x4", "suv", "berlina", "sedan", "station wagon", "coupé", "cabriolet", "convertible", "spider", "roadster", "crossover", "monovolume", "minivan", "pick-up", "truck", "furgone", "van", "ferrari", "lamborghini", "maserati", "alfa romeo", "fiat", "lancia", "abarth", "pagani", "ducati", "aprilia", "piaggio", "vespa", "bmw", "mercedes", "audi", "volkswagen", "porsche", "tesla", "toyota", "honda", "nissan", "mazda", "ford", "chevrolet", "gm", "peugeot", "renault", "citroën", "volvo", "jaguar", "land rover", "bentley", "rolls royce", "aston martin", "mclaren", "bugatti", "racing", "corsa", "gara", "race", "pista", "track", "circuito", "circuit", "pilota", "driver", "formula 1", "f1", "motogp", "rally", "endurance", "le mans", "monza", "imola", "mugello", "pole position", "podio", "podium", "vittoria", "win", "scuderia", "team", "box", "pit stop", "pneumatici", "tires", "gomme", "carburante", "fuel", "benzina", "diesel", "elettrico", "electric", "ibrido", "hybrid", "autonomia", "range", "ricarica", "charging", "batteria", "battery",
                // English automotive terms
                "automotive", "car", "vehicle", "motorcycle", "bike", "engine", "motor", "power", "speed", "acceleration", "brakes", "transmission", "drive", "suv", "sedan", "coupe", "convertible", "truck", "van", "racing", "race", "track", "circuit", "driver", "formula", "rally", "pole", "podium", "team", "pit", "tires", "fuel", "electric", "hybrid", "battery", "charging"
            ]
            return keywords.contains { text.contains($0) }
            
        case "world":
            // 100+ World keywords (Italian + English)
            let keywords = [
                // Italian world terms
                "mondo", "world", "internazionale", "international", "globale", "global", "mondiale", "estero", "foreign", "paese", "country", "nazione", "nation", "stato", "state", "continente", "continent", "europa", "europe", "asia", "africa", "america", "oceania", "usa", "stati uniti", "cina", "china", "russia", "india", "giappone", "japan", "brasile", "brazil", "canada", "messico", "mexico", "argentina", "australia", "francia", "france", "germania", "germany", "spagna", "spain", "regno unito", "uk", "inghilterra", "england", "scozia", "scotland", "irlanda", "ireland", "olanda", "netherlands", "belgio", "belgium", "svizzera", "switzerland", "austria", "portogallo", "portugal", "grecia", "greece", "turchia", "turkey", "egitto", "egypt", "sudafrica", "south africa", "nigeria", "kenya", "marocco", "morocco", "israele", "israel", "arabia saudita", "saudi arabia", "emirati", "uae", "dubai", "qatar", "iran", "iraq", "siria", "syria", "afghanistan", "pakistan", "corea", "korea", "vietnam", "thailandia", "thailand", "indonesia", "filippine", "philippines", "singapore", "malesia", "malaysia", "onu", "un", "nato", "ue", "unione europea", "european union", "g7", "g20", "brics", "asean", "fmi", "imf", "banca mondiale", "world bank", "wto", "unesco", "who", "oms",
                // English world terms
                "world", "international", "global", "foreign", "country", "nation", "state", "continent", "europe", "asia", "africa", "america", "oceania", "usa", "china", "russia", "india", "japan", "brazil", "canada", "mexico", "france", "germany", "spain", "uk", "australia", "turkey", "egypt", "israel", "saudi", "korea", "vietnam", "thailand", "singapore", "un", "nato", "eu", "european", "union"
            ]
            return keywords.contains { text.contains($0) }
            
        case "lifestyle":
            // 100+ Lifestyle keywords (Italian + English)
            let keywords = [
                // Italian lifestyle terms
                "lifestyle", "stile di vita", "moda", "fashion", "abbigliamento", "clothing", "vestiti", "clothes", "abito", "dress", "giacca", "jacket", "pantalone", "pants", "gonna", "skirt", "scarpe", "shoes", "borsa", "bag", "accessori", "accessories", "gioielli", "jewelry", "orologio", "watch", "occhiali", "glasses", "profumo", "perfume", "cosmetici", "cosmetics", "trucco", "makeup", "bellezza", "beauty", "capelli", "hair", "pelle", "skin", "cura", "care", "benessere", "wellness", "salute", "health", "fitness", "palestra", "gym", "allenamento", "workout", "yoga", "pilates", "corsa", "running", "jogging", "dieta", "diet", "nutrizione", "nutrition", "alimentazione", "food", "cucina", "cooking", "ricetta", "recipe", "chef", "ristorante", "restaurant", "trattoria", "osteria", "pizzeria", "bar", "caffè", "coffee", "vino", "wine", "birra", "beer", "cocktail", "drink", "bevanda", "gastronomia", "gastronomy", "gourmet", "michelin", "stella", "star", "viaggio", "travel", "turismo", "tourism", "vacanza", "vacation", "holiday", "destinazione", "destination", "hotel", "albergo", "resort", "spa", "terme", "relax", "mare", "sea", "montagna", "mountain", "lago", "lake", "città", "city", "campagna", "countryside", "casa", "home", "arredamento", "furniture", "design", "interior", "decorazione", "decoration", "giardino", "garden", "fai da te", "diy", "hobby", "tempo libero", "leisure", "arte", "art", "cultura", "culture", "libro", "book", "lettura", "reading", "mostra", "exhibition", "museo", "museum",
                // English lifestyle terms
                "lifestyle", "fashion", "clothing", "dress", "jacket", "shoes", "bag", "accessories", "jewelry", "watch", "perfume", "cosmetics", "makeup", "beauty", "hair", "skin", "wellness", "health", "fitness", "gym", "workout", "yoga", "diet", "nutrition", "food", "cooking", "recipe", "chef", "restaurant", "coffee", "wine", "beer", "cocktail", "travel", "tourism", "vacation", "hotel", "resort", "spa", "home", "furniture", "design", "interior", "decoration", "garden", "diy", "hobby", "leisure", "art", "culture", "book", "museum"
            ]
            return keywords.contains { text.contains($0) }
            
        case "general":
            // General accepts everything (catch-all)
            return true
            
        default:
            return true
        }
    }
}

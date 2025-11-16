# InShorts News App 📰

Hey! So this is a news app I built that's actually pretty cool. It's like having a smart friend who knows exactly what news you care about based on where you are.

## What Makes This Different?

You know how most news apps just throw random articles at you? This one actually gets you. Living in Naples? You'll see Napoli football news first. In Rome? Italian politics with Giorgia Meloni shows up at the top. It's location-smart, which is honestly game-changing.

## The Cool Stuff

### It Knows Where You Are 📍

The app detects your location and shows you news that actually matters to you:

**In Italy (Naples, Rome, Milan, etc.):**
- Italian politics first (Meloni, Italian government, Parliament)
- Napoli football news if you're near Naples
- Serie A updates
- EU news that affects Italy
- Plus global news so you're not in a bubble

**Anywhere Else:**
- Local teams and politics for your country
- Still get global coverage
- Everything's personalized

### Sports That Get You ⚽

If you're in Naples, you're probably a Napoli fan, right? The app knows this:
- SSC Napoli news shows up first
- Serie A standings and fixtures
- Champions League when Napoli's playing
- Other Italian teams (Inter, Milan, Juve, Roma)
- Plus Premier League, La Liga, etc.

It's not just scores - it's actual news, transfers, match analysis, the whole deal.

### Politics Without the BS 🏛️

Living in Italy means you need to know what Meloni's doing. The app gets it:
- Giorgia Meloni and Italian government news
- Parliament decisions that affect you
- EU politics (because Italy's in the EU)
- Global politics so you can talk to anyone

**And here's the best part:** You get news in BOTH Italian and English!
- Italian articles from real Italian sources (Currents, MediaStack)
- English articles about Italy (The Guardian)
- Just tap to translate the Italian ones

Perfect for learning Italian or just understanding what locals are reading.

## Where the News Comes From

I hooked up 6 different news sources so you get the full picture:

### The Premium Ones (Already Working!)

**The Guardian** 🏆
- British newspaper, super reliable
- Great for politics, sports, world news
- 5,000 articles per day (free tier)
- Status: ✅ Working right now

**Currents API** 🌍
- Global news in multiple languages
- Italian news in Italian!
- 600 articles per day
- Status: ✅ Working right now

**MediaStack** 📰
- 7,500+ news sources worldwide
- Italian politics in Italian
- 500 articles per month
- Status: ✅ Working right now

**Reddit** 🔥
- Viral news and trending topics
- Tech stuff, breaking news
- No API key needed
- Status: ✅ Working right now

**Hacker News** 💻
- Tech community news
- Startup stuff, programming
- No API key needed
- Status: ✅ Working right now

**New York Times** 🗽 (Optional)
- World-class journalism
- US and international politics
- 4,000 articles per day
- Status: ⏳ Add your key if you want it

So right now, 5 sources are working. Add NYT key and you'll have all 6.

## The Smart Features

### Language Mix
- English articles about Italy (The Guardian)
- Italian articles in Italian (Currents, MediaStack)
- Translate button for Italian articles
- Learn Italian while staying informed

### No Duplicate News
The app is smart enough to know when different sources are reporting the same story. You won't see "Meloni announces reform" 10 times from different sources.

### Fresh News Only
Nothing older than 24 hours. Who cares about yesterday's news?

### Sorted by What Matters
- Your location's news first
- Then regional stuff (EU for Italy)
- Then global news
- All sorted by newest

## How to Set It Up

### What's Already Working (No Setup!)
1. The Guardian - already configured
2. Currents API - already configured
3. MediaStack - already configured
4. Reddit - no key needed
5. Hacker News - no key needed

Just run the app and you're good to go!

### If You Want New York Times (Optional)

Takes 3 minutes:
1. Go to https://developer.nytimes.com/get-started
2. Sign up (free, no credit card)
3. Create an app
4. Enable "Top Stories API" and "Article Search API"
5. Copy your API key
6. Add it to `Config.xcconfig`:
   ```
   NYTIMES_API_KEYS = your-key-here
   ```
7. Rebuild the app

That's it. Now you have all 6 sources.

## Real Examples

### Politics Category in Italy:
```
🇮🇹 Meloni annuncia nuove riforme economiche
   (Italian article - tap to translate)
   
🏛️ Italian Parliament Approves 2024 Budget
   (English article from The Guardian)
   
🇪🇺 Italy-EU Summit on Migration Policy
   (EU news affecting Italy)
   
🌍 Biden Meets European Leaders at G7
   (Global politics)
```

### Sports Category in Naples:
```
⚽ Napoli Defeats Inter 3-1 in Serie A
   (Your local team first!)
   
🏆 Champions League: Napoli vs Barcelona Preview
   (Big matches)
   
🇮🇹 Serie A Standings: Napoli Tops the Table
   (League updates)
   
⚽ Premier League: Arsenal vs Man City
   (Global football)
```

## Why This Matters

Look, if you're living in Italy, you need to:
- Know what Meloni's doing (politics affects your life)
- Follow Napoli if you're in Naples (everyone talks about it)
- Understand EU decisions (Italy's in the EU)
- Stay connected globally (you're not from Italy originally, right?)

This app does all of that. It's like having a local friend who reads everything and tells you what matters.

## The Tech Stuff (If You Care)

Built with:
- SwiftUI (iOS app)
- MVVM architecture
- Async/await for API calls
- Location services for smart content
- Multiple API integrations
- Smart caching and deduplication

APIs used:
- The Guardian API
- Currents API
- MediaStack API
- Reddit API
- Hacker News API
- New York Times API (optional)

## Capacity

With all sources configured:
- ~100,000 requests per day
- That's like... unlimited for personal use
- Seriously, you won't hit the limits

## What You Get

**Right Now (5 sources working):**
- Italian politics in Italian and English
- Napoli football news (if in Naples/Italy)
- Serie A and Champions League
- EU politics
- Global news
- Tech news from Hacker News
- Viral content from Reddit

**If You Add NYT (6 sources):**
- Everything above
- Plus world-class US journalism
- Better international coverage
- More diverse perspectives

## Running the App

### Quick Start (Easiest Way!)

1. Open the project in Xcode
2. Press `Cmd + R`
3. Go to **Profile** tab (bottom right)
4. At the top, you'll see **"Detected Location"**
5. Tap **"Change"** and select **"Italy"**
6. **IMPORTANT:** Now swipe the categories at the top:
   - Swipe to **Politics** → See Meloni, Italian government, Parliament
   - Swipe to **Sports** → See Napoli, Serie A, Italian football
   - "For You" shows mixed global news
7. Done! You'll see Italian news first!

### Alternative: Change Device Region

**On Real iPhone:**
1. Go to **Settings** → **General** → **Language & Region**
2. Tap **Region**
3. Select **Italy**
4. Restart the app

**On Simulator:**
1. In Simulator, go to **Settings** → **General** → **Language & Region**
2. Tap **Region**
3. Select **Italy**
4. Restart the app

### What Happens

The app will:
- **Default to Italy** (European news by default!)
- Show Italian politics first (Meloni, Italian government)
- Show Napoli news in Sports category
- Mix in EU and global news
- Give you Italian articles in Italian + English articles

**No caching!** Change location anytime in the Profile tab.

**Note:** The app now defaults to Italy/Europe instead of US. Perfect for European users!

## Console Output (What You'll See)

```
📍 User location: Italy (IT)
🏛️ Fetching POLITICS news with location-aware focus
🇮🇹 Fetching Italian politics (Meloni government)
✅ Fetched 5 Italian language articles from Currents
✅ Fetched 5 Italian language articles from MediaStack
✅ Fetched 10 English articles from The Guardian
⚽ Fetching SPORTS news with location-aware team focus
🔵 Prioritizing SSC Napoli news...
✅ Fetched 30 articles total
```

## Future Ideas (Maybe?)

- Push notifications for Napoli matches
- More Italian news sources
- Regional news (Campania, Lazio, etc.)
- Italian language learning mode
- Politician profiles (Meloni, Mattarella, etc.)
- Live match scores

But honestly, it's pretty complete as is.

## The Bottom Line

This isn't just another news app. It's built for someone living in Italy who wants to:
- Stay informed about Italian politics
- Follow local sports (Napoli!)
- Understand EU decisions
- Connect globally
- Read in both Italian and English

It's smart, it's fast, and it actually gets what you need.

## Questions?

The code is pretty straightforward. Check out:
- `NewsAggregatorService.swift` - Main news fetching
- `PoliticalNewsService.swift` - Italian politics logic
- `SportsNewsService.swift` - Napoli football logic
- `LocationService.swift` - Location detection

Everything's commented and makes sense.

---

Built with ☕ for people living in Italy who want news that actually matters to them.

**Forza Napoli! 🔵⚪ Forza Italia! 🇮🇹**

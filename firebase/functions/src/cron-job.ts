/**
 * ========================================
 * CRON JOB - UNIFIED PIPELINE
 * ========================================
 * 
 * Runs every 1 hour
 * Complete all-in-one pipeline
 */

import * as functions from "firebase-functions";
import {runUnifiedPipeline} from "./unified-pipeline";

/**
 * Scheduled function - runs every 1 hour
 * CRITICAL: 9-minute timeout for processing all categories
 */
export const newsAggregatorCron = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes
    memory: "512MB",
  })
  .pubsub
  .schedule("every 1 hours")
  .timeZone("Europe/Rome")
  .onRun(async (context) => {
    console.log("⏰ CRON JOB TRIGGERED - Running unified pipeline");

    try {
      await runUnifiedPipeline();
      console.log("✅ Cron job completed successfully");
      return null;
    } catch (error) {
      console.error("❌ Cron job failed:", error);
      throw error;
    }
  });

/**
 * Manual trigger for testing
 * CRITICAL: 9-minute timeout for processing all categories
 */
export const runBackendManual = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes
    memory: "512MB",
  })
  .https.onRequest(async (req, res) => {
    console.log("🔧 MANUAL TRIGGER - Running unified pipeline");

    try {
      const results = await runUnifiedPipeline();

    const successful = results.filter((r) => r.success);
    const failed = results.filter((r) => !r.success);

    res.json({
      success: true,
      message: "Unified pipeline completed",
      timestamp: new Date().toISOString(),
      summary: {
        total_categories: results.length,
        successful: successful.length,
        failed: failed.length,
        total_articles: results.reduce((sum, r) => sum + r.total_articles, 0),
      },
      results: results,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    });
  }
});

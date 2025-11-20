import * as functions from "firebase-functions";
import {runUnifiedPipeline} from "./unified-pipeline";

export const newsAggregatorCron = functions
  .runWith({
    timeoutSeconds: 540,
    memory: "1GB",
  })
  .pubsub
  .schedule("every 2 hours")
  .timeZone("Europe/Rome")
  .onRun(async (context) => {
    console.log("Cron job triggered");

    try {
      await runUnifiedPipeline();
      console.log("Cron job completed");
      return null;
    } catch (error) {
      console.error("Cron job failed:", error);
      throw error;
    }
  });

export const runBackendManual = functions
  .runWith({
    timeoutSeconds: 540,
    memory: "512MB",
  })
  .https.onRequest(async (req, res) => {
    console.log("Manual trigger");

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

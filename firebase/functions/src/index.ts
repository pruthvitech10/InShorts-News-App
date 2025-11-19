/**
 * ========================================
 * MAIN INDEX - UNIFIED PIPELINE
 * ========================================
 * 
 * Complete all-in-one solution
 * Runs every 1 hour
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// ==================== EXPORT FUNCTIONS ====================

// Main unified pipeline - runs every 1 hour
export {newsAggregatorCron, runBackendManual} from "./cron-job";

// Shuffled news endpoints - each user gets different order!
export {getShuffledNews, getShuffledNewsPaginated} from "./shuffle-endpoint";






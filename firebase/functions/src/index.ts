/**
 * ========================================
 * MAIN INDEX - UNIFIED PIPELINE
 * ========================================
 * 
 * Complete all-in-one solution
 * Runs every 10 minutes
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// ==================== EXPORT FUNCTIONS ====================

// Main unified pipeline - runs every 10 minutes
export {newsAggregatorCron, runBackendManual} from "./cron-job";

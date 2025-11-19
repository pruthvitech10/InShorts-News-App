import * as admin from "firebase-admin";

admin.initializeApp();

export {newsAggregatorCron, runBackendManual} from "./cron-job";
export {getShuffledNews, getShuffledNewsPaginated} from "./shuffle-endpoint";






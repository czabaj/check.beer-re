import path from "node:path";

import { initializeApp, applicationDefault } from "firebase-admin/app";
import dotenv from "dotenv";

import { migratePlaces } from "./migrate-places";

dotenv.config({ path: path.join(__dirname, "../../../.env.local") });

const app = initializeApp({
  credential: applicationDefault(),
});

migratePlaces(app);

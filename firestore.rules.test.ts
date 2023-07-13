import fs from "node:fs";

import * as testing from "@firebase/rules-unit-testing";
import { describe, expect, test } from "vitest";

const testUserId = "KQC3YpthFJfKWOrSZhtz5O3Lm302";

describe("Security rules", () => {
  let testEnv: testing.RulesTestEnvironment;
  let authenticatedUser: testing.RulesTestContext;
  let unauthenticatedUser: testing.RulesTestContext;

  beforeAll(async () => {
    testEnv = await testing.initializeTestEnvironment({
      projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
      firestore: {
        rules: fs.readFileSync("firestore.rules", "utf8"),
        host: "127.0.0.1",
        port: 9090,
      },
    });

    authenticatedUser = testEnv.authenticatedContext(testUserId);
    unauthenticatedUser = testEnv.unauthenticatedContext();
  });

  it("should not allow to read for unauthenticated users", async () => {
    const readUser = unauthenticatedUser
      .firestore()
      .collection("users")
      .doc("Test-User")
      .get();

    await testing.assertFails(readUser);
  });
});

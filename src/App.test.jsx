import { render, screen } from "@testing-library/react";
import { expect, it, vi } from "vitest";

// jsdom lacks service worker and matchMedia; modules read them at import time.
vi.hoisted(() => {
  window.matchMedia = (query) => ({
    matches: false,
    media: query,
    addEventListener() {},
    removeEventListener() {},
    addListener() {},
    removeListener() {},
    dispatchEvent: () => false,
  });
  Object.defineProperty(navigator, "serviceWorker", {
    configurable: true,
    value: { ready: new Promise(() => {}) },
  });
});

import { make as App } from "./App.bs.jsx";

it("renders component without crashing", async () => {
  render(<App />);
  expect(await screen.findByRole("link", { name: "Otevřít" })).toBeTruthy();
});

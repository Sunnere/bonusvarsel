import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";

const JSON_URL =
  "https://www.miles-and-more.com/lh_shared/v1/offers/list.json" +
  "?languageCode=en" +
  "&countryCode=no" +
  "&context=/content/mam/web/row/en/earn/all-offers/jcr:content/par/offerlistfiltered_1753241868" +
  "&rows=2000";

const OUT = "data/lufthansa/mam.offers.raw.json";

fs.mkdirSync(path.dirname(OUT), { recursive: true });

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  userAgent:
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
  locale: "en-US",
});

const page = await context.newPage();

// 1) Besøk en “vanlig” side først → Cloudflare/cookies settes i session
await page.goto("https://www.miles-and-more.com/row/en/earn/all-offers.html", {
  waitUntil: "domcontentloaded",
});

// 2) Hent JSON via Playwright sin request (samme cookies/clearance)
const res = await page.request.get(JSON_URL, {
  headers: {
    accept: "application/json, text/plain, */*",
    referer: "https://www.miles-and-more.com/row/en/earn/all-offers.html",
  },
});

const status = res.status();
const ct = res.headers()["content-type"] || "";
const body = await res.text();

console.log("Status:", status);
console.log("Content-Type:", ct);

fs.writeFileSync(OUT, body);
console.log("Wrote:", OUT);

await browser.close();

// Guard: hvis vi fortsatt får HTML (DOCTYPE), stopp tidlig med tydelig feil
if (body.trim().startsWith("<")) {
  throw new Error(
    `Got HTML instead of JSON (likely Cloudflare/403). Saved to ${OUT} for inspection.`
  );
}

// Quick sanity-check
const j = JSON.parse(body);
console.log("offers:", j.offers?.length);
